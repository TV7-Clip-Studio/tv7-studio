// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'asset_upload_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssetUploadResponse {
  /// Returns a new [AssetUploadResponse] instance.
  AssetUploadResponse({
    required this.assetChecksum,
    required this.assetSizeBytes,
    required this.assetUrl,
    this.contentType,
  });

  @JsonKey(
    name: r'asset_checksum',
    required: true,
    includeIfNull: false,
  )
  final String assetChecksum;

  @JsonKey(
    name: r'asset_size_bytes',
    required: true,
    includeIfNull: false,
  )
  final int assetSizeBytes;

  @JsonKey(
    name: r'asset_url',
    required: true,
    includeIfNull: false,
  )
  final String assetUrl;

  @JsonKey(
    name: r'content_type',
    required: false,
    includeIfNull: false,
  )
  final String? contentType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetUploadResponse &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.assetUrl == assetUrl &&
          other.contentType == contentType;

  @override
  int get hashCode =>
      assetChecksum.hashCode +
      assetSizeBytes.hashCode +
      assetUrl.hashCode +
      (contentType == null ? 0 : contentType.hashCode);

  factory AssetUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AssetUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssetUploadResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
