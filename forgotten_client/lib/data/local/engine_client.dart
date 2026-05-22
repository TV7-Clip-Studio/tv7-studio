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

  Future<EngineHttpResponse> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _transport.request(method, _uri(path), body: body);
  }

  Uri _uri(String path) => baseUri.replace(path: path);
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
