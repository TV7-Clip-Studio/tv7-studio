import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
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

class _FakeEngineTransport implements EngineJsonTransport {
  final List<Map<String, dynamic>?> requests = [];
  bool requireTranscriptionSetup = false;
  String? generatedTranscriptPath;

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    requests.add(body);
    if (uri.path == '/v1/transcripts/generate' && requireTranscriptionSetup) {
      final json = {
        'error': 'TRANSCRIPTION_SETUP_REQUIRED',
        'message':
            'Local transcription requires a configured runtime and model.',
        'missing': ['transcription_runtime', 'transcription_model'],
        'setup_capability': 'transcription',
      };
      return EngineHttpResponse(
        statusCode: 409,
        elapsed: Duration.zero,
        json: json,
        rawBody: json.toString(),
      );
    }

    final json = switch (uri.path) {
      '/v1/media/probe' => {
        'metadata': {
          'path': body?['path'],
          'duration_seconds': 95.0,
          'width': 1920,
          'height': 1080,
          'format': 'mov,mp4,m4a,3gp,3g2,mj2',
          'size_bytes': 4,
        },
      },
      '/v1/media/thumbnail' => {'output_path': body?['output_path']},
      '/v1/media/render-clip' => {'output_path': body?['output_path']},
      '/v1/transcripts/download' => {
        'job': {
          'id': 'transcript_job',
          'status': 'succeeded',
          'progress': 1.0,
          'result': <String, dynamic>{},
        },
      },
      '/v1/transcripts/generate' => {
        'job': {
          'id': 'generate_job',
          'kind': 'transcript_generate',
          'status': 'queued',
          'progress': 0.0,
          'logs': ['queued transcript generation'],
          'result': null,
          'error': null,
          'cancel_requested': false,
        },
      },
      '/v1/jobs/generate_job' => {
        'id': 'generate_job',
        'kind': 'transcript_generate',
        'status': 'succeeded',
        'progress': 1.0,
        'logs': ['queued transcript generation', 'completed'],
        'result': {
          'transcript_path': generatedTranscriptPath,
          'language': 'en',
        },
        'error': null,
        'cancel_requested': false,
      },
      '/v1/jobs/generate_job/logs' => {
        'job_id': 'generate_job',
        'logs': ['queued transcript generation', 'completed'],
      },
      _ => {'status': 'ok'},
    };
    final outputPath = body?['output_path']?.toString();
    if (uri.path == '/v1/media/thumbnail' && outputPath != null) {
      await File(outputPath).create(recursive: true);
    }
    if (uri.path == '/v1/transcripts/generate' && outputPath != null) {
      generatedTranscriptPath = outputPath;
      await File(outputPath).writeAsString(
        'WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nGenerated transcript',
      );
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
  late _FakeToolRunner toolRunner;
  late _FakeEngineTransport engineTransport;
  late LocalVideoRepository repository;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('forgotten_videos_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    toolRunner = _FakeToolRunner();
    engineTransport = _FakeEngineTransport();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    repository = LocalVideoRepository(
      toolRunner: toolRunner,
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: engineTransport,
      ),
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
    expect(
      engineTransport.requests
          .where((request) => request?.containsKey('path') ?? false)
          .length,
      2,
    );
    expect(
      engineTransport.requests
          .where((request) => request?.containsKey('output_path') ?? false)
          .length,
      2,
    );

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

  test(
    'downloadTranscript accepts source_url metadata from older files',
    () async {
      final workspace = Directory(p.join(tempDir.path, 'forgotten_workspace'));
      await workspace.create(recursive: true);
      final video = File(p.join(workspace.path, 'video.mp4'))
        ..writeAsStringSync('data');
      final meta = File('${video.path}.meta.json')
        ..writeAsStringSync(
          '{"source_url":"https://example.com/watch?v=123",'
          '"subtitles":{"en":[]}}',
        );

      await repository.downloadTranscript(video.path);

      expect(meta.existsSync(), isTrue);
      expect(
        engineTransport.requests,
        contains(containsPair('url', 'https://example.com/watch?v=123')),
      );
    },
  );

  test('downloadTranscript rejects local-only source metadata', () async {
    final workspace = Directory(p.join(tempDir.path, 'forgotten_workspace'));
    await workspace.create(recursive: true);
    final video = File(p.join(workspace.path, 'video.mp4'))
      ..writeAsStringSync('data');
    File('${video.path}.meta.json').writeAsStringSync(
      '{"source_url":"file:///tmp/video.mp4","subtitles":{"en":[]}}',
    );

    expect(
      repository.downloadTranscript(video.path),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('requires original remote source URL metadata'),
        ),
      ),
    );
  });

  test(
    'generateTranscript creates sidecar transcript through Engine job',
    () async {
      final workspace = Directory(p.join(tempDir.path, 'forgotten_workspace'));
      await workspace.create(recursive: true);
      final video = File(p.join(workspace.path, 'video.mp4'))
        ..writeAsStringSync('data');

      final transcript = await repository.generateTranscript(video.path);

      expect(transcript?.text, 'Generated transcript');
      expect(File(p.join(workspace.path, 'video.vtt')).existsSync(), isTrue);
      expect(
        engineTransport.requests,
        contains(
          allOf(
            containsPair('media_path', video.path),
            containsPair('output_path', p.join(workspace.path, 'video.vtt')),
          ),
        ),
      );
    },
  );

  test('generateTranscript surfaces transcription setup-required', () async {
    final workspace = Directory(p.join(tempDir.path, 'forgotten_workspace'));
    await workspace.create(recursive: true);
    final video = File(p.join(workspace.path, 'video.mp4'))
      ..writeAsStringSync('data');
    engineTransport.requireTranscriptionSetup = true;

    expect(
      repository.generateTranscript(video.path),
      throwsA(
        isA<LocalTranscriptionSetupRequiredException>().having(
          (error) => error.missing,
          'missing',
          contains('transcription_runtime'),
        ),
      ),
    );
  });
}
