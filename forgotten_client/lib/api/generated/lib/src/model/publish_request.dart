// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publish_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishRequest {
  /// Returns a new [PublishRequest] instance.
  PublishRequest({
    this.assetChecksum,
    this.assetSizeBytes,
    this.assetUrl,
    required this.platforms,
  });

  @JsonKey(
    name: r'asset_checksum',
    required: false,
    includeIfNull: false,
  )
  final String? assetChecksum;

  @JsonKey(
    name: r'asset_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? assetSizeBytes;

  @JsonKey(
    name: r'asset_url',
    required: false,
    includeIfNull: false,
  )
  final String? assetUrl;

  @JsonKey(
    name: r'platforms',
    required: true,
    includeIfNull: false,
  )
  final List<String> platforms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishRequest &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.assetUrl == assetUrl &&
          other.platforms == platforms;

  @override
  int get hashCode =>
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      platforms.hashCode;

  factory PublishRequest.fromJson(Map<String, dynamic> json) =>
      _$PublishRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublishRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
