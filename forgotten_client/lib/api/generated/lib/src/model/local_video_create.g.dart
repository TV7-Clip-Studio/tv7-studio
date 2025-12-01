// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_video_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalVideoCreateCWProxy {
  LocalVideoCreate clipGenerationMode(ClipGenerationMode? clipGenerationMode);

  LocalVideoCreate clips(List<ClipUpsert>? clips);

  LocalVideoCreate durationSeconds(int? durationSeconds);

  LocalVideoCreate fileSizeBytes(int? fileSizeBytes);

  LocalVideoCreate localPath(String? localPath);

  LocalVideoCreate metadataOnly(bool? metadataOnly);

  LocalVideoCreate originalFilename(String? originalFilename);

  LocalVideoCreate sourceUrl(String sourceUrl);

  LocalVideoCreate status(VideoStatus? status);

  LocalVideoCreate title(String? title);

  LocalVideoCreate transcriptLanguage(String? transcriptLanguage);

  LocalVideoCreate transcriptText(String? transcriptText);

  LocalVideoCreate uploadChecksum(String? uploadChecksum);

  LocalVideoCreate uploadFileSizeBytes(int? uploadFileSizeBytes);

  LocalVideoCreate workspaceRoot(String? workspaceRoot);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LocalVideoCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LocalVideoCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  LocalVideoCreate call({
    ClipGenerationMode? clipGenerationMode,
    List<ClipUpsert>? clips,
    int? durationSeconds,
    int? fileSizeBytes,
    String? localPath,
    bool? metadataOnly,
    String? originalFilename,
    String? sourceUrl,
    VideoStatus? status,
    String? title,
    String? transcriptLanguage,
    String? transcriptText,
    String? uploadChecksum,
    int? uploadFileSizeBytes,
    String? workspaceRoot,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLocalVideoCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLocalVideoCreate.copyWith.fieldName(...)`
class _$LocalVideoCreateCWProxyImpl implements _$LocalVideoCreateCWProxy {
  const _$LocalVideoCreateCWProxyImpl(this._value);

  final LocalVideoCreate _value;

  @override
  LocalVideoCreate clipGenerationMode(ClipGenerationMode? clipGenerationMode) =>
      this(clipGenerationMode: clipGenerationMode);

  @override
  LocalVideoCreate clips(List<ClipUpsert>? clips) => this(clips: clips);

  @override
  LocalVideoCreate durationSeconds(int? durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  LocalVideoCreate fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  LocalVideoCreate localPath(String? localPath) => this(localPath: localPath);

  @override
  LocalVideoCreate metadataOnly(bool? metadataOnly) =>
      this(metadataOnly: metadataOnly);

  @override
  LocalVideoCreate originalFilename(String? originalFilename) =>
      this(originalFilename: originalFilename);

  @override
  LocalVideoCreate sourceUrl(String sourceUrl) => this(sourceUrl: sourceUrl);

  @override
  LocalVideoCreate status(VideoStatus? status) => this(status: status);

  @override
  LocalVideoCreate title(String? title) => this(title: title);

  @override
  LocalVideoCreate transcriptLanguage(String? transcriptLanguage) =>
      this(transcriptLanguage: transcriptLanguage);

  @override
  LocalVideoCreate transcriptText(String? transcriptText) =>
      this(transcriptText: transcriptText);

  @override
  LocalVideoCreate uploadChecksum(String? uploadChecksum) =>
      this(uploadChecksum: uploadChecksum);

  @override
  LocalVideoCreate uploadFileSizeBytes(int? uploadFileSizeBytes) =>
      this(uploadFileSizeBytes: uploadFileSizeBytes);

  @override
  LocalVideoCreate workspaceRoot(String? workspaceRoot) =>
      this(workspaceRoot: workspaceRoot);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LocalVideoCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LocalVideoCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  LocalVideoCreate call({
    Object? clipGenerationMode = const $CopyWithPlaceholder(),
    Object? clips = const $CopyWithPlaceholder(),
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? localPath = const $CopyWithPlaceholder(),
    Object? metadataOnly = const $CopyWithPlaceholder(),
    Object? originalFilename = const $CopyWithPlaceholder(),
    Object? sourceUrl = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? transcriptLanguage = const $CopyWithPlaceholder(),
    Object? transcriptText = const $CopyWithPlaceholder(),
    Object? uploadChecksum = const $CopyWithPlaceholder(),
    Object? uploadFileSizeBytes = const $CopyWithPlaceholder(),
    Object? workspaceRoot = const $CopyWithPlaceholder(),
  }) {
    return LocalVideoCreate(
      clipGenerationMode: clipGenerationMode == const $CopyWithPlaceholder()
          ? _value.clipGenerationMode
          // ignore: cast_nullable_to_non_nullable
          : clipGenerationMode as ClipGenerationMode?,
      clips: clips == const $CopyWithPlaceholder()
          ? _value.clips
          // ignore: cast_nullable_to_non_nullable
          : clips as List<ClipUpsert>?,
      durationSeconds: durationSeconds == const $CopyWithPlaceholder()
          ? _value.durationSeconds
          // ignore: cast_nullable_to_non_nullable
          : durationSeconds as int?,
      fileSizeBytes: fileSizeBytes == const $CopyWithPlaceholder()
          ? _value.fileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : fileSizeBytes as int?,
      localPath: localPath == const $CopyWithPlaceholder()
          ? _value.localPath
          // ignore: cast_nullable_to_non_nullable
          : localPath as String?,
      metadataOnly: metadataOnly == const $CopyWithPlaceholder()
          ? _value.metadataOnly
          // ignore: cast_nullable_to_non_nullable
          : metadataOnly as bool?,
      originalFilename: originalFilename == const $CopyWithPlaceholder()
          ? _value.originalFilename
          // ignore: cast_nullable_to_non_nullable
          : originalFilename as String?,
      sourceUrl: sourceUrl == const $CopyWithPlaceholder() || sourceUrl == null
          ? _value.sourceUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceUrl as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as VideoStatus?,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      transcriptLanguage: transcriptLanguage == const $CopyWithPlaceholder()
          ? _value.transcriptLanguage
          // ignore: cast_nullable_to_non_nullable
          : transcriptLanguage as String?,
      transcriptText: transcriptText == const $CopyWithPlaceholder()
          ? _value.transcriptText
          // ignore: cast_nullable_to_non_nullable
          : transcriptText as String?,
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

extension $LocalVideoCreateCopyWith on LocalVideoCreate {
  /// Returns a callable class that can be used as follows: `instanceOfLocalVideoCreate.copyWith(...)` or like so:`instanceOfLocalVideoCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalVideoCreateCWProxy get copyWith => _$LocalVideoCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalVideoCreate _$LocalVideoCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LocalVideoCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['source_url'],
        );
        final val = LocalVideoCreate(
          clipGenerationMode: $checkedConvert(
              'clip_generation_mode',
              (v) =>
                  $enumDecodeNullable(_$ClipGenerationModeEnumMap, v) ??
                  ClipGenerationMode.replace),
          clips: $checkedConvert(
              'clips',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ClipUpsert.fromJson(e as Map<String, dynamic>))
                  .toList()),
          durationSeconds:
              $checkedConvert('duration_seconds', (v) => (v as num?)?.toInt()),
          fileSizeBytes:
              $checkedConvert('file_size_bytes', (v) => (v as num?)?.toInt()),
          localPath: $checkedConvert('local_path', (v) => v as String?),
          metadataOnly:
              $checkedConvert('metadata_only', (v) => v as bool? ?? false),
          originalFilename:
              $checkedConvert('original_filename', (v) => v as String?),
          sourceUrl: $checkedConvert('source_url', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) =>
                  $enumDecodeNullable(_$VideoStatusEnumMap, v) ??
                  VideoStatus.ready),
          title: $checkedConvert('title', (v) => v as String?),
          transcriptLanguage:
              $checkedConvert('transcript_language', (v) => v as String?),
          transcriptText:
              $checkedConvert('transcript_text', (v) => v as String?),
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
        'durationSeconds': 'duration_seconds',
        'fileSizeBytes': 'file_size_bytes',
        'localPath': 'local_path',
        'metadataOnly': 'metadata_only',
        'originalFilename': 'original_filename',
        'sourceUrl': 'source_url',
        'transcriptLanguage': 'transcript_language',
        'transcriptText': 'transcript_text',
        'uploadChecksum': 'upload_checksum',
        'uploadFileSizeBytes': 'upload_file_size_bytes',
        'workspaceRoot': 'workspace_root'
      },
    );

Map<String, dynamic> _$LocalVideoCreateToJson(LocalVideoCreate instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('clip_generation_mode',
      _$ClipGenerationModeEnumMap[instance.clipGenerationMode]);
  writeNotNull('clips', instance.clips?.map((e) => e.toJson()).toList());
  writeNotNull('duration_seconds', instance.durationSeconds);
  writeNotNull('file_size_bytes', instance.fileSizeBytes);
  writeNotNull('local_path', instance.localPath);
  writeNotNull('metadata_only', instance.metadataOnly);
  writeNotNull('original_filename', instance.originalFilename);
  val['source_url'] = instance.sourceUrl;
  writeNotNull('status', _$VideoStatusEnumMap[instance.status]);
  writeNotNull('title', instance.title);
  writeNotNull('transcript_language', instance.transcriptLanguage);
  writeNotNull('transcript_text', instance.transcriptText);
  writeNotNull('upload_checksum', instance.uploadChecksum);
  writeNotNull('upload_file_size_bytes', instance.uploadFileSizeBytes);
  writeNotNull('workspace_root', instance.workspaceRoot);
  return val;
}

const _$ClipGenerationModeEnumMap = {
  ClipGenerationMode.replace: 'replace',
  ClipGenerationMode.append: 'append',
};

const _$VideoStatusEnumMap = {
  VideoStatus.ingested: 'ingested',
  VideoStatus.processing: 'processing',
  VideoStatus.ready: 'ready',
  VideoStatus.error: 'error',
};
