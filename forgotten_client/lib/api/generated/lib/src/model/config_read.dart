// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_read.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConfigRead {
  /// Returns a new [ConfigRead] instance.
  ConfigRead({
    required this.allowedPlatforms,
    required this.assetUploadRequired,
    this.highlightsEnabled = true,
    this.maxAssetSizeBytes,
    this.maxVideoDurationSeconds,
    this.openaiMode = ConfigReadOpenaiModeEnum.backend,
    this.publishModes,
    required this.publishingEnabled,
    this.schedulingEnabled = false,
  });

  @JsonKey(
    name: r'allowed_platforms',
    required: true,
    includeIfNull: false,
  )
  final List<String> allowedPlatforms;

  @JsonKey(
    name: r'asset_upload_required',
    required: true,
    includeIfNull: false,
  )
  final bool assetUploadRequired;

  @JsonKey(
    defaultValue: true,
    name: r'highlights_enabled',
    required: false,
    includeIfNull: false,
  )
  final bool? highlightsEnabled;

  @JsonKey(
    name: r'max_asset_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? maxAssetSizeBytes;

  @JsonKey(
    name: r'max_video_duration_seconds',
    required: false,
    includeIfNull: false,
  )
  final int? maxVideoDurationSeconds;

  @JsonKey(
    defaultValue: 'backend',
    name: r'openai_mode',
    required: false,
    includeIfNull: false,
  )
  final ConfigReadOpenaiModeEnum? openaiMode;

  @JsonKey(
    name: r'publish_modes',
    required: false,
    includeIfNull: false,
  )
  final List<ConfigReadPublishModesEnum>? publishModes;

  @JsonKey(
    name: r'publishing_enabled',
    required: true,
    includeIfNull: false,
  )
  final bool publishingEnabled;

  @JsonKey(
    defaultValue: false,
    name: r'scheduling_enabled',
    required: false,
    includeIfNull: false,
  )
  final bool? schedulingEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigRead &&
          other.allowedPlatforms == allowedPlatforms &&
          other.assetUploadRequired == assetUploadRequired &&
          other.highlightsEnabled == highlightsEnabled &&
          other.maxAssetSizeBytes == maxAssetSizeBytes &&
          other.maxVideoDurationSeconds == maxVideoDurationSeconds &&
          other.openaiMode == openaiMode &&
          other.publishModes == publishModes &&
          other.publishingEnabled == publishingEnabled &&
          other.schedulingEnabled == schedulingEnabled;

  @override
  int get hashCode =>
      allowedPlatforms.hashCode +
      assetUploadRequired.hashCode +
      highlightsEnabled.hashCode +
      (maxAssetSizeBytes == null ? 0 : maxAssetSizeBytes.hashCode) +
      (maxVideoDurationSeconds == null ? 0 : maxVideoDurationSeconds.hashCode) +
      openaiMode.hashCode +
      publishModes.hashCode +
      publishingEnabled.hashCode +
      schedulingEnabled.hashCode;

  factory ConfigRead.fromJson(Map<String, dynamic> json) =>
      _$ConfigReadFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ConfigReadOpenaiModeEnum {
  @JsonValue(r'backend')
  backend(r'backend'),
  @JsonValue(r'client_supplied')
  clientSupplied(r'client_supplied'),
  @JsonValue(r'disabled')
  disabled(r'disabled');

  const ConfigReadOpenaiModeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ConfigReadPublishModesEnum {
  @JsonValue(r'backend_publish')
  backendPublish(r'backend_publish'),
  @JsonValue(r'local_only')
  localOnly(r'local_only');

  const ConfigReadPublishModesEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
