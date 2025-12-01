// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HighlightResponseCWProxy {
  HighlightResponse clips(List<SuggestedClip> clips);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HighlightResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HighlightResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  HighlightResponse call({
    List<SuggestedClip>? clips,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHighlightResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHighlightResponse.copyWith.fieldName(...)`
class _$HighlightResponseCWProxyImpl implements _$HighlightResponseCWProxy {
  const _$HighlightResponseCWProxyImpl(this._value);

  final HighlightResponse _value;

  @override
  HighlightResponse clips(List<SuggestedClip> clips) => this(clips: clips);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HighlightResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HighlightResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  HighlightResponse call({
    Object? clips = const $CopyWithPlaceholder(),
  }) {
    return HighlightResponse(
      clips: clips == const $CopyWithPlaceholder() || clips == null
          ? _value.clips
          // ignore: cast_nullable_to_non_nullable
          : clips as List<SuggestedClip>,
    );
  }
}

extension $HighlightResponseCopyWith on HighlightResponse {
  /// Returns a callable class that can be used as follows: `instanceOfHighlightResponse.copyWith(...)` or like so:`instanceOfHighlightResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HighlightResponseCWProxy get copyWith =>
      _$HighlightResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HighlightResponse _$HighlightResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HighlightResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['clips'],
        );
        final val = HighlightResponse(
          clips: $checkedConvert(
              'clips',
              (v) => (v as List<dynamic>)
                  .map((e) => SuggestedClip.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$HighlightResponseToJson(HighlightResponse instance) =>
    <String, dynamic>{
      'clips': instance.clips.map((e) => e.toJson()).toList(),
    };
