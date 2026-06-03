import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';

class _FakeTransport implements EngineJsonTransport {
  _FakeTransport(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final requested = <Uri>[];
  final methods = <String>[];
  final bodies = <Map<String, dynamic>?>[];
  int statusCode = 200;

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    requested.add(uri);
    methods.add(method);
    bodies.add(body);
    final response = responses[uri.path];
    if (response == null) {
      throw const SocketException('missing response');
    }
    return EngineHttpResponse(
      statusCode: statusCode,
      elapsed: Duration.zero,
      json: response,
      rawBody: response.toString(),
    );
  }
}

void main() {
  test('getHealth calls Engine health endpoint', () async {
    final transport = _FakeTransport({
      '/health': {'status': 'ok'},
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final health = await client.getHealth();

    expect(health.isOk, isTrue);
    expect(transport.requested.single.path, '/health');
  });

  test('getDiagnostics parses degraded repair summary', () async {
    final transport = _FakeTransport({
      '/v1/diagnostics': {
        'status': 'degraded',
        'tools': [
          {'name': 'ffprobe', 'available': false},
        ],
      },
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final diagnostics = await client.getDiagnostics();

    expect(diagnostics.isReady, isFalse);
    expect(diagnostics.summary, 'Engine degraded: missing ffprobe');
    expect(transport.requested.single.path, '/v1/diagnostics');
  });

  test('probeMedia posts path and parses metadata', () async {
    final transport = _FakeTransport({
      '/v1/media/probe': {
        'metadata': {
          'path': '/tmp/input.mp4',
          'duration_seconds': 3.5,
          'width': 320,
          'height': 180,
          'format': 'mov,mp4,m4a,3gp,3g2,mj2',
          'size_bytes': 1234,
        },
      },
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final metadata = await client.probeMedia('/tmp/input.mp4');

    expect(metadata.durationSeconds, 3.5);
    expect(metadata.width, 320);
    expect(metadata.height, 180);
    expect(transport.methods.single, 'POST');
    expect(transport.requested.single.path, '/v1/media/probe');
    expect(transport.bodies.single, {'path': '/tmp/input.mp4'});
  });

  test('generateThumbnail posts input and output paths', () async {
    final transport = _FakeTransport({
      '/v1/media/thumbnail': {'output_path': '/tmp/thumb.jpg'},
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final result = await client.generateThumbnail(
      inputPath: '/tmp/input.mp4',
      outputPath: '/tmp/thumb.jpg',
    );

    expect(result.outputPath, '/tmp/thumb.jpg');
    expect(transport.requested.single.path, '/v1/media/thumbnail');
    expect(transport.bodies.single, {
      'source_path': '/tmp/input.mp4',
      'output_path': '/tmp/thumb.jpg',
    });
  });

  test('renderClip posts clip bounds and output path', () async {
    final transport = _FakeTransport({
      '/v1/media/render-clip': {'output_path': '/tmp/clip.mp4'},
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final result = await client.renderClip(
      inputPath: '/tmp/input.mp4',
      outputPath: '/tmp/clip.mp4',
      startSeconds: 1.0,
      endSeconds: 2.5,
    );

    expect(result.outputPath, '/tmp/clip.mp4');
    expect(transport.requested.single.path, '/v1/media/render-clip');
    expect(transport.bodies.single, {
      'source_path': '/tmp/input.mp4',
      'output_path': '/tmp/clip.mp4',
      'start_seconds': 1.0,
      'end_seconds': 2.5,
    });
  });

  test('media operations throw on non-2xx Engine response', () async {
    final transport = _FakeTransport({
      '/v1/media/probe': {'error': 'ffprobe failed'},
    })..statusCode = 500;
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    expect(
      () => client.probeMedia('/tmp/input.mp4'),
      throwsA(isA<EngineApiException>()),
    );
  });

  test('startUrlIngest posts request and parses job', () async {
    final transport = _FakeTransport({
      '/v1/ingest/url': {
        'job': {
          'id': 'job_1',
          'kind': 'url_ingest',
          'status': 'queued',
          'progress': 0.0,
          'logs': ['queued'],
          'result': null,
          'error': null,
          'cancel_requested': false,
        },
      },
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final job = await client.startUrlIngest(
      url: 'https://example.com/video',
      outputDir: '/tmp',
      outputTemplate: 'video.%(ext)s',
    );

    expect(job.id, 'job_1');
    expect(job.kind, 'url_ingest');
    expect(transport.requested.single.path, '/v1/ingest/url');
    expect(transport.bodies.single, {
      'url': 'https://example.com/video',
      'output_dir': '/tmp',
      'output_template': 'video.%(ext)s',
    });
  });

  test('job endpoints parse status, logs, and cancellation', () async {
    final transport = _FakeTransport({
      '/v1/jobs/job_1': {
        'id': 'job_1',
        'kind': 'url_ingest',
        'status': 'succeeded',
        'progress': 1.0,
        'logs': ['queued', 'completed'],
        'result': {
          'url': 'https://example.com/video',
          'media_path': '/tmp/video.mp4',
          'metadata': {'title': 'Example'},
        },
        'error': null,
        'cancel_requested': false,
      },
      '/v1/jobs/job_1/logs': {
        'job_id': 'job_1',
        'logs': ['queued', 'completed'],
      },
      '/v1/jobs/job_1/cancel': {
        'id': 'job_1',
        'kind': 'url_ingest',
        'status': 'cancelled',
        'progress': 1.0,
        'logs': ['cancel requested'],
        'result': null,
        'error': 'job cancelled',
        'cancel_requested': true,
      },
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final job = await client.getJob('job_1');
    final result = EngineUrlIngestResult.fromJson(job.result!);
    final logs = await client.getJobLogs('job_1');
    final cancelled = await client.cancelJob('job_1');

    expect(job.isTerminal, isTrue);
    expect(result.mediaPath, '/tmp/video.mp4');
    expect(logs.logs, ['queued', 'completed']);
    expect(cancelled.status, 'cancelled');
    expect(cancelled.cancelRequested, isTrue);
  });

  test('startTranscriptDownload posts request', () async {
    final transport = _FakeTransport({
      '/v1/transcripts/download': {
        'job': {
          'id': 'job_t',
          'kind': 'transcript_download',
          'status': 'queued',
          'progress': 0.0,
          'logs': ['queued'],
          'result': null,
          'error': null,
          'cancel_requested': false,
        },
      },
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final job = await client.startTranscriptDownload(
      url: 'https://example.com/video',
      outputPath: '/tmp/video.vtt',
      language: 'en',
    );

    expect(job.id, 'job_t');
    expect(transport.requested.single.path, '/v1/transcripts/download');
    expect(transport.bodies.single, {
      'url': 'https://example.com/video',
      'output_path': '/tmp/video.vtt',
      'language': 'en',
    });
  });
}
