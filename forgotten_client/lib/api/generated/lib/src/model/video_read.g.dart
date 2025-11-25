// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VideoReadCWProxy {
  VideoRead id(int id);

  VideoRead sourceUrl(String sourceUrl);

  VideoRead localPath(String? localPath);

  VideoRead ingestType(VideoIngestType ingestType);

  VideoRead originalFilename(String? originalFilename);

  VideoRead uploadChecksum(String? uploadChecksum);

  VideoRead uploadFileSizeBytes(int? uploadFileSizeBytes);

  VideoRead transcriptText(String? transcriptText);

  VideoRead transcriptLanguage(String? transcriptLanguage);

  VideoRead durationSeconds(int? durationSeconds);

  VideoRead fileSizeBytes(int? fileSizeBytes);

  VideoRead errorMessage(String? errorMessage);

  VideoRead workspaceRoot(String? workspaceRoot);

  VideoRead status(VideoStatus status);

  VideoRead clipGenerationMode(ClipGenerationMode clipGenerationMode);

  VideoRead createdAt(DateTime createdAt);

  VideoRead updatedAt(DateTime updatedAt);

  VideoRead requestedByUserId(int? requestedByUserId);

  VideoRead clips(List<ClipRead>? clips);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoRead(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoRead call({
    int id,
    String sourceUrl,
    String? localPath,
    VideoIngestType ingestType,
    String? originalFilename,
    String? uploadChecksum,
    int? uploadFileSizeBytes,
    String? transcriptText,
    String? transcriptLanguage,
    int? durationSeconds,
    int? fileSizeBytes,
    String? errorMessage,
    String? workspaceRoot,
    VideoStatus status,
    ClipGenerationMode clipGenerationMode,
    DateTime createdAt,
    DateTime updatedAt,
    int? requestedByUserId,
    List<ClipRead>? clips,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVideoRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVideoRead.copyWith.fieldName(...)`
class _$VideoReadCWProxyImpl implements _$VideoReadCWProxy {
  const _$VideoReadCWProxyImpl(this._value);

  final VideoRead _value;

  @override
  VideoRead id(int id) => this(id: id);

  @override
  VideoRead sourceUrl(String sourceUrl) => this(sourceUrl: sourceUrl);

  @override
  VideoRead localPath(String? localPath) => this(localPath: localPath);

  @override
  VideoRead ingestType(VideoIngestType ingestType) =>
      this(ingestType: ingestType);

  @override
  VideoRead originalFilename(String? originalFilename) =>
      this(originalFilename: originalFilename);

  @override
  VideoRead uploadChecksum(String? uploadChecksum) =>
      this(uploadChecksum: uploadChecksum);

  @override
  VideoRead uploadFileSizeBytes(int? uploadFileSizeBytes) =>
      this(uploadFileSizeBytes: uploadFileSizeBytes);

  @override
  VideoRead transcriptText(String? transcriptText) =>
      this(transcriptText: transcriptText);

  @override
  VideoRead transcriptLanguage(String? transcriptLanguage) =>
      this(transcriptLanguage: transcriptLanguage);

  @override
  VideoRead durationSeconds(int? durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  VideoRead fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  VideoRead errorMessage(String? errorMessage) =>
      this(errorMessage: errorMessage);

  @override
  VideoRead workspaceRoot(String? workspaceRoot) =>
      this(workspaceRoot: workspaceRoot);

  @override
  VideoRead status(VideoStatus status) => this(status: status);

  @override
  VideoRead clipGenerationMode(ClipGenerationMode clipGenerationMode) =>
      this(clipGenerationMode: clipGenerationMode);

  @override
  VideoRead createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  VideoRead updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  VideoRead requestedByUserId(int? requestedByUserId) =>
      this(requestedByUserId: requestedByUserId);

  @override
  VideoRead clips(List<ClipRead>? clips) => this(clips: clips);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoRead(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoRead call({
    Object? id = const $CopyWithPlaceholder(),
    Object? sourceUrl = const $CopyWithPlaceholder(),
    Object? localPath = const $CopyWithPlaceholder(),
    Object? ingestType = const $CopyWithPlaceholder(),
    Object? originalFilename = const $CopyWithPlaceholder(),
    Object? uploadChecksum = const $CopyWithPlaceholder(),
    Object? uploadFileSizeBytes = const $CopyWithPlaceholder(),
    Object? transcriptText = const $CopyWithPlaceholder(),
    Object? transcriptLanguage = const $CopyWithPlaceholder(),
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? errorMessage = const $CopyWithPlaceholder(),
    Object? workspaceRoot = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? clipGenerationMode = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? requestedByUserId = const $CopyWithPlaceholder(),
    Object? clips = const $CopyWithPlaceholder(),
  }) {
    return VideoRead(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      sourceUrl: sourceUrl == const $CopyWithPlaceholder()
          ? _value.sourceUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceUrl as String,
      localPath: localPath == const $CopyWithPlaceholder()
          ? _value.localPath
          // ignore: cast_nullable_to_non_nullable
          : localPath as String?,
      ingestType: ingestType == const $CopyWithPlaceholder()
          ? _value.ingestType
          // ignore: cast_nullable_to_non_nullable
          : ingestType as VideoIngestType,
      originalFilename: originalFilename == const $CopyWithPlaceholder()
          ? _value.originalFilename
          // ignore: cast_nullable_to_non_nullable
          : originalFilename as String?,
      uploadChecksum: uploadChecksum == const $CopyWithPlaceholder()
          ? _value.uploadChecksum
          // ignore: cast_nullable_to_non_nullable
          : uploadChecksum as String?,
      uploadFileSizeBytes: uploadFileSizeBytes == const $CopyWithPlaceholder()
          ? _value.uploadFileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : uploadFileSizeBytes as int?,
      transcriptText: transcriptText == const $CopyWithPlaceholder()
          ? _value.transcriptText
          // ignore: cast_nullable_to_non_nullable
          : transcriptText as String?,
      transcriptLanguage: transcriptLanguage == const $CopyWithPlaceholder()
          ? _value.transcriptLanguage
          // ignore: cast_nullable_to_non_nullable
          : transcriptLanguage as String?,
      durationSeconds: durationSeconds == const $CopyWithPlaceholder()
          ? _value.durationSeconds
          // ignore: cast_nullable_to_non_nullable
          : durationSeconds as int?,
      fileSizeBytes: fileSizeBytes == const $CopyWithPlaceholder()
          ? _value.fileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : fileSizeBytes as int?,
      errorMessage: errorMessage == const $CopyWithPlaceholder()
          ? _value.errorMessage
          // ignore: cast_nullable_to_non_nullable
          : errorMessage as String?,
      workspaceRoot: workspaceRoot == const $CopyWithPlaceholder()
          ? _value.workspaceRoot
          // ignore: cast_nullable_to_non_nullable
          : workspaceRoot as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as VideoStatus,
      clipGenerationMode: clipGenerationMode == const $CopyWithPlaceholder()
          ? _value.clipGenerationMode
          // ignore: cast_nullable_to_non_nullable
          : clipGenerationMode as ClipGenerationMode,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      requestedByUserId: requestedByUserId == const $CopyWithPlaceholder()
          ? _value.requestedByUserId
          // ignore: cast_nullable_to_non_nullable
          : requestedByUserId as int?,
      clips: clips == const $CopyWithPlaceholder()
          ? _value.clips
          // ignore: cast_nullable_to_non_nullable
          : clips as List<ClipRead>?,
    );
  }
}

extension $VideoReadCopyWith on VideoRead {
  /// Returns a callable class that can be used as follows: `instanceOfVideoRead.copyWith(...)` or like so:`instanceOfVideoRead.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VideoReadCWProxy get copyWith => _$VideoReadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoRead _$VideoReadFromJson(Map<String, dynamic> json) => $checkedCreate(
  'VideoRead',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'source_url',
        'local_path',
        'ingest_type',
        'transcript_text',
        'status',
        'clip_generation_mode',
        'created_at',
        'updated_at',
      ],
    );
    final val = VideoRead(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      sourceUrl: $checkedConvert('source_url', (v) => v as String),
      localPath: $checkedConvert('local_path', (v) => v as String?),
      ingestType: $checkedConvert(
        'ingest_type',
        (v) => $enumDecode(_$VideoIngestTypeEnumMap, v),
      ),
      originalFilename: $checkedConvert(
        'original_filename',
        (v) => v as String?,
      ),
      uploadChecksum: $checkedConvert('upload_checksum', (v) => v as String?),
      uploadFileSizeBytes: $checkedConvert(
        'upload_file_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      transcriptText: $checkedConvert('transcript_text', (v) => v as String?),
      transcriptLanguage: $checkedConvert(
        'transcript_language',
        (v) => v as String?,
      ),
      durationSeconds: $checkedConvert(
        'duration_seconds',
        (v) => (v as num?)?.toInt(),
      ),
      fileSizeBytes: $checkedConvert(
        'file_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      errorMessage: $checkedConvert('error_message', (v) => v as String?),
      workspaceRoot: $checkedConvert('workspace_root', (v) => v as String?),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$VideoStatusEnumMap, v),
      ),
      clipGenerationMode: $checkedConvert(
        'clip_generation_mode',
        (v) => $enumDecode(_$ClipGenerationModeEnumMap, v),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
      requestedByUserId: $checkedConvert(
        'requested_by_user_id',
        (v) => (v as num?)?.toInt(),
      ),
      clips: $checkedConvert(
        'clips',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ClipRead.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'sourceUrl': 'source_url',
    'localPath': 'local_path',
    'ingestType': 'ingest_type',
    'originalFilename': 'original_filename',
    'uploadChecksum': 'upload_checksum',
    'uploadFileSizeBytes': 'upload_file_size_bytes',
    'transcriptText': 'transcript_text',
    'transcriptLanguage': 'transcript_language',
    'durationSeconds': 'duration_seconds',
    'fileSizeBytes': 'file_size_bytes',
    'errorMessage': 'error_message',
    'workspaceRoot': 'workspace_root',
    'clipGenerationMode': 'clip_generation_mode',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
    'requestedByUserId': 'requested_by_user_id',
  },
);

Map<String, dynamic> _$VideoReadToJson(VideoRead instance) => <String, dynamic>{
  'id': instance.id,
  'source_url': instance.sourceUrl,
  'local_path': instance.localPath,
  'ingest_type': _$VideoIngestTypeEnumMap[instance.ingestType]!,
  'original_filename': instance.originalFilename,
  'upload_checksum': instance.uploadChecksum,
  'upload_file_size_bytes': instance.uploadFileSizeBytes,
  'transcript_text': instance.transcriptText,
  'transcript_language': instance.transcriptLanguage,
  'duration_seconds': instance.durationSeconds,
  'file_size_bytes': instance.fileSizeBytes,
  'error_message': instance.errorMessage,
  'workspace_root': instance.workspaceRoot,
  'status': _$VideoStatusEnumMap[instance.status]!,
  'clip_generation_mode':
      _$ClipGenerationModeEnumMap[instance.clipGenerationMode]!,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'requested_by_user_id': instance.requestedByUserId,
  'clips': instance.clips?.map((e) => e.toJson()).toList(),
};

const _$VideoIngestTypeEnumMap = {
  VideoIngestType.youtube: 'youtube',
  VideoIngestType.upload: 'upload',
};

const _$VideoStatusEnumMap = {
  VideoStatus.ingested: 'ingested',
  VideoStatus.processing: 'processing',
  VideoStatus.ready: 'ready',
  VideoStatus.error: 'error',
};

const _$ClipGenerationModeEnumMap = {
  ClipGenerationMode.replace: 'replace',
  ClipGenerationMode.append: 'append',
};
