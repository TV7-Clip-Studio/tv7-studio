// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_ingest_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VideoIngestResponseCWProxy {
  VideoIngestResponse created(bool created);

  VideoIngestResponse queued(bool? queued);

  VideoIngestResponse video(VideoRead video);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoIngestResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoIngestResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoIngestResponse call({
    bool? created,
    bool? queued,
    VideoRead? video,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVideoIngestResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVideoIngestResponse.copyWith.fieldName(...)`
class _$VideoIngestResponseCWProxyImpl implements _$VideoIngestResponseCWProxy {
  const _$VideoIngestResponseCWProxyImpl(this._value);

  final VideoIngestResponse _value;

  @override
  VideoIngestResponse created(bool created) => this(created: created);

  @override
  VideoIngestResponse queued(bool? queued) => this(queued: queued);

  @override
  VideoIngestResponse video(VideoRead video) => this(video: video);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VideoIngestResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VideoIngestResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  VideoIngestResponse call({
    Object? created = const $CopyWithPlaceholder(),
    Object? queued = const $CopyWithPlaceholder(),
    Object? video = const $CopyWithPlaceholder(),
  }) {
    return VideoIngestResponse(
      created: created == const $CopyWithPlaceholder() || created == null
          ? _value.created
          // ignore: cast_nullable_to_non_nullable
          : created as bool,
      queued: queued == const $CopyWithPlaceholder()
          ? _value.queued
          // ignore: cast_nullable_to_non_nullable
          : queued as bool?,
      video: video == const $CopyWithPlaceholder() || video == null
          ? _value.video
          // ignore: cast_nullable_to_non_nullable
          : video as VideoRead,
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
    $checkedCreate(
      'VideoIngestResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['created', 'video'],
        );
        final val = VideoIngestResponse(
          created: $checkedConvert('created', (v) => v as bool),
          queued: $checkedConvert('queued', (v) => v as bool? ?? true),
          video: $checkedConvert(
              'video', (v) => VideoRead.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$VideoIngestResponseToJson(VideoIngestResponse instance) {
  final val = <String, dynamic>{
    'created': instance.created,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('queued', instance.queued);
  val['video'] = instance.video.toJson();
  return val;
}
