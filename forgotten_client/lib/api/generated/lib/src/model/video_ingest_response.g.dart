// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_ingest_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VideoIngestResponseCWProxy {
  VideoIngestResponse video(VideoRead video);

  VideoIngestResponse queued(bool? queued);

  VideoIngestResponse created(bool created);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoIngestResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoIngestResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoIngestResponse call({VideoRead video, bool? queued, bool created});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVideoIngestResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVideoIngestResponse.copyWith.fieldName(...)`
class _$VideoIngestResponseCWProxyImpl implements _$VideoIngestResponseCWProxy {
  const _$VideoIngestResponseCWProxyImpl(this._value);

  final VideoIngestResponse _value;

  @override
  VideoIngestResponse video(VideoRead video) => this(video: video);

  @override
  VideoIngestResponse queued(bool? queued) => this(queued: queued);

  @override
  VideoIngestResponse created(bool created) => this(created: created);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoIngestResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoIngestResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoIngestResponse call({
    Object? video = const $CopyWithPlaceholder(),
    Object? queued = const $CopyWithPlaceholder(),
    Object? created = const $CopyWithPlaceholder(),
  }) {
    return VideoIngestResponse(
      video: video == const $CopyWithPlaceholder()
          ? _value.video
          // ignore: cast_nullable_to_non_nullable
          : video as VideoRead,
      queued: queued == const $CopyWithPlaceholder()
          ? _value.queued
          // ignore: cast_nullable_to_non_nullable
          : queued as bool?,
      created: created == const $CopyWithPlaceholder()
          ? _value.created
          // ignore: cast_nullable_to_non_nullable
          : created as bool,
    );
  }
}

extension $VideoIngestResponseCopyWith on VideoIngestResponse {
  /// Returns a callable class that can be used as follows: `instanceOfVideoIngestResponse.copyWith(...)` or like so:`instanceOfVideoIngestResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VideoIngestResponseCWProxy get copyWith =>
      _$VideoIngestResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoIngestResponse _$VideoIngestResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VideoIngestResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['video', 'created']);
      final val = VideoIngestResponse(
        video: $checkedConvert(
          'video',
          (v) => VideoRead.fromJson(v as Map<String, dynamic>),
        ),
        queued: $checkedConvert('queued', (v) => v as bool? ?? true),
        created: $checkedConvert('created', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$VideoIngestResponseToJson(
  VideoIngestResponse instance,
) => <String, dynamic>{
  'video': instance.video.toJson(),
  'queued': instance.queued,
  'created': instance.created,
};
