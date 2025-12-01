// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/clip_generation_mode.dart';
import 'package:forgotten_client_api/src/model/clip_read.dart';
import 'package:forgotten_client_api/src/model/video_ingest_type.dart';
import 'package:forgotten_client_api/src/model/video_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'video_read.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VideoRead {
  /// Returns a new [VideoRead] instance.
  VideoRead({
    required this.clipGenerationMode,
    this.clips,
    required this.createdAt,
    this.durationSeconds,
    this.errorMessage,
    this.fileSizeBytes,
    required this.id,
    required this.ingestType,
    required this.localPath,
    this.originalFilename,
    this.requestedByUserId,
    required this.sourceUrl,
    required this.status,
    this.transcriptLanguage,
    required this.transcriptText,
    required this.updatedAt,
    this.uploadChecksum,
    this.uploadFileSizeBytes,
    this.workspaceRoot,
  });

  @JsonKey(
    name: r'clip_generation_mode',
    required: true,
    includeIfNull: false,
  )
  final ClipGenerationMode clipGenerationMode;

  @JsonKey(
    name: r'clips',
    required: false,
    includeIfNull: false,
  )
  final List<ClipRead>? clips;

  @JsonKey(
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

  @JsonKey(
    name: r'duration_seconds',
    required: false,
    includeIfNull: false,
  )
  final int? durationSeconds;

  @JsonKey(
    name: r'error_message',
    required: false,
    includeIfNull: false,
  )
  final String? errorMessage;

  @JsonKey(
    name: r'file_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? fileSizeBytes;

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final int id;

  @JsonKey(
    name: r'ingest_type',
    required: true,
    includeIfNull: false,
  )
  final VideoIngestType ingestType;

  @JsonKey(
    name: r'local_path',
    required: true,
    includeIfNull: true,
  )
  final String? localPath;

  @JsonKey(
    name: r'original_filename',
    required: false,
    includeIfNull: false,
  )
  final String? originalFilename;

  @JsonKey(
    name: r'requested_by_user_id',
    required: false,
    includeIfNull: false,
  )
  final int? requestedByUserId;

  @JsonKey(
    name: r'source_url',
    required: true,
    includeIfNull: false,
  )
  final String sourceUrl;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final VideoStatus status;

  @JsonKey(
    name: r'transcript_language',
    required: false,
    includeIfNull: false,
  )
  final String? transcriptLanguage;

  @JsonKey(
    name: r'transcript_text',
    required: true,
    includeIfNull: true,
  )
  final String? transcriptText;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

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
      other is VideoRead &&
          other.clipGenerationMode == clipGenerationMode &&
          other.clips == clips &&
          other.createdAt == createdAt &&
          other.durationSeconds == durationSeconds &&
          other.errorMessage == errorMessage &&
          other.fileSizeBytes == fileSizeBytes &&
          other.id == id &&
          other.ingestType == ingestType &&
          other.localPath == localPath &&
          other.originalFilename == originalFilename &&
          other.requestedByUserId == requestedByUserId &&
          other.sourceUrl == sourceUrl &&
          other.status == status &&
          other.transcriptLanguage == transcriptLanguage &&
          other.transcriptText == transcriptText &&
          other.updatedAt == updatedAt &&
          other.uploadChecksum == uploadChecksum &&
          other.uploadFileSizeBytes == uploadFileSizeBytes &&
          other.workspaceRoot == workspaceRoot;

  @override
  int get hashCode =>
      clipGenerationMode.hashCode +
      clips.hashCode +
      createdAt.hashCode +
      (durationSeconds == null ? 0 : durationSeconds.hashCode) +
      (errorMessage == null ? 0 : errorMessage.hashCode) +
      (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
      id.hashCode +
      ingestType.hashCode +
      (localPath == null ? 0 : localPath.hashCode) +
      (originalFilename == null ? 0 : originalFilename.hashCode) +
      (requestedByUserId == null ? 0 : requestedByUserId.hashCode) +
      sourceUrl.hashCode +
      status.hashCode +
      (transcriptLanguage == null ? 0 : transcriptLanguage.hashCode) +
      (transcriptText == null ? 0 : transcriptText.hashCode) +
      updatedAt.hashCode +
      (uploadChecksum == null ? 0 : uploadChecksum.hashCode) +
      (uploadFileSizeBytes == null ? 0 : uploadFileSizeBytes.hashCode) +
      (workspaceRoot == null ? 0 : workspaceRoot.hashCode);

  factory VideoRead.fromJson(Map<String, dynamic> json) =>
      _$VideoReadFromJson(json);

  Map<String, dynamic> toJson() => _$VideoReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
