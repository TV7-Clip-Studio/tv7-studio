import 'dart:convert';
import 'dart:io';

class EngineClient {
  const EngineClient({
    required this.baseUri,
    EngineJsonTransport transport = const DartEngineJsonTransport(),
  }) : _transport = transport;

  final Uri baseUri;
  final EngineJsonTransport _transport;

  Future<EngineHealth> getHealth() async {
    final response = await request('GET', '/health');
    return EngineHealth.fromJson(response.json);
  }

  Future<EngineDiagnostics> getDiagnostics() async {
    final response = await request('GET', '/v1/diagnostics');
    return EngineDiagnostics.fromJson(response.json);
  }

  Future<EngineMediaMetadata> probeMedia(String path) async {
    final response = await request(
      'POST',
      '/v1/media/probe',
      body: {'path': path},
    );
    _ensureSuccess(response);
    final metadata = response.json['metadata'];
    if (metadata is! Map<String, dynamic>) {
      throw const FormatException('Engine probe response missing metadata');
    }
    return EngineMediaMetadata.fromJson(metadata);
  }

  Future<EngineThumbnailResult> generateThumbnail({
    required String inputPath,
    required String outputPath,
  }) async {
    final response = await request(
      'POST',
      '/v1/media/thumbnail',
      body: {'source_path': inputPath, 'output_path': outputPath},
    );
    _ensureSuccess(response);
    return EngineThumbnailResult.fromJson(_resultJson(response.json));
  }

  Future<EngineRenderClipResult> renderClip({
    required String inputPath,
    required String outputPath,
    required double startSeconds,
    required double endSeconds,
  }) async {
    final response = await request(
      'POST',
      '/v1/media/render-clip',
      body: {
        'source_path': inputPath,
        'output_path': outputPath,
        'start_seconds': startSeconds,
        'end_seconds': endSeconds,
      },
    );
    _ensureSuccess(response);
    return EngineRenderClipResult.fromJson(_resultJson(response.json));
  }

  Future<EngineJob> startUrlIngest({
    required String url,
    required String outputDir,
    String? outputTemplate,
  }) async {
    final response = await request(
      'POST',
      '/v1/ingest/url',
      body: {
        'url': url,
        'output_dir': outputDir,
        if (outputTemplate != null) 'output_template': outputTemplate,
      },
    );
    _ensureSuccess(response);
    return EngineJob.fromJson(_jobJson(response.json));
  }

  Future<EngineJob> startTranscriptDownload({
    required String url,
    required String outputPath,
    String? language,
  }) async {
    final response = await request(
      'POST',
      '/v1/transcripts/download',
      body: {
        'url': url,
        'output_path': outputPath,
        if (language != null) 'language': language,
      },
    );
    _ensureSuccess(response);
    return EngineJob.fromJson(_jobJson(response.json));
  }

  Future<EngineJob> getJob(String id) async {
    final response = await request('GET', '/v1/jobs/$id');
    _ensureSuccess(response);
    return EngineJob.fromJson(response.json);
  }

  Future<EngineJobLogs> getJobLogs(String id) async {
    final response = await request('GET', '/v1/jobs/$id/logs');
    _ensureSuccess(response);
    return EngineJobLogs.fromJson(response.json);
  }

  Future<EngineJob> cancelJob(String id) async {
    final response = await request('POST', '/v1/jobs/$id/cancel');
    _ensureSuccess(response);
    return EngineJob.fromJson(response.json);
  }

  Future<EngineHttpResponse> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _transport.request(method, _uri(path), body: body);
  }

  Uri _uri(String path) => baseUri.replace(path: path);

  void _ensureSuccess(EngineHttpResponse response) {
    if (response.isSuccess) return;
    throw EngineApiException(
      statusCode: response.statusCode,
      response: response.json,
    );
  }

  Map<String, dynamic> _resultJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) return result;
    return json;
  }

  Map<String, dynamic> _jobJson(Map<String, dynamic> json) {
    final job = json['job'];
    if (job is Map<String, dynamic>) return job;
    throw const FormatException('Engine response missing job');
  }
}

class EngineApiException implements Exception {
  const EngineApiException({required this.statusCode, required this.response});

  final int statusCode;
  final Map<String, dynamic> response;

  @override
  String toString() {
    final error = response['error']?.toString();
    if (error != null && error.isNotEmpty) {
      return 'EngineApiException($statusCode): $error';
    }
    return 'EngineApiException($statusCode)';
  }
}

abstract class EngineJsonTransport {
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  });
}

class DartEngineJsonTransport implements EngineJsonTransport {
  const DartEngineJsonTransport({this.timeout = const Duration(seconds: 2)});

  final Duration timeout;

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final stopwatch = Stopwatch()..start();
      final request = await client.openUrl(method, uri).timeout(timeout);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      stopwatch.stop();
      final bodyText = await response.transform(utf8.decoder).join();
      final decoded = bodyText.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(bodyText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Engine response was not a JSON object');
      }
      return EngineHttpResponse(
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        json: decoded,
        rawBody: bodyText,
      );
    } finally {
      client.close(force: true);
    }
  }
}

class EngineHttpResponse {
  const EngineHttpResponse({
    required this.statusCode,
    required this.elapsed,
    required this.json,
    required this.rawBody,
  });

  final int statusCode;
  final Duration elapsed;
  final Map<String, dynamic> json;
  final String rawBody;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class EngineHealth {
  const EngineHealth({required this.status, required this.raw});

  factory EngineHealth.fromJson(Map<String, dynamic> json) {
    return EngineHealth(
      status: json['status']?.toString() ?? 'unknown',
      raw: json,
    );
  }

  final String status;
  final Map<String, dynamic> raw;

  bool get isOk => status == 'ok';
}

class EngineDiagnostics {
  const EngineDiagnostics({required this.status, required this.raw});

  factory EngineDiagnostics.fromJson(Map<String, dynamic> json) {
    return EngineDiagnostics(
      status: json['status']?.toString() ?? 'unknown',
      raw: json,
    );
  }

  final String status;
  final Map<String, dynamic> raw;

  bool get isReady => status == 'ready';

  String get summary {
    if (isReady) return 'Engine ready';

    final tools = raw['tools'];
    if (tools is List) {
      final unavailable = tools
          .whereType<Map<String, dynamic>>()
          .where((tool) => tool['available'] == false)
          .map((tool) => tool['name']?.toString())
          .whereType<String>()
          .toList();
      if (unavailable.isNotEmpty) {
        return 'Engine degraded: missing ${unavailable.join(', ')}';
      }
    }

    final workDir = raw['work_dir'];
    if (workDir is Map<String, dynamic> && workDir['ready'] == false) {
      final error = workDir['error']?.toString();
      return error == null || error.isEmpty
          ? 'Engine degraded: work directory is not ready'
          : 'Engine degraded: $error';
    }

    return 'Engine degraded: diagnostics status is $status';
  }
}

class EngineMediaMetadata {
  const EngineMediaMetadata({
    required this.path,
    this.durationSeconds,
    this.width,
    this.height,
    this.format,
    this.sizeBytes,
  });

  factory EngineMediaMetadata.fromJson(Map<String, dynamic> json) {
    return EngineMediaMetadata(
      path: json['path']?.toString() ?? '',
      durationSeconds: _toDouble(json['duration_seconds']),
      width: _toInt(json['width']),
      height: _toInt(json['height']),
      format: json['format']?.toString(),
      sizeBytes: _toInt(json['size_bytes']),
    );
  }

  final String path;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final String? format;
  final int? sizeBytes;

  Map<String, dynamic> toFfprobeLikeJson() {
    return {
      'format': {
        if (durationSeconds != null) 'duration': durationSeconds.toString(),
        if (format != null) 'format_name': format,
      },
      'streams': [
        if (width != null || height != null)
          {
            'codec_type': 'video',
            if (width != null) 'width': width,
            if (height != null) 'height': height,
          },
      ],
      if (path.isNotEmpty) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
    };
  }
}

class EngineThumbnailResult {
  const EngineThumbnailResult({required this.outputPath});

  factory EngineThumbnailResult.fromJson(Map<String, dynamic> json) {
    return EngineThumbnailResult(
      outputPath: json['output_path']?.toString() ?? '',
    );
  }

  final String outputPath;
}

class EngineRenderClipResult {
  const EngineRenderClipResult({required this.outputPath});

  factory EngineRenderClipResult.fromJson(Map<String, dynamic> json) {
    return EngineRenderClipResult(
      outputPath: json['output_path']?.toString() ?? '',
    );
  }

  final String outputPath;
}

class EngineJob {
  const EngineJob({
    required this.id,
    required this.kind,
    required this.status,
    required this.progress,
    required this.logs,
    required this.result,
    required this.error,
    required this.cancelRequested,
  });

  factory EngineJob.fromJson(Map<String, dynamic> json) {
    return EngineJob(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'unknown',
      status: json['status']?.toString() ?? 'unknown',
      progress: _toDouble(json['progress']) ?? 0,
      logs:
          (json['logs'] as List?)?.map((value) => value.toString()).toList() ??
          const [],
      result: json['result'] is Map<String, dynamic>
          ? json['result'] as Map<String, dynamic>
          : null,
      error: json['error']?.toString(),
      cancelRequested: json['cancel_requested'] == true,
    );
  }

  final String id;
  final String kind;
  final String status;
  final double progress;
  final List<String> logs;
  final Map<String, dynamic>? result;
  final String? error;
  final bool cancelRequested;

  bool get isTerminal =>
      status == 'succeeded' || status == 'failed' || status == 'cancelled';
}

class EngineJobLogs {
  const EngineJobLogs({required this.jobId, required this.logs});

  factory EngineJobLogs.fromJson(Map<String, dynamic> json) {
    return EngineJobLogs(
      jobId: json['job_id']?.toString() ?? '',
      logs:
          (json['logs'] as List?)?.map((value) => value.toString()).toList() ??
          const [],
    );
  }

  final String jobId;
  final List<String> logs;
}

class EngineUrlIngestResult {
  const EngineUrlIngestResult({
    required this.url,
    this.mediaPath,
    required this.metadata,
  });

  factory EngineUrlIngestResult.fromJson(Map<String, dynamic> json) {
    return EngineUrlIngestResult(
      url: json['url']?.toString() ?? '',
      mediaPath: json['media_path']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  final String url;
  final String? mediaPath;
  final Map<String, dynamic> metadata;
}

class EngineTranscriptDownloadResult {
  const EngineTranscriptDownloadResult({
    required this.language,
    this.transcriptPath,
  });

  factory EngineTranscriptDownloadResult.fromJson(Map<String, dynamic> json) {
    return EngineTranscriptDownloadResult(
      language: json['language']?.toString() ?? 'en',
      transcriptPath: json['transcript_path']?.toString(),
    );
  }

  final String language;
  final String? transcriptPath;
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
