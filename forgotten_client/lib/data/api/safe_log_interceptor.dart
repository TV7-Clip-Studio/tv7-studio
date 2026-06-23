import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const _redacted = '<redacted>';

class SafeLogInterceptor extends Interceptor {
  SafeLogInterceptor({required this.prefix, this.logPrint});

  final String prefix;
  final void Function(String message)? logPrint;

  void _log(String message) {
    (logPrint ?? debugPrint)('[$prefix] $message');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('*** Request ***');
    _log('uri: ${options.uri}');
    _log('method: ${options.method}');
    if (options.headers.isNotEmpty) {
      _log('headers: ${sanitizeForLog(options.headers)}');
    }
    if (options.data != null) {
      _log('data: ${sanitizeForLog(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log('*** Response ***');
    _log('uri: ${response.requestOptions.uri}');
    _log('statusCode: ${response.statusCode}');
    if (response.data != null) {
      _log('data: ${sanitizeForLog(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('*** Error ***');
    _log('uri: ${err.requestOptions.uri}');
    _log('type: ${err.type}');
    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      _log('statusCode: $statusCode');
    }
    final data = err.response?.data;
    if (data != null) {
      _log('data: ${sanitizeForLog(data)}');
    }
    handler.next(err);
  }
}

@visibleForTesting
Object? sanitizeForLog(Object? value) {
  if (value == null) return null;
  if (value is Map) {
    return value.map((key, rawValue) {
      final keyText = key.toString();
      return MapEntry(
        key,
        _isSensitiveKey(keyText) ? _redacted : sanitizeForLog(rawValue),
      );
    });
  }
  if (value is Iterable) {
    return value.map(sanitizeForLog).toList();
  }
  if (value is String) {
    return _sanitizeString(value);
  }
  if (value is FormData) {
    return {
      'fields': sanitizeForLog(Map.fromEntries(value.fields)),
      'files': value.files.map((file) => file.key).toList(),
    };
  }
  final jsonValue = _tryToJson(value);
  if (jsonValue != null && !identical(jsonValue, value)) {
    return sanitizeForLog(jsonValue);
  }
  return value;
}

Object? _tryToJson(Object value) {
  try {
    final dynamic dynamicValue = value;
    return dynamicValue.toJson();
  } catch (_) {
    return null;
  }
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase().replaceAll('-', '_');
  return normalized == 'authorization' ||
      normalized == 'password' ||
      normalized == 'access_token' ||
      normalized == 'refresh_token' ||
      normalized == 'id_token' ||
      normalized == 'api_key' ||
      normalized == 'secret' ||
      normalized.endsWith('_secret') ||
      normalized.endsWith('_token');
}

String _sanitizeString(String value) {
  if (value.startsWith('Bearer ')) return 'Bearer $_redacted';
  final trimmed = value.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      final decoded = jsonDecode(trimmed);
      final sanitized = sanitizeForLog(decoded);
      return jsonEncode(sanitized);
    } catch (_) {}
  }
  return value;
}
