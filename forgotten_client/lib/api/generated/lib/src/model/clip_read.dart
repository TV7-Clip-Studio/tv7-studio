// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/clip_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clip_read.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClipRead {
  /// Returns a new [ClipRead] instance.
  ClipRead({
    this.assetChecksum,
    this.assetSizeBytes,
    this.assetUrl,
    required this.captionText,
    required this.createdAt,
    required this.endSec,
    this.fileSizeBytes,
    this.frameRate,
    required this.id,
    required this.localPath,
    this.readyLocalOnly = false,
    this.renderHeight,
    this.renderWidth,
    required this.startSec,
    required this.status,
    this.thumbnailPath,
    required this.updatedAt,
    required this.videoId,
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
    required: true,
    includeIfNull: true,
  )
  final String? captionText;

  @JsonKey(
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

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
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final int id;

  @JsonKey(
    name: r'local_path',
    required: true,
    includeIfNull: true,
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
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final ClipStatus status;

  @JsonKey(
    name: r'thumbnail_path',
    required: false,
    includeIfNull: false,
  )
  final String? thumbnailPath;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @JsonKey(
    name: r'video_id',
    required: true,
    includeIfNull: false,
  )
  final int videoId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipRead &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.assetUrl == assetUrl &&
          other.captionText == captionText &&
          other.createdAt == createdAt &&
          other.endSec == endSec &&
          other.fileSizeBytes == fileSizeBytes &&
          other.frameRate == frameRate &&
          other.id == id &&
          other.localPath == localPath &&
          other.readyLocalOnly == readyLocalOnly &&
          other.renderHeight == renderHeight &&
          other.renderWidth == renderWidth &&
          other.startSec == startSec &&
          other.status == status &&
          other.thumbnailPath == thumbnailPath &&
          other.updatedAt == updatedAt &&
          other.videoId == videoId;

  @override
  int get hashCode =>
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      (captionText == null ? 0 : captionText.hashCode) +
      createdAt.hashCode +
      endSec.hashCode +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      (frameRate == null ? 0 : frameRate.hashCode) +
      id.hashCode +
      (localPath == null ? 0 : localPath.hashCode) +
      readyLocalOnly.hashCode +
      (renderHeight == null ? 0 : renderHeight.hashCode) +
      (renderWidth == null ? 0 : renderWidth.hashCode) +
      startSec.hashCode +
      status.hashCode +
      (thumbnailPath == null ? 0 : thumbnailPath.hashCode) +
      updatedAt.hashCode +
      videoId.hashCode;

  factory ClipRead.fromJson(Map<String, dynamic> json) =>
      _$ClipReadFromJson(json);

  Map<String, dynamic> toJson() => _$ClipReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
