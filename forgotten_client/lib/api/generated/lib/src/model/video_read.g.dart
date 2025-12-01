// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VideoReadCWProxy {
  VideoRead clipGenerationMode(ClipGenerationMode clipGenerationMode);

  VideoRead clips(List<ClipRead>? clips);

  VideoRead createdAt(DateTime createdAt);

  VideoRead durationSeconds(int? durationSeconds);

  VideoRead errorMessage(String? errorMessage);

  VideoRead fileSizeBytes(int? fileSizeBytes);

  VideoRead id(int id);

  VideoRead ingestType(VideoIngestType ingestType);

  VideoRead localPath(String? localPath);

  VideoRead originalFilename(String? originalFilename);

  VideoRead requestedByUserId(int? requestedByUserId);

  VideoRead sourceUrl(String sourceUrl);

  VideoRead status(VideoStatus status);

  VideoRead transcriptLanguage(String? transcriptLanguage);

  VideoRead transcriptText(String? transcriptText);

  VideoRead updatedAt(DateTime updatedAt);

  VideoRead uploadChecksum(String? uploadChecksum);

  VideoRead uploadFileSizeBytes(int? uploadFileSizeBytes);

  VideoRead workspaceRoot(String? workspaceRoot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoRead(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoRead call({
    ClipGenerationMode? clipGenerationMode,
    List<ClipRead>? clips,
    DateTime? createdAt,
    int? durationSeconds,
    String? errorMessage,
    int? fileSizeBytes,
    int? id,
    VideoIngestType? ingestType,
    String? localPath,
    String? originalFilename,
    int? requestedByUserId,
    String? sourceUrl,
    VideoStatus? status,
    String? transcriptLanguage,
    String? transcriptText,
    DateTime? updatedAt,
    String? uploadChecksum,
    int? uploadFileSizeBytes,
    String? workspaceRoot,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVideoRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVideoRead.copyWith.fieldName(...)`
class _$VideoReadCWProxyImpl implements _$VideoReadCWProxy {
  const _$VideoReadCWProxyImpl(this._value);

  final VideoRead _value;

  @override
  VideoRead clipGenerationMode(ClipGenerationMode clipGenerationMode) =>
      this(clipGenerationMode: clipGenerationMode);

  @override
  VideoRead clips(List<ClipRead>? clips) => this(clips: clips);

  @override
  VideoRead createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  VideoRead durationSeconds(int? durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  VideoRead errorMessage(String? errorMessage) =>
      this(errorMessage: errorMessage);

  @override
  VideoRead fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  VideoRead id(int id) => this(id: id);

  @override
  VideoRead ingestType(VideoIngestType ingestType) =>
      this(ingestType: ingestType);

  @override
  VideoRead localPath(String? localPath) => this(localPath: localPath);

  @override
  VideoRead originalFilename(String? originalFilename) =>
      this(originalFilename: originalFilename);

  @override
  VideoRead requestedByUserId(int? requestedByUserId) =>
      this(requestedByUserId: requestedByUserId);

  @override
  VideoRead sourceUrl(String sourceUrl) => this(sourceUrl: sourceUrl);

  @override
  VideoRead status(VideoStatus status) => this(status: status);

  @override
  VideoRead transcriptLanguage(String? transcriptLanguage) =>
      this(transcriptLanguage: transcriptLanguage);

  @override
  VideoRead transcriptText(String? transcriptText) =>
      this(transcriptText: transcriptText);

  @override
  VideoRead updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  VideoRead uploadChecksum(String? uploadChecksum) =>
      this(uploadChecksum: uploadChecksum);

  @override
  VideoRead uploadFileSizeBytes(int? uploadFileSizeBytes) =>
      this(uploadFileSizeBytes: uploadFileSizeBytes);

  @override
  VideoRead workspaceRoot(String? workspaceRoot) =>
      this(workspaceRoot: workspaceRoot);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoRead(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoRead call({
    Object? clipGenerationMode = const $CopyWithPlaceholder(),
    Object? clips = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? errorMessage = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? ingestType = const $CopyWithPlaceholder(),
    Object? localPath = const $CopyWithPlaceholder(),
    Object? originalFilename = const $CopyWithPlaceholder(),
    Object? requestedByUserId = const $CopyWithPlaceholder(),
    Object? sourceUrl = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? transcriptLanguage = const $CopyWithPlaceholder(),
    Object? transcriptText = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? uploadChecksum = const $CopyWithPlaceholder(),
    Object? uploadFileSizeBytes = const $CopyWithPlaceholder(),
    Object? workspaceRoot = const $CopyWithPlaceholder(),
  }) {
    return VideoRead(
      clipGenerationMode: clipGenerationMode == const $CopyWithPlaceholder() ||
              clipGenerationMode == null
          ? _value.clipGenerationMode
          // ignore: cast_nullable_to_non_nullable
          : clipGenerationMode as ClipGenerationMode,
      clips: clips == const $CopyWithPlaceholder()
          ? _value.clips
          // ignore: cast_nullable_to_non_nullable
          : clips as List<ClipRead>?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      durationSeconds: durationSeconds == const $CopyWithPlaceholder()
          ? _value.durationSeconds
          // ignore: cast_nullable_to_non_nullable
          : durationSeconds as int?,
      errorMessage: errorMessage == const $CopyWithPlaceholder()
          ? _value.errorMessage
          // ignore: cast_nullable_to_non_nullable
          : errorMessage as String?,
      fileSizeBytes: fileSizeBytes == const $CopyWithPlaceholder()
          ? _value.fileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : fileSizeBytes as int?,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      ingestType:
          ingestType == const $CopyWithPlaceholder() || ingestType == null
              ? _value.ingestType
              // ignore: cast_nullable_to_non_nullable
              : ingestType as VideoIngestType,
      localPath: localPath == const $CopyWithPlaceholder()
          ? _value.localPath
          // ignore: cast_nullable_to_non_nullable
          : localPath as String?,
      originalFilename: originalFilename == const $CopyWithPlaceholder()
          ? _value.originalFilename
          // ignore: cast_nullable_to_non_nullable
          : originalFilename as String?,
      requestedByUserId: requestedByUserId == const $CopyWithPlaceholder()
          ? _value.requestedByUserId
          // ignore: cast_nullable_to_non_nullable
          : requestedByUserId as int?,
      sourceUrl: sourceUrl == const $CopyWithPlaceholder() || sourceUrl == null
          ? _value.sourceUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceUrl as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as VideoStatus,
      transcriptLanguage: transcriptLanguage == const $CopyWithPlaceholder()
          ? _value.transcriptLanguage
          // ignore: cast_nullable_to_non_nullable
          : transcriptLanguage as String?,
      transcriptText: transcriptText == const $CopyWithPlaceholder()
          ? _value.transcriptText
          // ignore: cast_nullable_to_non_nullable
          : transcriptText as String?,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      uploadChecksum: uploadChecksum == const $CopyWithPlaceholder()
          ? _value.uploadChecksum
          // ignore: cast_nullable_to_non_nullable
          : uploadChecksum as String?,
      uploadFileSizeBytes: uploadFileSizeBytes == const $CopyWithPlaceholder()
          ? _value.uploadFileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : uploadFileSizeBytes as int?,
      workspaceRoot: workspaceRoot == const $CopyWithPlaceholder()
          ? _value.workspaceRoot
          // ignore: cast_nullable_to_non_nullable
          : workspaceRoot as String?,
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
            'clip_generation_mode',
            'created_at',
            'id',
            'ingest_type',
            'local_path',
            'source_url',
            'status',
            'transcript_text',
            'updated_at'
          ],
        );
        final val = VideoRead(
          clipGenerationMode: $checkedConvert('clip_generation_mode',
              (v) => $enumDecode(_$ClipGenerationModeEnumMap, v)),
          clips: $checkedConvert(
              'clips',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ClipRead.fromJson(e as Map<String, dynamic>))
                  .toList()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          durationSeconds:
              $checkedConvert('duration_seconds', (v) => (v as num?)?.toInt()),
          errorMessage: $checkedConvert('error_message', (v) => v as String?),
          fileSizeBytes:
              $checkedConvert('file_size_bytes', (v) => (v as num?)?.toInt()),
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          ingestType: $checkedConvert(
              'ingest_type', (v) => $enumDecode(_$VideoIngestTypeEnumMap, v)),
          localPath: $checkedConvert('local_path', (v) => v as String?),
          originalFilename:
              $checkedConvert('original_filename', (v) => v as String?),
          requestedByUserId: $checkedConvert(
              'requested_by_user_id', (v) => (v as num?)?.toInt()),
          sourceUrl: $checkedConvert('source_url', (v) => v as String),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$VideoStatusEnumMap, v)),
          transcriptLanguage:
              $checkedConvert('transcript_language', (v) => v as String?),
          transcriptText:
              $checkedConvert('transcript_text', (v) => v as String?),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          uploadChecksum:
              $checkedConvert('upload_checksum', (v) => v as String?),
          uploadFileSizeBytes: $checkedConvert(
              'upload_file_size_bytes', (v) => (v as num?)?.toInt()),
          workspaceRoot: $checkedConvert('workspace_root', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'clipGenerationMode': 'clip_generation_mode',
        'createdAt': 'created_at',
        'durationSeconds': 'duration_seconds',
        'errorMessage': 'error_message',
        'fileSizeBytes': 'file_size_bytes',
        'ingestType': 'ingest_type',
        'localPath': 'local_path',
        'originalFilename': 'original_filename',
        'requestedByUserId': 'requested_by_user_id',
        'sourceUrl': 'source_url',
        'transcriptLanguage': 'transcript_language',
        'transcriptText': 'transcript_text',
        'updatedAt': 'updated_at',
        'uploadChecksum': 'upload_checksum',
        'uploadFileSizeBytes': 'upload_file_size_bytes',
        'workspaceRoot': 'workspace_root'
      },
    );

Map<String, dynamic> _$VideoReadToJson(VideoRead instance) {
  final val = <String, dynamic>{
    'clip_generation_mode':
        _$ClipGenerationModeEnumMap[instance.clipGenerationMode]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('clips', instance.clips?.map((e) => e.toJson()).toList());
  val['created_at'] = instance.createdAt.toIso8601String();
  writeNotNull('duration_seconds', instance.durationSeconds);
  writeNotNull('error_message', instance.errorMessage);
  writeNotNull('file_size_bytes', instance.fileSizeBytes);
  val['id'] = instance.id;
  val['ingest_type'] = _$VideoIngestTypeEnumMap[instance.ingestType]!;
  val['local_path'] = instance.localPath;
  writeNotNull('original_filename', instance.originalFilename);
  writeNotNull('requested_by_user_id', instance.requestedByUserId);
  val['source_url'] = instance.sourceUrl;
  val['status'] = _$VideoStatusEnumMap[instance.status]!;
  writeNotNull('transcript_language', instance.transcriptLanguage);
  val['transcript_text'] = instance.transcriptText;
  val['updated_at'] = instance.updatedAt.toIso8601String();
  writeNotNull('upload_checksum', instance.uploadChecksum);
  writeNotNull('upload_file_size_bytes', instance.uploadFileSizeBytes);
  writeNotNull('workspace_root', instance.workspaceRoot);
  return val;
}

const _$ClipGenerationModeEnumMap = {
  ClipGenerationMode.replace: 'replace',
  ClipGenerationMode.append: 'append',
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
