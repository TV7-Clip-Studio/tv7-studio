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

    required  this.id,

    required  this.sourceUrl,

    required  this.localPath,

    required  this.ingestType,

     this.originalFilename,

     this.uploadChecksum,

     this.uploadFileSizeBytes,

    required  this.transcriptText,

     this.transcriptLanguage,

     this.durationSeconds,

     this.fileSizeBytes,

     this.errorMessage,

     this.workspaceRoot,

    required  this.status,

    required  this.clipGenerationMode,

    required  this.createdAt,

    required  this.updatedAt,

     this.requestedByUserId,

     this.clips,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    
  )


  final int id;



  @JsonKey(
    
    name: r'source_url',
    required: true,
    
  )


  final String sourceUrl;



  @JsonKey(
    
    name: r'local_path',
    required: true,
    includeIfNull: true,
  )


  final String? localPath;



  @JsonKey(
    
    name: r'ingest_type',
    required: true,
    
  )


  final VideoIngestType ingestType;



  @JsonKey(
    
    name: r'original_filename',
    required: false,
    
  )


  final String? originalFilename;



  @JsonKey(
    
    name: r'upload_checksum',
    required: false,
    
  )


  final String? uploadChecksum;



  @JsonKey(
    
    name: r'upload_file_size_bytes',
    required: false,
    
  )


  final int? uploadFileSizeBytes;



  @JsonKey(
    
    name: r'transcript_text',
    required: true,
    includeIfNull: true,
  )


  final String? transcriptText;



  @JsonKey(
    
    name: r'transcript_language',
    required: false,
    
  )


  final String? transcriptLanguage;



  @JsonKey(
    
    name: r'duration_seconds',
    required: false,
    
  )


  final int? durationSeconds;



  @JsonKey(
    
    name: r'file_size_bytes',
    required: false,
    
  )


  final int? fileSizeBytes;



  @JsonKey(
    
    name: r'error_message',
    required: false,
    
  )


  final String? errorMessage;



  @JsonKey(
    
    name: r'workspace_root',
    required: false,
    
  )


  final String? workspaceRoot;



  @JsonKey(
    
    name: r'status',
    required: true,
    
  )


  final VideoStatus status;



  @JsonKey(
    
    name: r'clip_generation_mode',
    required: true,
    
  )


  final ClipGenerationMode clipGenerationMode;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    
  )


  final DateTime updatedAt;



  @JsonKey(
    
    name: r'requested_by_user_id',
    required: false,
    
  )


  final int? requestedByUserId;



  @JsonKey(
    
    name: r'clips',
    required: false,
    
  )


  final List<ClipRead>? clips;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VideoRead &&
      other.id == id &&
      other.sourceUrl == sourceUrl &&
      other.localPath == localPath &&
      other.ingestType == ingestType &&
      other.originalFilename == originalFilename &&
      other.uploadChecksum == uploadChecksum &&
      other.uploadFileSizeBytes == uploadFileSizeBytes &&
      other.transcriptText == transcriptText &&
      other.transcriptLanguage == transcriptLanguage &&
      other.durationSeconds == durationSeconds &&
      other.fileSizeBytes == fileSizeBytes &&
      other.errorMessage == errorMessage &&
      other.workspaceRoot == workspaceRoot &&
      other.status == status &&
      other.clipGenerationMode == clipGenerationMode &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.requestedByUserId == requestedByUserId &&
      other.clips == clips;

    @override
    int get hashCode =>
        id.hashCode +
        sourceUrl.hashCode +
        (localPath == null ? 0 : localPath.hashCode) +
        ingestType.hashCode +
        (originalFilename == null ? 0 : originalFilename.hashCode) +
        (uploadChecksum == null ? 0 : uploadChecksum.hashCode) +
        (uploadFileSizeBytes == null ? 0 : uploadFileSizeBytes.hashCode) +
        (transcriptText == null ? 0 : transcriptText.hashCode) +
        (transcriptLanguage == null ? 0 : transcriptLanguage.hashCode) +
        (durationSeconds == null ? 0 : durationSeconds.hashCode) +
        (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
        (errorMessage == null ? 0 : errorMessage.hashCode) +
        (workspaceRoot == null ? 0 : workspaceRoot.hashCode) +
        status.hashCode +
        clipGenerationMode.hashCode +
        createdAt.hashCode +
        updatedAt.hashCode +
        (requestedByUserId == null ? 0 : requestedByUserId.hashCode) +
        clips.hashCode;

  factory VideoRead.fromJson(Map<String, dynamic> json) => _$VideoReadFromJson(json);

  Map<String, dynamic> toJson() => _$VideoReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

