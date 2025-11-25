// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'you_tube_ingest_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YouTubeIngestRequestCWProxy {
  YouTubeIngestRequest youtubeUrl(String youtubeUrl);

  YouTubeIngestRequest appendClips(bool? appendClips);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YouTubeIngestRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YouTubeIngestRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  YouTubeIngestRequest call({String youtubeUrl, bool? appendClips});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYouTubeIngestRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYouTubeIngestRequest.copyWith.fieldName(...)`
class _$YouTubeIngestRequestCWProxyImpl
    implements _$YouTubeIngestRequestCWProxy {
  const _$YouTubeIngestRequestCWProxyImpl(this._value);

  final YouTubeIngestRequest _value;

  @override
  YouTubeIngestRequest youtubeUrl(String youtubeUrl) =>
      this(youtubeUrl: youtubeUrl);

  @override
  YouTubeIngestRequest appendClips(bool? appendClips) =>
      this(appendClips: appendClips);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YouTubeIngestRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YouTubeIngestRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  YouTubeIngestRequest call({
    Object? youtubeUrl = const $CopyWithPlaceholder(),
    Object? appendClips = const $CopyWithPlaceholder(),
  }) {
    return YouTubeIngestRequest(
      youtubeUrl: youtubeUrl == const $CopyWithPlaceholder()
          ? _value.youtubeUrl
          // ignore: cast_nullable_to_non_nullable
          : youtubeUrl as String,
      appendClips: appendClips == const $CopyWithPlaceholder()
          ? _value.appendClips
          // ignore: cast_nullable_to_non_nullable
          : appendClips as bool?,
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
  Map<String, dynamic> json,
) => $checkedCreate(
  'YouTubeIngestRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['youtube_url']);
    final val = YouTubeIngestRequest(
      youtubeUrl: $checkedConvert('youtube_url', (v) => v as String),
      appendClips: $checkedConvert('append_clips', (v) => v as bool? ?? false),
    );
    return val;
  },
  fieldKeyMap: const {
    'youtubeUrl': 'youtube_url',
    'appendClips': 'append_clips',
  },
);

Map<String, dynamic> _$YouTubeIngestRequestToJson(
  YouTubeIngestRequest instance,
) => <String, dynamic>{
  'youtube_url': instance.youtubeUrl,
  'append_clips': instance.appendClips,
};
