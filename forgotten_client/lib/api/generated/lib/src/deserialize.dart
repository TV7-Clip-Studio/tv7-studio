// @dart=3.4
import 'package:forgotten_client_api/src/model/ai_request.dart';
import 'package:forgotten_client_api/src/model/ai_response.dart';
import 'package:forgotten_client_api/src/model/activate_license_request.dart';
import 'package:forgotten_client_api/src/model/asset_upload_response.dart';
import 'package:forgotten_client_api/src/model/clip_read.dart';
import 'package:forgotten_client_api/src/model/clip_update_request.dart';
import 'package:forgotten_client_api/src/model/clip_upsert.dart';
import 'package:forgotten_client_api/src/model/config_read.dart';
import 'package:forgotten_client_api/src/model/http_validation_error.dart';
import 'package:forgotten_client_api/src/model/highlight_request.dart';
import 'package:forgotten_client_api/src/model/highlight_response.dart';
import 'package:forgotten_client_api/src/model/license_status.dart';
import 'package:forgotten_client_api/src/model/local_video_create.dart';
import 'package:forgotten_client_api/src/model/login_request.dart';
import 'package:forgotten_client_api/src/model/publish_job_read.dart';
import 'package:forgotten_client_api/src/model/publish_request.dart';
import 'package:forgotten_client_api/src/model/suggested_clip.dart';
import 'package:forgotten_client_api/src/model/token.dart';
import 'package:forgotten_client_api/src/model/token_refresh_request.dart';
import 'package:forgotten_client_api/src/model/user_create.dart';
import 'package:forgotten_client_api/src/model/user_read.dart';
import 'package:forgotten_client_api/src/model/validation_error.dart';
import 'package:forgotten_client_api/src/model/video_ingest_response.dart';
import 'package:forgotten_client_api/src/model/video_read.dart';
import 'package:forgotten_client_api/src/model/you_tube_ingest_request.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType,
    {bool growable = true}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AIRequest':
      return AIRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AIResponse':
      return AIResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ActivateLicenseRequest':
      return ActivateLicenseRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AssetUploadResponse':
      return AssetUploadResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClipGenerationMode':
    case 'ClipRead':
      return ClipRead.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ClipStatus':
    case 'ClipUpdateRequest':
      return ClipUpdateRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClipUpsert':
      return ClipUpsert.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ConfigRead':
      return ConfigRead.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HTTPValidationError':
      return HTTPValidationError.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HighlightRequest':
      return HighlightRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HighlightResponse':
      return HighlightResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LicenseStatus':
      return LicenseStatus.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LocalVideoCreate':
      return LocalVideoCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LoginRequest':
      return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PlanType':
    case 'PublishJobRead':
      return PublishJobRead.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublishJobStatus':
    case 'PublishRequest':
      return PublishRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SuggestedClip':
      return SuggestedClip.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Token':
      return Token.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TokenRefreshRequest':
      return TokenRefreshRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'UserCreate':
      return UserCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UserRead':
      return UserRead.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ValidationError':
      return ValidationError.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VideoIngestResponse':
      return VideoIngestResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VideoIngestType':
    case 'VideoRead':
      return VideoRead.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VideoStatus':
    case 'YouTubeIngestRequest':
      return YouTubeIngestRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toList(growable: growable) as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toSet() as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map((dynamic v) => deserialize<BaseType, BaseType>(
              v, targetType,
              growable: growable)),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
