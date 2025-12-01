// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clip_update_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClipUpdateRequest {
  /// Returns a new [ClipUpdateRequest] instance.
  ClipUpdateRequest({
    this.assetChecksum,
    this.assetSizeBytes,
    this.assetUrl,
    this.captionText,
    this.fileSizeBytes,
    this.frameRate,
    this.readyLocalOnly,
    this.renderHeight,
    this.renderWidth,
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
    name: r'caption_text',
    required: false,
    includeIfNull: false,
  )
  final String? captionText;

  @JsonKey(
    name: r'file_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? fileSizeBytes;

  @JsonKey(
    name: r'frame_rate',
    required: false,
    includeIfNull: false,
  )
  final num? frameRate;

  @JsonKey(
    name: r'ready_local_only',
    required: false,
    includeIfNull: false,
  )
  final bool? readyLocalOnly;

  @JsonKey(
    name: r'render_height',
    required: false,
    includeIfNull: false,
  )
  final int? renderHeight;

  @JsonKey(
    name: r'render_width',
    required: false,
    includeIfNull: false,
  )
  final int? renderWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipUpdateRequest &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.assetUrl == assetUrl &&
          other.captionText == captionText &&
          other.fileSizeBytes == fileSizeBytes &&
          other.frameRate == frameRate &&
          other.readyLocalOnly == readyLocalOnly &&
          other.renderHeight == renderHeight &&
          other.renderWidth == renderWidth;

  @override
  int get hashCode =>
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      (captionText == null ? 0 : captionText.hashCode) +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      (frameRate == null ? 0 : frameRate.hashCode) +
      (readyLocalOnly == null ? 0 : readyLocalOnly.hashCode) +
      (renderHeight == null ? 0 : renderHeight.hashCode) +
      (renderWidth == null ? 0 : renderWidth.hashCode);

  factory ClipUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ClipUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClipUpdateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
