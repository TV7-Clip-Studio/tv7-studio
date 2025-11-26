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
    required this.startSec,

    required this.endSec,

    this.localPath,

    this.assetUrl,

    this.assetChecksum,

    this.assetSizeBytes,

    this.readyLocalOnly = false,

    this.captionText,

    this.renderWidth,

    this.renderHeight,

    this.frameRate,

    this.fileSizeBytes,

    this.status = ClipStatus.ready,
  });

  @JsonKey(name: r'start_sec', required: true)
  final int startSec;

  @JsonKey(name: r'end_sec', required: true)
  final int endSec;

  @JsonKey(name: r'local_path', required: false)
  final String? localPath;

  @JsonKey(name: r'asset_url', required: false)
  final String? assetUrl;

  @JsonKey(name: r'asset_checksum', required: false)
  final String? assetChecksum;

  @JsonKey(name: r'asset_size_bytes', required: false)
  final int? assetSizeBytes;

  @JsonKey(defaultValue: false, name: r'ready_local_only', required: false)
  final bool? readyLocalOnly;

  @JsonKey(name: r'caption_text', required: false)
  final String? captionText;

  @JsonKey(name: r'render_width', required: false)
  final int? renderWidth;

  @JsonKey(name: r'render_height', required: false)
  final int? renderHeight;

  @JsonKey(name: r'frame_rate', required: false)
  final num? frameRate;

  @JsonKey(name: r'file_size_bytes', required: false)
  final int? fileSizeBytes;

  @JsonKey(defaultValue: ClipStatus.ready, name: r'status', required: false)
  final ClipStatus? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipUpsert &&
          other.startSec == startSec &&
          other.endSec == endSec &&
          other.localPath == localPath &&
          other.assetUrl == assetUrl &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.readyLocalOnly == readyLocalOnly &&
          other.captionText == captionText &&
          other.renderWidth == renderWidth &&
          other.renderHeight == renderHeight &&
          other.frameRate == frameRate &&
          other.fileSizeBytes == fileSizeBytes &&
          other.status == status;

  @override
  int get hashCode =>
      startSec.hashCode +
      endSec.hashCode +
      (localPath == null ? 0 : localPath.hashCode) +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      readyLocalOnly.hashCode +
      (captionText == null ? 0 : captionText.hashCode) +
      (renderWidth == null ? 0 : renderWidth.hashCode) +
      (renderHeight == null ? 0 : renderHeight.hashCode) +
      (frameRate == null ? 0 : frameRate.hashCode) +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      status.hashCode;

  factory ClipUpsert.fromJson(Map<String, dynamic> json) =>
      _$ClipUpsertFromJson(json);

  Map<String, dynamic> toJson() => _$ClipUpsertToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
