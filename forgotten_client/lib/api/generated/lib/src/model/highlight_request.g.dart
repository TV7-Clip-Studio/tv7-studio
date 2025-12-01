// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HighlightRequestCWProxy {
  HighlightRequest durationSeconds(int durationSeconds);

  HighlightRequest maxClips(int? maxClips);

  HighlightRequest prompt(String? prompt);

  HighlightRequest transcript(String transcript);

  HighlightRequest transcriptLanguage(String? transcriptLanguage);

  HighlightRequest videoId(int? videoId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HighlightRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HighlightRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  HighlightRequest call({
    int? durationSeconds,
    int? maxClips,
    String? prompt,
    String? transcript,
    String? transcriptLanguage,
    int? videoId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHighlightRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHighlightRequest.copyWith.fieldName(...)`
class _$HighlightRequestCWProxyImpl implements _$HighlightRequestCWProxy {
  const _$HighlightRequestCWProxyImpl(this._value);

  final HighlightRequest _value;

  @override
  HighlightRequest durationSeconds(int durationSeconds) =>
      this(durationSeconds: durationSeconds);

  @override
  HighlightRequest maxClips(int? maxClips) => this(maxClips: maxClips);

  @override
  HighlightRequest prompt(String? prompt) => this(prompt: prompt);

  @override
  HighlightRequest transcript(String transcript) =>
      this(transcript: transcript);

  @override
  HighlightRequest transcriptLanguage(String? transcriptLanguage) =>
      this(transcriptLanguage: transcriptLanguage);

  @override
  HighlightRequest videoId(int? videoId) => this(videoId: videoId);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HighlightRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HighlightRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  HighlightRequest call({
    Object? durationSeconds = const $CopyWithPlaceholder(),
    Object? maxClips = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
    Object? transcript = const $CopyWithPlaceholder(),
    Object? transcriptLanguage = const $CopyWithPlaceholder(),
    Object? videoId = const $CopyWithPlaceholder(),
  }) {
    return HighlightRequest(
      durationSeconds: durationSeconds == const $CopyWithPlaceholder() ||
              durationSeconds == null
          ? _value.durationSeconds
          // ignore: cast_nullable_to_non_nullable
          : durationSeconds as int,
      maxClips: maxClips == const $CopyWithPlaceholder()
          ? _value.maxClips
          // ignore: cast_nullable_to_non_nullable
          : maxClips as int?,
      prompt: prompt == const $CopyWithPlaceholder()
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String?,
      transcript:
          transcript == const $CopyWithPlaceholder() || transcript == null
              ? _value.transcript
              // ignore: cast_nullable_to_non_nullable
              : transcript as String,
      transcriptLanguage: transcriptLanguage == const $CopyWithPlaceholder()
          ? _value.transcriptLanguage
          // ignore: cast_nullable_to_non_nullable
          : transcriptLanguage as String?,
      videoId: videoId == const $CopyWithPlaceholder()
          ? _value.videoId
          // ignore: cast_nullable_to_non_nullable
          : videoId as int?,
    );
  }
}

extension $HighlightRequestCopyWith on HighlightRequest {
  /// Returns a callable class that can be used as follows: `instanceOfHighlightRequest.copyWith(...)` or like so:`instanceOfHighlightRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HighlightRequestCWProxy get copyWith => _$HighlightRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HighlightRequest _$HighlightRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HighlightRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['duration_seconds', 'transcript'],
        );
        final val = HighlightRequest(
          durationSeconds:
              $checkedConvert('duration_seconds', (v) => (v as num).toInt()),
          maxClips: $checkedConvert('max_clips', (v) => (v as num?)?.toInt()),
          prompt: $checkedConvert('prompt', (v) => v as String?),
          transcript: $checkedConvert('transcript', (v) => v as String),
          transcriptLanguage:
              $checkedConvert('transcript_language', (v) => v as String?),
          videoId:
              $checkedConvert('video_id', (v) => (v as num?)?.toInt() ?? 0),
        );
        return val;
      },
      fieldKeyMap: const {
        'durationSeconds': 'duration_seconds',
        'maxClips': 'max_clips',
        'transcriptLanguage': 'transcript_language',
        'videoId': 'video_id'
      },
    );

Map<String, dynamic> _$HighlightRequestToJson(HighlightRequest instance) {
  final val = <String, dynamic>{
    'duration_seconds': instance.durationSeconds,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('max_clips', instance.maxClips);
  writeNotNull('prompt', instance.prompt);
  val['transcript'] = instance.transcript;
  writeNotNull('transcript_language', instance.transcriptLanguage);
  writeNotNull('video_id', instance.videoId);
  return val;
}
