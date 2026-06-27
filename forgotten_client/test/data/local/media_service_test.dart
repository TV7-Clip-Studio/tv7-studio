import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_job_poller.dart';
import 'package:forgotten_client/data/local/media_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeEngineTransport implements EngineJsonTransport {
  _FakeEngineTransport({this.failIngest = false});

  final bool failIngest;
  final requested = <Uri>[];
  final bodies = <Map<String, dynamic>?>[];
  String? mediaPath;
  String? transcriptPath;

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    requested.add(uri);
    bodies.add(body);

    Map<String, dynamic> json;
    var statusCode = 200;
    switch (uri.path) {
      case '/v1/ingest/url':
        final outputDir =
            body?['output_dir']?.toString() ?? Directory.systemTemp.path;
        mediaPath = p.join(outputDir, 'download_1.mp4');
        await File(mediaPath!).writeAsString('downloaded');
        json = {
          'job': {
            'id': 'job_ingest',
            'kind': 'url_ingest',
            'status': 'queued',
            'progress': 0.0,
            'logs': ['queued'],
            'result': null,
            'error': null,
            'cancel_requested': false,
          },
        };
      case '/v1/jobs/job_ingest':
        json = {
          'id': 'job_ingest',
          'kind': 'url_ingest',
          'status': failIngest ? 'failed' : 'succeeded',
          'progress': 1.0,
          'logs': ['queued', 'completed'],
          'result': failIngest
              ? null
              : {
                  'url': 'https://example.com/video',
                  'media_path': mediaPath,
                  'metadata': {'title': 'Example'},
                },
          'error': failIngest ? 'download failed' : null,
          'cancel_requested': false,
        };
      case '/v1/jobs/job_ingest/logs':
        json = {
          'job_id': 'job_ingest',
          'logs': ['queued', 'completed'],
        };
      case '/v1/transcripts/download':
        transcriptPath = body?['output_path']?.toString();
        if (transcriptPath != null) {
          await File(transcriptPath!).writeAsString('WEBVTT\n\nHello');
        }
        json = {
          'job': {
            'id': 'job_transcript',
            'kind': 'transcript_download',
            'status': 'queued',
            'progress': 0.0,
            'logs': ['queued transcript'],
            'result': null,
            'error': null,
            'cancel_requested': false,
          },
        };
      case '/v1/jobs/job_transcript':
        json = {
          'id': 'job_transcript',
          'kind': 'transcript_download',
          'status': 'succeeded',
          'progress': 1.0,
          'logs': ['queued transcript', 'completed'],
          'result': {'transcript_path': transcriptPath, 'language': 'en'},
          'error': null,
          'cancel_requested': false,
        };
      case '/v1/jobs/job_transcript/logs':
        json = {
          'job_id': 'job_transcript',
          'logs': ['queued transcript', 'completed'],
        };
      default:
        statusCode = 404;
        json = {'error': 'missing'};
    }

    return EngineHttpResponse(
      statusCode: statusCode,
      elapsed: Duration.zero,
      json: json,
      rawBody: json.toString(),
    );
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
    final service = MediaService(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: _FakeEngineTransport(),
      ),
    );

    final ingested = await service.prepareIngestFromFile(source.path);

    expect(ingested.path, isNot(source.path));
    expect(p.basename(ingested.path), p.basename(source.path));
    expect(ingested.existsSync(), isTrue);
    expect(ingested.readAsStringSync(), 'abc');
  });

  test(
    'prepareIngestFromUrl polls Engine jobs and returns downloaded file',
    () async {
      final transport = _FakeEngineTransport();
      final service = MediaService(
        engineClient: EngineClient(
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          transport: transport,
        ),
        pollingPolicy: const EngineJobPollingPolicy(
          initialInterval: Duration.zero,
          maxInterval: Duration.zero,
          timeout: Duration(seconds: 1),
        ),
      );
      final logs = <String>[];
      final progressValues = <double>[];
      final jobIds = <String>[];

      final file = await service.prepareIngestFromUrl(
        'https://example.com/video',
        onLog: logs.add,
        onProgress: progressValues.add,
        onJobStarted: jobIds.add,
      );

      expect(
        transport.requested.map((uri) => uri.path),
        contains('/v1/ingest/url'),
      );
      expect(
        transport.requested.map((uri) => uri.path),
        contains('/v1/jobs/job_ingest'),
      );
      expect(file.existsSync(), isTrue);
      expect(File('${file.path}.meta.json').existsSync(), isTrue);
      expect(logs, contains('completed'));
      expect(progressValues, contains(0.0));
      expect(progressValues, contains(1.0));
      expect(jobIds, containsAllInOrder(['job_ingest', 'job_transcript']));
    },
  );

  test('prepareIngestFromUrl surfaces failed Engine jobs', () async {
    final service = MediaService(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: _FakeEngineTransport(failIngest: true),
      ),
      pollingPolicy: const EngineJobPollingPolicy(
        initialInterval: Duration.zero,
        maxInterval: Duration.zero,
        timeout: Duration(seconds: 1),
      ),
    );

    expect(
      () => service.prepareIngestFromUrl('https://example.com/bad'),
      throwsA(isA<StateError>()),
    );
  });
}
