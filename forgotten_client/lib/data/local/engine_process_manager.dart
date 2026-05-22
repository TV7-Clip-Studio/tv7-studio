import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:forgotten_client/data/local/engine_client.dart';

enum EngineStartupStatus { ready, degraded, unavailable }

class EngineSidecarConfig {
  const EngineSidecarConfig({
    required this.binaryPath,
    required this.host,
    required this.port,
    required this.workDir,
    this.ffmpegBin,
    this.ffprobeBin,
    this.healthAttempts = 30,
    this.healthDelay = const Duration(milliseconds: 200),
  });

  final String binaryPath;
  final String host;
  final int port;
  final String workDir;
  final String? ffmpegBin;
  final String? ffprobeBin;
  final int healthAttempts;
  final Duration healthDelay;

  Uri get baseUri => Uri(scheme: 'http', host: host, port: port);

  Map<String, String> toEnvironment() {
    final environment = <String, String>{
      'TV7_ENGINE_HOST': host,
      'TV7_ENGINE_PORT': port.toString(),
      'TV7_ENGINE_WORK_DIR': workDir,
    };

    if (ffmpegBin != null && ffmpegBin!.trim().isNotEmpty) {
      environment['TV7_ENGINE_FFMPEG_BIN'] = ffmpegBin!;
    }
    if (ffprobeBin != null && ffprobeBin!.trim().isNotEmpty) {
      environment['TV7_ENGINE_FFPROBE_BIN'] = ffprobeBin!;
    }

    return environment;
  }
}

class EngineStartupResult {
  const EngineStartupResult({
    required this.status,
    required this.baseUri,
    this.diagnostics,
    this.message,
  });

  final EngineStartupStatus status;
  final Uri baseUri;
  final EngineDiagnostics? diagnostics;
  final String? message;

  bool get isReady => status == EngineStartupStatus.ready;
}

abstract class EngineProcess {
  int get pid;
  Future<int> get exitCode;
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

class DartEngineProcess implements EngineProcess {
  DartEngineProcess(this._process);

  final Process _process;

  @override
  int get pid => _process.pid;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    return _process.kill(signal);
  }
}

abstract class EngineProcessLauncher {
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    required Map<String, String> environment,
    String? workingDirectory,
  });
}

class DartEngineProcessLauncher implements EngineProcessLauncher {
  const DartEngineProcessLauncher();

  @override
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    required Map<String, String> environment,
    String? workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      environment: environment,
      workingDirectory: workingDirectory,
    );
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => debugPrint('[engine] $line'));
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => debugPrint('[engine] $line'));
    return DartEngineProcess(process);
  }
}

class EngineProcessManager {
  EngineProcessManager({
    EngineProcessLauncher launcher = const DartEngineProcessLauncher(),
    EngineJsonTransport transport = const DartEngineJsonTransport(),
  }) : _launcher = launcher,
       _transport = transport;

  final EngineProcessLauncher _launcher;
  final EngineJsonTransport _transport;
  EngineProcess? _process;

  Future<EngineStartupResult> start(EngineSidecarConfig config) async {
    final binary = File(config.binaryPath);
    if (!await binary.exists()) {
      return EngineStartupResult(
        status: EngineStartupStatus.unavailable,
        baseUri: config.baseUri,
        message: 'Engine binary not found at ${config.binaryPath}',
      );
    }

    try {
      _process = await _launcher.start(
        config.binaryPath,
        const [],
        environment: config.toEnvironment(),
        workingDirectory: config.workDir,
      );
    } catch (error) {
      return EngineStartupResult(
        status: EngineStartupStatus.unavailable,
        baseUri: config.baseUri,
        message: 'Engine failed to launch: $error',
      );
    }

    final client = EngineClient(baseUri: config.baseUri, transport: _transport);

    try {
      await _waitForHealth(
        client,
        attempts: config.healthAttempts,
        delay: config.healthDelay,
      );
    } catch (error) {
      return EngineStartupResult(
        status: EngineStartupStatus.unavailable,
        baseUri: config.baseUri,
        message: 'Engine did not become healthy: $error',
      );
    }

    try {
      final diagnostics = await client.getDiagnostics();
      final status = diagnostics.isReady
          ? EngineStartupStatus.ready
          : EngineStartupStatus.degraded;
      return EngineStartupResult(
        status: status,
        baseUri: config.baseUri,
        diagnostics: diagnostics,
        message: diagnostics.summary,
      );
    } catch (error) {
      return EngineStartupResult(
        status: EngineStartupStatus.degraded,
        baseUri: config.baseUri,
        message: 'Engine health check passed but diagnostics failed: $error',
      );
    }
  }

  Future<void> _waitForHealth(
    EngineClient client, {
    required int attempts,
    required Duration delay,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final health = await client.getHealth();
        if (!health.isOk) {
          throw StateError('Engine health status is ${health.status}');
        }
        return;
      } catch (error) {
        lastError = error;
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }
    }
    throw lastError ?? StateError('health probe did not run');
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;

    _process = null;
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }
  }
}
