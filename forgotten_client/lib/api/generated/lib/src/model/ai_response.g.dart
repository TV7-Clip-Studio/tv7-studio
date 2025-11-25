// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AIResponseCWProxy {
  AIResponse output(String output);

  AIResponse meta(Map<String, Object>? meta);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  AIResponse call({String output, Map<String, Object>? meta});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAIResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAIResponse.copyWith.fieldName(...)`
class _$AIResponseCWProxyImpl implements _$AIResponseCWProxy {
  const _$AIResponseCWProxyImpl(this._value);

  final AIResponse _value;

  @override
  AIResponse output(String output) => this(output: output);

  @override
  AIResponse meta(Map<String, Object>? meta) => this(meta: meta);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  AIResponse call({
    Object? output = const $CopyWithPlaceholder(),
    Object? meta = const $CopyWithPlaceholder(),
  }) {
    return AIResponse(
      output: output == const $CopyWithPlaceholder()
          ? _value.output
          // ignore: cast_nullable_to_non_nullable
          : output as String,
      meta: meta == const $CopyWithPlaceholder()
          ? _value.meta
          // ignore: cast_nullable_to_non_nullable
          : meta as Map<String, Object>?,
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

AIResponse _$AIResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AIResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['output']);
      final val = AIResponse(
        output: $checkedConvert('output', (v) => v as String),
        meta: $checkedConvert(
          'meta',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as Object),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AIResponseToJson(AIResponse instance) =>
    <String, dynamic>{'output': instance.output, 'meta': instance.meta};
