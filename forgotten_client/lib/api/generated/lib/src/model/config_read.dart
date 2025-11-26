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
    required this.publishingEnabled,

    required this.assetUploadRequired,

    required this.allowedPlatforms,

    this.maxAssetSizeBytes,

    this.maxVideoDurationSeconds,

    this.publishModes,
  });

  @JsonKey(name: r'publishing_enabled', required: true)
  final bool publishingEnabled;

  @JsonKey(name: r'asset_upload_required', required: true)
  final bool assetUploadRequired;

  @JsonKey(name: r'allowed_platforms', required: true)
  final List<String> allowedPlatforms;

  @JsonKey(name: r'max_asset_size_bytes', required: false)
  final int? maxAssetSizeBytes;

  @JsonKey(name: r'max_video_duration_seconds', required: false)
  final int? maxVideoDurationSeconds;

  @JsonKey(name: r'publish_modes', required: false)
  final List<ConfigReadPublishModesEnum>? publishModes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigRead &&
          other.publishingEnabled == publishingEnabled &&
          other.assetUploadRequired == assetUploadRequired &&
          other.allowedPlatforms == allowedPlatforms &&
          other.maxAssetSizeBytes == maxAssetSizeBytes &&
          other.maxVideoDurationSeconds == maxVideoDurationSeconds &&
          other.publishModes == publishModes;

  @override
  int get hashCode =>
      publishingEnabled.hashCode +
      assetUploadRequired.hashCode +
      allowedPlatforms.hashCode +
      (maxAssetSizeBytes == null ? 0 : maxAssetSizeBytes.hashCode) +
      (maxVideoDurationSeconds == null ? 0 : maxVideoDurationSeconds.hashCode) +
      publishModes.hashCode;

  factory ConfigRead.fromJson(Map<String, dynamic> json) =>
      _$ConfigReadFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
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
