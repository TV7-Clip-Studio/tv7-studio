import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeToolRunner extends ToolRunner {
  _FakeToolRunner({required this.mediaInfo});

  final Map<String, dynamic> mediaInfo;
  final List<String> thumbnailRequests = [];
  final List<String> mediaInfoRequests = [];

  @override
  Future<Map<String, dynamic>> getMediaInfo(String path) async {
    mediaInfoRequests.add(path);
    return mediaInfo;
  }

  @override
  Future<void> generateThumbnail(String videoPath, String thumbnailPath) async {
    thumbnailRequests.add(thumbnailPath);
    final file = File(thumbnailPath);
    await file.create(recursive: true);
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    return ProcessResult(0, 0, '', '');
  }

  @override
  Stream<String> runStream(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async* {}
}

void main() {
  late Directory tempDir;
  late _FakeToolRunner toolRunner;
  late LocalVideoRepository repository;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('forgotten_videos_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    toolRunner = _FakeToolRunner(
      mediaInfo: {
        'format': {'duration': '95.0'},
        'streams': [
          {'codec_type': 'video', 'width': 1920, 'height': 1080},
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    repository = LocalVideoRepository(
      toolRunner: toolRunner,
      videosApi: VideosApi(dio),
      uploadsApi: UploadsApi(dio),
      aiApi: AiApi(dio),
      dio: dio,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempDir.delete(recursive: true);
  });

  test('getVideos returns enriched, sorted video items', () async {
    final workspace = Directory(p.join(tempDir.path, 'forgotten_workspace'));
    await workspace.create(recursive: true);

    final older = File(p.join(workspace.path, 'older.mp4'))
      ..writeAsStringSync('data1');
    final newer = File(p.join(workspace.path, 'newer.mkv'))
      ..writeAsStringSync('data2');
    await older.setLastModified(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );
    await newer.setLastModified(DateTime.now());

    final items = await repository.getVideos();

    expect(items.map((i) => p.basename(i.file.path)).toList(), [
      'newer.mkv',
      'older.mp4',
    ]);
    expect(items.first.duration, isNotNull);
    expect(toolRunner.mediaInfoRequests.length, 2);
    expect(toolRunner.thumbnailRequests.length, 2);

    // Sidecar files should be present for the latest item
    final thumbPath = '${newer.path}.thumb.jpg';
    final metaPath = '${newer.path}.meta.json';
    expect(File(thumbPath).existsSync(), isTrue);
    expect(File(metaPath).existsSync(), isTrue);
  });

  test('deleteVideo removes video and sidecars', () async {
    final workspace = Directory(p.join(tempDir.path, 'forgotten_workspace'));
    await workspace.create(recursive: true);

    final video = File(p.join(workspace.path, 'clip.mp4'))
      ..writeAsStringSync('data');
    final meta = File('${video.path}.meta.json')..writeAsStringSync('{}');
    final thumb = File('${video.path}.thumb.jpg')..writeAsStringSync('thumb');

    expect(video.existsSync(), isTrue);
    expect(meta.existsSync(), isTrue);
    expect(thumb.existsSync(), isTrue);

    await repository.deleteVideo(video.path);

    expect(video.existsSync(), isFalse);
    expect(meta.existsSync(), isFalse);
    expect(thumb.existsSync(), isFalse);
  });
}
