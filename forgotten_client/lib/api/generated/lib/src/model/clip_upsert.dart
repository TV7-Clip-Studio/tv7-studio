// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/clip_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clip_upsert.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClipUpsert {
  /// Returns a new [ClipUpsert] instance.
  ClipUpsert({
    this.assetChecksum,
    this.assetSizeBytes,
    this.assetUrl,
    this.captionText,
    required this.endSec,
    this.fileSizeBytes,
    this.frameRate,
    this.localPath,
    this.readyLocalOnly = false,
    this.renderHeight,
    this.renderWidth,
    required this.startSec,
    this.status = ClipStatus.ready,
    this.thumbnailPath,
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
    name: r'end_sec',
    required: true,
    includeIfNull: false,
  )
  final int endSec;

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
    name: r'local_path',
    required: false,
    includeIfNull: false,
  )
  final String? localPath;

  @JsonKey(
    defaultValue: false,
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

  @JsonKey(
    name: r'start_sec',
    required: true,
    includeIfNull: false,
  )
  final int startSec;

  @JsonKey(
    defaultValue: ClipStatus.ready,
    name: r'status',
    required: false,
    includeIfNull: false,
  )
  final ClipStatus? status;

  @JsonKey(
    name: r'thumbnail_path',
    required: false,
    includeIfNull: false,
  )
  final String? thumbnailPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipUpsert &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.assetUrl == assetUrl &&
          other.captionText == captionText &&
          other.endSec == endSec &&
          other.fileSizeBytes == fileSizeBytes &&
          other.frameRate == frameRate &&
          other.localPath == localPath &&
          other.readyLocalOnly == readyLocalOnly &&
          other.renderHeight == renderHeight &&
          other.renderWidth == renderWidth &&
          other.startSec == startSec &&
          other.status == status &&
          other.thumbnailPath == thumbnailPath;

  @override
  int get hashCode =>
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      (captionText == null ? 0 : captionText.hashCode) +
      endSec.hashCode +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      (frameRate == null ? 0 : frameRate.hashCode) +
      (localPath == null ? 0 : localPath.hashCode) +
      readyLocalOnly.hashCode +
      (renderHeight == null ? 0 : renderHeight.hashCode) +
      (renderWidth == null ? 0 : renderWidth.hashCode) +
      startSec.hashCode +
      status.hashCode +
      (thumbnailPath == null ? 0 : thumbnailPath.hashCode);

  factory ClipUpsert.fromJson(Map<String, dynamic> json) =>
      _$ClipUpsertFromJson(json);

  Map<String, dynamic> toJson() => _$ClipUpsertToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
