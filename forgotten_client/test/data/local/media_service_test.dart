import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/media_service.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeToolRunner extends ToolRunner {
  _FakeToolRunner({this.streamLines = const [], this.exitCode = 0});

  final List<String> streamLines;
  final List<List<String>> runStreamArgs = [];
  final List<String> runArgsExecutables = [];
  final int exitCode;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    runArgsExecutables.add(executable);
    return ProcessResult(0, 0, '', '');
  }

  @override
  Stream<String> runStream(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async* {
    runStreamArgs.add(args);
    String? outputPath;
    final oIndex = args.indexOf('-o');
    if (oIndex != -1 && oIndex + 1 < args.length) {
      outputPath = args[oIndex + 1];
    } else if (args.length >= 2) {
      outputPath = args[1];
    }

    if (outputPath != null) {
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString('downloaded');
    }
    for (final line in streamLines) {
      yield line;
    }
    if (exitCode != 0) {
      throw ProcessException(executable, args, 'Exit code $exitCode', exitCode);
    }
  }

  @override
  Future<void> downloadTranscript(
    String url,
    String outputPath,
    String language,
  ) async {
    final file = File('$outputPath.$language.vtt');
    await file.parent.create(recursive: true);
    await file.writeAsString('WEBVTT\n\n00:00.000 --> 00:01.000\nHello');
  }
}

void main() {
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('forgotten_media_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempDir.delete(recursive: true);
  });

  test('prepareIngestFromFile copies source into workspace', () async {
    final source = File(p.join(tempDir.path, 'video.mp4'))
      ..writeAsStringSync('abc');
    final service = MediaService(toolRunner: _FakeToolRunner());

    final ingested = await service.prepareIngestFromFile(source.path);

    expect(ingested.path, isNot(source.path));
    expect(p.basename(ingested.path), p.basename(source.path));
    expect(ingested.existsSync(), isTrue);
    expect(ingested.readAsStringSync(), 'abc');
  });

  test(
    'prepareIngestFromUrl streams logs and returns downloaded file',
    () async {
      final toolRunner = _FakeToolRunner(streamLines: ['line1', 'line2']);
      final service = MediaService(toolRunner: toolRunner);
      final logs = <String>[];

      final file = await service.prepareIngestFromUrl(
        'https://example.com/video',
        onLog: logs.add,
      );

      expect(toolRunner.runStreamArgs, isNotEmpty);
      expect(logs, containsAll(['line1', 'line2']));
      expect(file.existsSync(), isTrue);
    },
  );

  test('prepareIngestFromUrl surfaces process failures', () async {
    final toolRunner = _FakeToolRunner(streamLines: ['err'], exitCode: 1);
    final service = MediaService(toolRunner: toolRunner);

    expect(
      () => service.prepareIngestFromUrl('https://example.com/bad'),
      throwsA(isA<ProcessException>()),
    );
  });
}
