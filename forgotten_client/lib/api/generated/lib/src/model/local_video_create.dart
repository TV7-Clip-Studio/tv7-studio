//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/clip_upsert.dart';
import 'package:forgotten_client_api/src/model/clip_generation_mode.dart';
import 'package:forgotten_client_api/src/model/video_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_video_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalVideoCreate {
  /// Returns a new [LocalVideoCreate] instance.
  LocalVideoCreate({
    required this.sourceUrl,

    this.localPath,

    this.originalFilename,

    this.uploadChecksum,

    this.uploadFileSizeBytes,

    this.durationSeconds,

    this.fileSizeBytes,

    this.transcriptText,

    this.transcriptLanguage,

    this.workspaceRoot,

    this.status = VideoStatus.ready,

    this.clipGenerationMode = ClipGenerationMode.replace,

    this.clips,
  });

  /// Identifier for the local video (e.g., file:// or local://)
  @JsonKey(name: r'source_url', required: true)
  final String sourceUrl;

  @JsonKey(name: r'local_path', required: false)
  final String? localPath;

  @JsonKey(name: r'original_filename', required: false)
  final String? originalFilename;

  @JsonKey(name: r'upload_checksum', required: false)
  final String? uploadChecksum;

  @JsonKey(name: r'upload_file_size_bytes', required: false)
  final int? uploadFileSizeBytes;

  @JsonKey(name: r'duration_seconds', required: false)
  final int? durationSeconds;

  @JsonKey(name: r'file_size_bytes', required: false)
  final int? fileSizeBytes;

  @JsonKey(name: r'transcript_text', required: false)
  final String? transcriptText;

  @JsonKey(name: r'transcript_language', required: false)
  final String? transcriptLanguage;

  @JsonKey(name: r'workspace_root', required: false)
  final String? workspaceRoot;

  @JsonKey(defaultValue: VideoStatus.ready, name: r'status', required: false)
  final VideoStatus? status;

  @JsonKey(
    defaultValue: ClipGenerationMode.replace,
    name: r'clip_generation_mode',
    required: false,
  )
  final ClipGenerationMode? clipGenerationMode;

  @JsonKey(name: r'clips', required: false)
  final List<ClipUpsert>? clips;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalVideoCreate &&
          other.sourceUrl == sourceUrl &&
          other.localPath == localPath &&
          other.originalFilename == originalFilename &&
          other.uploadChecksum == uploadChecksum &&
          other.uploadFileSizeBytes == uploadFileSizeBytes &&
          other.durationSeconds == durationSeconds &&
          other.fileSizeBytes == fileSizeBytes &&
          other.transcriptText == transcriptText &&
          other.transcriptLanguage == transcriptLanguage &&
          other.workspaceRoot == workspaceRoot &&
          other.status == status &&
          other.clipGenerationMode == clipGenerationMode &&
          other.clips == clips;

  @override
  int get hashCode =>
      sourceUrl.hashCode +
      (localPath == null ? 0 : localPath.hashCode) +
      (originalFilename == null ? 0 : originalFilename.hashCode) +
      (uploadChecksum == null ? 0 : uploadChecksum.hashCode) +
      (uploadFileSizeBytes == null ? 0 : uploadFileSizeBytes.hashCode) +
      (durationSeconds == null ? 0 : durationSeconds.hashCode) +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      (transcriptText == null ? 0 : transcriptText.hashCode) +
      (transcriptLanguage == null ? 0 : transcriptLanguage.hashCode) +
      (workspaceRoot == null ? 0 : workspaceRoot.hashCode) +
      status.hashCode +
      clipGenerationMode.hashCode +
      (clips == null ? 0 : clips.hashCode);

  factory LocalVideoCreate.fromJson(Map<String, dynamic> json) =>
      _$LocalVideoCreateFromJson(json);

  Map<String, dynamic> toJson() => _$LocalVideoCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
