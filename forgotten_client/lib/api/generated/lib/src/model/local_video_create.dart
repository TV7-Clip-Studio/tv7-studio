// @dart=3.4
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
    this.clipGenerationMode = ClipGenerationMode.replace,
    this.clips,
    this.durationSeconds,
    this.fileSizeBytes,
    this.localPath,
    this.metadataOnly = false,
    this.originalFilename,
    required this.sourceUrl,
    this.status = VideoStatus.ready,
    this.title,
    this.transcriptLanguage,
    this.transcriptText,
    this.uploadChecksum,
    this.uploadFileSizeBytes,
    this.workspaceRoot,
  });

  @JsonKey(
    defaultValue: ClipGenerationMode.replace,
    name: r'clip_generation_mode',
    required: false,
    includeIfNull: false,
  )
  final ClipGenerationMode? clipGenerationMode;

  @JsonKey(
    name: r'clips',
    required: false,
    includeIfNull: false,
  )
  final List<ClipUpsert>? clips;

  @JsonKey(
    name: r'duration_seconds',
    required: false,
    includeIfNull: false,
  )
  final int? durationSeconds;

  @JsonKey(
    name: r'file_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? fileSizeBytes;

  @JsonKey(
    name: r'local_path',
    required: false,
    includeIfNull: false,
  )
  final String? localPath;

  /// If true, server will not attempt to download or host the source video.
  @JsonKey(
    defaultValue: false,
    name: r'metadata_only',
    required: false,
    includeIfNull: false,
  )
  final bool? metadataOnly;

  @JsonKey(
    name: r'original_filename',
    required: false,
    includeIfNull: false,
  )
  final String? originalFilename;

  /// Identifier for the local video (e.g., file:// or local://)
  @JsonKey(
    name: r'source_url',
    required: true,
    includeIfNull: false,
  )
  final String sourceUrl;

  @JsonKey(
    defaultValue: VideoStatus.ready,
    name: r'status',
    required: false,
    includeIfNull: false,
  )
  final VideoStatus? status;

  @JsonKey(
    name: r'title',
    required: false,
    includeIfNull: false,
  )
  final String? title;

  @JsonKey(
    name: r'transcript_language',
    required: false,
    includeIfNull: false,
  )
  final String? transcriptLanguage;

  @JsonKey(
    name: r'transcript_text',
    required: false,
    includeIfNull: false,
  )
  final String? transcriptText;

  @JsonKey(
    name: r'upload_checksum',
    required: false,
    includeIfNull: false,
  )
  final String? uploadChecksum;

  @JsonKey(
    name: r'upload_file_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? uploadFileSizeBytes;

  @JsonKey(
    name: r'workspace_root',
    required: false,
    includeIfNull: false,
  )
  final String? workspaceRoot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalVideoCreate &&
          other.clipGenerationMode == clipGenerationMode &&
          other.clips == clips &&
          other.durationSeconds == durationSeconds &&
          other.fileSizeBytes == fileSizeBytes &&
          other.localPath == localPath &&
          other.metadataOnly == metadataOnly &&
          other.originalFilename == originalFilename &&
          other.sourceUrl == sourceUrl &&
          other.status == status &&
          other.title == title &&
          other.transcriptLanguage == transcriptLanguage &&
          other.transcriptText == transcriptText &&
          other.uploadChecksum == uploadChecksum &&
          other.uploadFileSizeBytes == uploadFileSizeBytes &&
          other.workspaceRoot == workspaceRoot;

  @override
  int get hashCode =>
      clipGenerationMode.hashCode +
      (clips == null ? 0 : clips.hashCode) +
      (durationSeconds == null ? 0 : durationSeconds.hashCode) +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      (localPath == null ? 0 : localPath.hashCode) +
      metadataOnly.hashCode +
      (originalFilename == null ? 0 : originalFilename.hashCode) +
      sourceUrl.hashCode +
      status.hashCode +
      (title == null ? 0 : title.hashCode) +
      (transcriptLanguage == null ? 0 : transcriptLanguage.hashCode) +
      (transcriptText == null ? 0 : transcriptText.hashCode) +
      (uploadChecksum == null ? 0 : uploadChecksum.hashCode) +
      (uploadFileSizeBytes == null ? 0 : uploadFileSizeBytes.hashCode) +
      (workspaceRoot == null ? 0 : workspaceRoot.hashCode);

  factory LocalVideoCreate.fromJson(Map<String, dynamic> json) =>
      _$LocalVideoCreateFromJson(json);

  Map<String, dynamic> toJson() => _$LocalVideoCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
