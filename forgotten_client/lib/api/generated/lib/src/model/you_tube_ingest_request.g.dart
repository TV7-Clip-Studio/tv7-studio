// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'you_tube_ingest_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YouTubeIngestRequestCWProxy {
  YouTubeIngestRequest appendClips(bool? appendClips);

  YouTubeIngestRequest youtubeUrl(String youtubeUrl);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YouTubeIngestRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YouTubeIngestRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  YouTubeIngestRequest call({
    bool? appendClips,
    String? youtubeUrl,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYouTubeIngestRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYouTubeIngestRequest.copyWith.fieldName(...)`
class _$YouTubeIngestRequestCWProxyImpl
    implements _$YouTubeIngestRequestCWProxy {
  const _$YouTubeIngestRequestCWProxyImpl(this._value);

  final YouTubeIngestRequest _value;

  @override
  YouTubeIngestRequest appendClips(bool? appendClips) =>
      this(appendClips: appendClips);

  @override
  YouTubeIngestRequest youtubeUrl(String youtubeUrl) =>
      this(youtubeUrl: youtubeUrl);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YouTubeIngestRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YouTubeIngestRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  YouTubeIngestRequest call({
    Object? appendClips = const $CopyWithPlaceholder(),
    Object? youtubeUrl = const $CopyWithPlaceholder(),
  }) {
    return YouTubeIngestRequest(
      appendClips: appendClips == const $CopyWithPlaceholder()
          ? _value.appendClips
          // ignore: cast_nullable_to_non_nullable
          : appendClips as bool?,
      youtubeUrl:
          youtubeUrl == const $CopyWithPlaceholder() || youtubeUrl == null
              ? _value.youtubeUrl
              // ignore: cast_nullable_to_non_nullable
              : youtubeUrl as String,
    );
  }
}

extension $YouTubeIngestRequestCopyWith on YouTubeIngestRequest {
  /// Returns a callable class that can be used as follows: `instanceOfYouTubeIngestRequest.copyWith(...)` or like so:`instanceOfYouTubeIngestRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YouTubeIngestRequestCWProxy get copyWith =>
      _$YouTubeIngestRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YouTubeIngestRequest _$YouTubeIngestRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'YouTubeIngestRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['youtube_url'],
        );
        final val = YouTubeIngestRequest(
          appendClips:
              $checkedConvert('append_clips', (v) => v as bool? ?? false),
          youtubeUrl: $checkedConvert('youtube_url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'appendClips': 'append_clips',
        'youtubeUrl': 'youtube_url'
      },
    );

Map<String, dynamic> _$YouTubeIngestRequestToJson(
    YouTubeIngestRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('append_clips', instance.appendClips);
  val['youtube_url'] = instance.youtubeUrl;
  return val;
}
