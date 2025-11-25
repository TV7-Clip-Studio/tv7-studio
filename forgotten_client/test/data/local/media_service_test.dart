import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:forgotten_client/data/local/media_service.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeToolRunner extends ToolRunner {
  _FakeToolRunner({this.streamLines = const []});

  final List<String> streamLines;
  final List<List<String>> runStreamArgs = [];
  final List<String> runArgsExecutables = [];

  @override
  Future<ProcessResult> run(String executable, List<String> args, {String? workingDirectory}) async {
    runArgsExecutables.add(executable);
    return ProcessResult(0, 0, '', '');
  }

  @override
  Stream<String> runStream(String executable, List<String> args, {String? workingDirectory}) async* {
    runStreamArgs.add(args);
    if (args.length >= 2) {
      final outputPath = args[1];
      await File(outputPath).writeAsString('downloaded');
    }
    for (final line in streamLines) {
      yield line;
    }
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
    final source = File(p.join(tempDir.path, 'video.mp4'))..writeAsStringSync('abc');
    final service = MediaService(toolRunner: _FakeToolRunner());

    final ingested = await service.prepareIngestFromFile(source.path);

    expect(ingested.path, isNot(source.path));
    expect(p.basename(ingested.path), p.basename(source.path));
    expect(ingested.existsSync(), isTrue);
    expect(ingested.readAsStringSync(), 'abc');
  });

  test('prepareIngestFromUrl streams logs and returns downloaded file', () async {
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
  });
}
