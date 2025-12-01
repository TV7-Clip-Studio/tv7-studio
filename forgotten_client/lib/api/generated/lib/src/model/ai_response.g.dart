// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AIResponseCWProxy {
  AIResponse meta(Map<String, Object>? meta);

  AIResponse output(String output);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  AIResponse call({
    Map<String, Object>? meta,
    String? output,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAIResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAIResponse.copyWith.fieldName(...)`
class _$AIResponseCWProxyImpl implements _$AIResponseCWProxy {
  const _$AIResponseCWProxyImpl(this._value);

  final AIResponse _value;

  @override
  AIResponse meta(Map<String, Object>? meta) => this(meta: meta);

  @override
  AIResponse output(String output) => this(output: output);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  AIResponse call({
    Object? meta = const $CopyWithPlaceholder(),
    Object? output = const $CopyWithPlaceholder(),
  }) {
    return AIResponse(
      meta: meta == const $CopyWithPlaceholder()
          ? _value.meta
          // ignore: cast_nullable_to_non_nullable
          : meta as Map<String, Object>?,
      output: output == const $CopyWithPlaceholder() || output == null
          ? _value.output
          // ignore: cast_nullable_to_non_nullable
          : output as String,
    );
  }
}

extension $AIResponseCopyWith on AIResponse {
  /// Returns a callable class that can be used as follows: `instanceOfAIResponse.copyWith(...)` or like so:`instanceOfAIResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AIResponseCWProxy get copyWith => _$AIResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIResponse _$AIResponseFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AIResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['output'],
        );
        final val = AIResponse(
          meta: $checkedConvert(
              'meta',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as Object),
                  )),
          output: $checkedConvert('output', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AIResponseToJson(AIResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('meta', instance.meta);
  val['output'] = instance.output;
  return val;
}
