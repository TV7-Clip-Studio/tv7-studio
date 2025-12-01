// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggested_clip.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuggestedClipCWProxy {
  SuggestedClip description(String description);

  SuggestedClip endSec(int endSec);

  SuggestedClip hook(String hook);

  SuggestedClip startSec(int startSec);

  SuggestedClip title(String title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SuggestedClip(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SuggestedClip(...).copyWith(id: 12, name: "My name")
  /// ````
  SuggestedClip call({
    String? description,
    int? endSec,
    String? hook,
    int? startSec,
    String? title,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSuggestedClip.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSuggestedClip.copyWith.fieldName(...)`
class _$SuggestedClipCWProxyImpl implements _$SuggestedClipCWProxy {
  const _$SuggestedClipCWProxyImpl(this._value);

  final SuggestedClip _value;

  @override
  SuggestedClip description(String description) =>
      this(description: description);

  @override
  SuggestedClip endSec(int endSec) => this(endSec: endSec);

  @override
  SuggestedClip hook(String hook) => this(hook: hook);

  @override
  SuggestedClip startSec(int startSec) => this(startSec: startSec);

  @override
  SuggestedClip title(String title) => this(title: title);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SuggestedClip(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SuggestedClip(...).copyWith(id: 12, name: "My name")
  /// ````
  SuggestedClip call({
    Object? description = const $CopyWithPlaceholder(),
    Object? endSec = const $CopyWithPlaceholder(),
    Object? hook = const $CopyWithPlaceholder(),
    Object? startSec = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return SuggestedClip(
      description:
          description == const $CopyWithPlaceholder() || description == null
              ? _value.description
              // ignore: cast_nullable_to_non_nullable
              : description as String,
      endSec: endSec == const $CopyWithPlaceholder() || endSec == null
          ? _value.endSec
          // ignore: cast_nullable_to_non_nullable
          : endSec as int,
      hook: hook == const $CopyWithPlaceholder() || hook == null
          ? _value.hook
          // ignore: cast_nullable_to_non_nullable
          : hook as String,
      startSec: startSec == const $CopyWithPlaceholder() || startSec == null
          ? _value.startSec
          // ignore: cast_nullable_to_non_nullable
          : startSec as int,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $SuggestedClipCopyWith on SuggestedClip {
  /// Returns a callable class that can be used as follows: `instanceOfSuggestedClip.copyWith(...)` or like so:`instanceOfSuggestedClip.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuggestedClipCWProxy get copyWith => _$SuggestedClipCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestedClip _$SuggestedClipFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SuggestedClip',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'description',
            'end_sec',
            'hook',
            'start_sec',
            'title'
          ],
        );
        final val = SuggestedClip(
          description: $checkedConvert('description', (v) => v as String),
          endSec: $checkedConvert('end_sec', (v) => (v as num).toInt()),
          hook: $checkedConvert('hook', (v) => v as String),
          startSec: $checkedConvert('start_sec', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'endSec': 'end_sec', 'startSec': 'start_sec'},
    );

Map<String, dynamic> _$SuggestedClipToJson(SuggestedClip instance) =>
    <String, dynamic>{
      'description': instance.description,
      'end_sec': instance.endSec,
      'hook': instance.hook,
      'start_sec': instance.startSec,
      'title': instance.title,
    };
