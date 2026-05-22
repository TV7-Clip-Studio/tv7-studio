import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:forgotten_client/app.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final engineManager = EngineProcessManager();
  final engineConfig = await _resolveEngineConfig();
  final engineStartup = await engineManager.start(engineConfig);
  runApp(
    App(
      config: config,
      engineClient: EngineClient(baseUri: engineConfig.baseUri),
      engineManager: engineManager,
      engineStartup: engineStartup,
    ),
  );
}

Future<EngineSidecarConfig> _resolveEngineConfig() async {
  const host = String.fromEnvironment(
    'TV7_ENGINE_HOST',
    defaultValue: '127.0.0.1',
  );
  const port = int.fromEnvironment('TV7_ENGINE_PORT', defaultValue: 7070);
  const binaryOverride = String.fromEnvironment('TV7_ENGINE_BINARY_PATH');
  const workDirOverride = String.fromEnvironment('TV7_ENGINE_WORK_DIR');
  const ffmpegBin = String.fromEnvironment('TV7_ENGINE_FFMPEG_BIN');
  const ffprobeBin = String.fromEnvironment('TV7_ENGINE_FFPROBE_BIN');

  final workDir = workDirOverride.isEmpty
      ? await _defaultEngineWorkDir()
      : workDirOverride;
  await Directory(workDir).create(recursive: true);

  return EngineSidecarConfig(
    binaryPath: binaryOverride.isEmpty
        ? _resolveDeveloperEngineBinaryPath()
        : binaryOverride,
    host: host,
    port: port,
    workDir: workDir,
    ffmpegBin: ffmpegBin.isEmpty ? null : ffmpegBin,
    ffprobeBin: ffprobeBin.isEmpty ? null : ffprobeBin,
  );
}

Future<String> _defaultEngineWorkDir() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  return p.join(appDocDir.path, 'forgotten_workspace');
}

String _resolveDeveloperEngineBinaryPath() {
  final current = Directory.current.path;
  final candidates = [
    p.normalize(
      p.join(
        current,
        '..',
        'tv7-axum-engine',
        'target',
        'debug',
        'engine-service',
      ),
    ),
    p.normalize(
      p.join(
        current,
        '..',
        '..',
        'tv7-axum-engine',
        'target',
        'debug',
        'engine-service',
      ),
    ),
  ];

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  return candidates.first;
}
