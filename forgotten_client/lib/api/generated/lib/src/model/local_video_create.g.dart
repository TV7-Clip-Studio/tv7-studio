// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_video_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalVideoCreateCWProxy {
  LocalVideoCreate sourceUrl(String sourceUrl);

  LocalVideoCreate localPath(String? localPath);

  LocalVideoCreate originalFilename(String? originalFilename);

  LocalVideoCreate uploadChecksum(String? uploadChecksum);

  LocalVideoCreate uploadFileSizeBytes(int? uploadFileSizeBytes);

  LocalVideoCreate durationSeconds(int? durationSeconds);

  LocalVideoCreate fileSizeBytes(int? fileSizeBytes);

  LocalVideoCreate transcriptText(String? transcriptText);

  LocalVideoCreate transcriptLanguage(String? transcriptLanguage);

  LocalVideoCreate workspaceRoot(String? workspaceRoot);

  LocalVideoCreate status(VideoStatus? status);

  LocalVideoCreate clipGenerationMode(ClipGenerationMode? clipGenerationMode);

  LocalVideoCreate clips(List<ClipUpsert>? clips);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LocalVideoCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LocalVideoCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  LocalVideoCreate call({
    String sourceUrl,
    String? localPath,
    String? originalFilename,
    String? uploadChecksum,
    int? uploadFileSizeBytes,
    int? durationSeconds,
    int? fileSizeBytes,
    String? transcriptText,
    String? transcriptLanguage,
    String? workspaceRoot,
    VideoStatus? status,
    ClipGenerationMode? clipGenerationMode,
    List<ClipUpsert>? clips,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLocalVideoCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLocalVideoCreate.copyWith.fieldName(...)`
class _$LocalVideoCreateCWProxyImpl implements _$LocalVideoCreateCWProxy {
  const _$LocalVideoCreateCWProxyImpl(this._value);

  final LocalVideoCreate _value;

  @override
  LocalVideoCreate sourceUrl(String sourceUrl) => this(sourceUrl: sourceUrl);

  @override
  LocalVideoCreate localPath(String? localPath) => this(localPath: localPath);

  @override
  LocalVideoCreate originalFilename(String? originalFilename) =>
      this(originalFilename: originalFilename);

  @override
  LocalVideoCreate uploadChecksum(String? uploadChecksum) =>
      this(uploadChecksum: uploadChecksum);

  @override
  LocalVideoCreate uploadFileSizeBytes(int? uploadFileSizeBytes) =>
      this(uploadFileSizeBytes: uploadFileSizeBytes);

  @override
  LocalVideoCreate durationSeconds(int? durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  LocalVideoCreate fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  LocalVideoCreate transcriptText(String? transcriptText) =>
      this(transcriptText: transcriptText);

  @override
  LocalVideoCreate transcriptLanguage(String? transcriptLanguage) =>
      this(transcriptLanguage: transcriptLanguage);

  @override
  LocalVideoCreate workspaceRoot(String? workspaceRoot) =>
      this(workspaceRoot: workspaceRoot);

  @override
  LocalVideoCreate status(VideoStatus? status) => this(status: status);

  @override
  LocalVideoCreate clipGenerationMode(ClipGenerationMode? clipGenerationMode) =>
      this(clipGenerationMode: clipGenerationMode);

  @override
  LocalVideoCreate clips(List<ClipUpsert>? clips) => this(clips: clips);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LocalVideoCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LocalVideoCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  LocalVideoCreate call({
    Object? sourceUrl = const $CopyWithPlaceholder(),
    Object? localPath = const $CopyWithPlaceholder(),
    Object? originalFilename = const $CopyWithPlaceholder(),
    Object? uploadChecksum = const $CopyWithPlaceholder(),
    Object? uploadFileSizeBytes = const $CopyWithPlaceholder(),
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? transcriptText = const $CopyWithPlaceholder(),
    Object? transcriptLanguage = const $CopyWithPlaceholder(),
    Object? workspaceRoot = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? clipGenerationMode = const $CopyWithPlaceholder(),
    Object? clips = const $CopyWithPlaceholder(),
  }) {
    return LocalVideoCreate(
      sourceUrl: sourceUrl == const $CopyWithPlaceholder()
          ? _value.sourceUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceUrl as String,
      localPath: localPath == const $CopyWithPlaceholder()
          ? _value.localPath
          // ignore: cast_nullable_to_non_nullable
          : localPath as String?,
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
      durationSeconds: durationSeconds == const $CopyWithPlaceholder()
          ? _value.durationSeconds
          // ignore: cast_nullable_to_non_nullable
          : durationSeconds as int?,
      fileSizeBytes: fileSizeBytes == const $CopyWithPlaceholder()
          ? _value.fileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : fileSizeBytes as int?,
      transcriptText: transcriptText == const $CopyWithPlaceholder()
          ? _value.transcriptText
          // ignore: cast_nullable_to_non_nullable
          : transcriptText as String?,
      transcriptLanguage: transcriptLanguage == const $CopyWithPlaceholder()
          ? _value.transcriptLanguage
          // ignore: cast_nullable_to_non_nullable
          : transcriptLanguage as String?,
      workspaceRoot: workspaceRoot == const $CopyWithPlaceholder()
          ? _value.workspaceRoot
          // ignore: cast_nullable_to_non_nullable
          : workspaceRoot as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as VideoStatus?,
      clipGenerationMode: clipGenerationMode == const $CopyWithPlaceholder()
          ? _value.clipGenerationMode
          // ignore: cast_nullable_to_non_nullable
          : clipGenerationMode as ClipGenerationMode?,
      clips: clips == const $CopyWithPlaceholder()
          ? _value.clips
          // ignore: cast_nullable_to_non_nullable
          : clips as List<ClipUpsert>?,
    );
  }
}

extension $LocalVideoCreateCopyWith on LocalVideoCreate {
  /// Returns a callable class that can be used as follows: `instanceOfLocalVideoCreate.copyWith(...)` or like so:`instanceOfLocalVideoCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalVideoCreateCWProxy get copyWith => _$LocalVideoCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalVideoCreate _$LocalVideoCreateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'LocalVideoCreate',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['source_url']);
    final val = LocalVideoCreate(
      sourceUrl: $checkedConvert('source_url', (v) => v as String),
      localPath: $checkedConvert('local_path', (v) => v as String?),
      originalFilename: $checkedConvert(
        'original_filename',
        (v) => v as String?,
      ),
      uploadChecksum: $checkedConvert('upload_checksum', (v) => v as String?),
      uploadFileSizeBytes: $checkedConvert(
        'upload_file_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      durationSeconds: $checkedConvert(
        'duration_seconds',
        (v) => (v as num?)?.toInt(),
      ),
      fileSizeBytes: $checkedConvert(
        'file_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      transcriptText: $checkedConvert('transcript_text', (v) => v as String?),
      transcriptLanguage: $checkedConvert(
        'transcript_language',
        (v) => v as String?,
      ),
      workspaceRoot: $checkedConvert('workspace_root', (v) => v as String?),
      status: $checkedConvert(
        'status',
        (v) =>
            $enumDecodeNullable(_$VideoStatusEnumMap, v) ?? VideoStatus.ready,
      ),
      clipGenerationMode: $checkedConvert(
        'clip_generation_mode',
        (v) =>
            $enumDecodeNullable(_$ClipGenerationModeEnumMap, v) ??
            ClipGenerationMode.replace,
      ),
      clips: $checkedConvert(
        'clips',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ClipUpsert.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'sourceUrl': 'source_url',
    'localPath': 'local_path',
    'originalFilename': 'original_filename',
    'uploadChecksum': 'upload_checksum',
    'uploadFileSizeBytes': 'upload_file_size_bytes',
    'durationSeconds': 'duration_seconds',
    'fileSizeBytes': 'file_size_bytes',
    'transcriptText': 'transcript_text',
    'transcriptLanguage': 'transcript_language',
    'workspaceRoot': 'workspace_root',
    'clipGenerationMode': 'clip_generation_mode',
  },
);

Map<String, dynamic> _$LocalVideoCreateToJson(LocalVideoCreate instance) =>
    <String, dynamic>{
      'source_url': instance.sourceUrl,
      'local_path': instance.localPath,
      'original_filename': instance.originalFilename,
      'upload_checksum': instance.uploadChecksum,
      'upload_file_size_bytes': instance.uploadFileSizeBytes,
      'duration_seconds': instance.durationSeconds,
      'file_size_bytes': instance.fileSizeBytes,
      'transcript_text': instance.transcriptText,
      'transcript_language': instance.transcriptLanguage,
      'workspace_root': instance.workspaceRoot,
      'status': _$VideoStatusEnumMap[instance.status],
      'clip_generation_mode':
          _$ClipGenerationModeEnumMap[instance.clipGenerationMode],
      'clips': instance.clips?.map((e) => e.toJson()).toList(),
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
