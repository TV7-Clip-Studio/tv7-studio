import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:path/path.dart' as p;

class _FakeProcess implements EngineProcess {
  final _exitCode = Completer<int>();
  final List<ProcessSignal> signals = [];

  @override
  int get pid => 42;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    signals.add(signal);
    if (!_exitCode.isCompleted) {
      _exitCode.complete(0);
    }
    return true;
  }
}

class _FakeLauncher implements EngineProcessLauncher {
  _FakeLauncher(this.process);

  final _FakeProcess process;
  String? executable;
  List<String>? arguments;
  Map<String, String>? environment;
  String? workingDirectory;
  var startCount = 0;

  @override
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    required Map<String, String> environment,
    String? workingDirectory,
  }) async {
    startCount++;
    this.executable = executable;
    this.arguments = arguments;
    this.environment = environment;
    this.workingDirectory = workingDirectory;
    return process;
  }
}

class _FakeTransport implements EngineJsonTransport {
  _FakeTransport({required this.diagnostics, this.healthFailures = 0});

  final Map<String, dynamic> diagnostics;
  final requested = <Uri>[];
  int healthFailures;

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    requested.add(uri);
    Map<String, dynamic> json;
    if (uri.path == '/health') {
      if (healthFailures > 0) {
        healthFailures--;
        throw const SocketException('not ready');
      }
      json = {'status': 'ok'};
    } else if (uri.path == '/v1/diagnostics') {
      json = diagnostics;
    } else {
      throw StateError('unexpected path ${uri.path}');
    }
    return EngineHttpResponse(
      statusCode: 200,
      elapsed: Duration.zero,
      json: json,
      rawBody: json.toString(),
    );
  }
}

void main() {
  late Directory tempDir;
  late File binary;
  late Directory workDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('engine_manager_test');
    binary = File(p.join(tempDir.path, 'engine-service'));
    await binary.writeAsString('fake');
    workDir = Directory(p.join(tempDir.path, 'workspace'));
    await workDir.create();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  EngineSidecarConfig config({
    String? ffmpegBin,
    String? ffprobeBin,
    int healthAttempts = 3,
  }) {
    return EngineSidecarConfig(
      binaryPath: binary.path,
      host: '127.0.0.1',
      port: 7070,
      workDir: workDir.path,
      ffmpegBin: ffmpegBin,
      ffprobeBin: ffprobeBin,
      healthAttempts: healthAttempts,
      healthDelay: Duration.zero,
    );
  }

  test(
    'starts Engine with contract environment and probes diagnostics',
    () async {
      final process = _FakeProcess();
      final launcher = _FakeLauncher(process);
      final transport = _FakeTransport(
        diagnostics: {'status': 'ready', 'tools': <Map<String, dynamic>>[]},
        healthFailures: 1,
      );
      final manager = EngineProcessManager(
        launcher: launcher,
        transport: transport,
      );

      final result = await manager.start(
        config(ffmpegBin: '/bin/ffmpeg', ffprobeBin: '/bin/ffprobe'),
      );

      expect(result.status, EngineStartupStatus.ready);
      expect(launcher.executable, binary.path);
      expect(launcher.arguments, isEmpty);
      expect(launcher.workingDirectory, workDir.path);
      expect(launcher.environment, {
        'TV7_ENGINE_HOST': '127.0.0.1',
        'TV7_ENGINE_PORT': '7070',
        'TV7_ENGINE_WORK_DIR': workDir.path,
        'TV7_ENGINE_FFMPEG_BIN': '/bin/ffmpeg',
        'TV7_ENGINE_FFPROBE_BIN': '/bin/ffprobe',
      });
      expect(transport.requested.map((uri) => uri.path), [
        '/health',
        '/health',
        '/v1/diagnostics',
      ]);
    },
  );

  test('surfaces degraded diagnostics without stopping Engine', () async {
    final process = _FakeProcess();
    final launcher = _FakeLauncher(process);
    final manager = EngineProcessManager(
      launcher: launcher,
      transport: _FakeTransport(
        diagnostics: {
          'status': 'degraded',
          'tools': [
            {'name': 'ffmpeg', 'available': false},
          ],
        },
      ),
    );

    final result = await manager.start(config());

    expect(result.status, EngineStartupStatus.degraded);
    expect(result.message, contains('ffmpeg'));
    expect(process.signals, isEmpty);
  });

  test('reports unavailable when binary path cannot be resolved', () async {
    final process = _FakeProcess();
    final launcher = _FakeLauncher(process);
    final manager = EngineProcessManager(
      launcher: launcher,
      transport: _FakeTransport(diagnostics: {'status': 'ready'}),
    );

    final result = await manager.start(
      EngineSidecarConfig(
        binaryPath: p.join(tempDir.path, 'missing-engine'),
        host: '127.0.0.1',
        port: 7070,
        workDir: workDir.path,
        healthDelay: Duration.zero,
      ),
    );

    expect(result.status, EngineStartupStatus.unavailable);
    expect(result.message, contains('Engine binary not found'));
    expect(launcher.startCount, 0);
  });

  test('stops the launched Engine process', () async {
    final process = _FakeProcess();
    final manager = EngineProcessManager(
      launcher: _FakeLauncher(process),
      transport: _FakeTransport(diagnostics: {'status': 'ready'}),
    );

    await manager.start(config());
    await manager.stop();

    expect(process.signals, [ProcessSignal.sigterm]);
  });
}
