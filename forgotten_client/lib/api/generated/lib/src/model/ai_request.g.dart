// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AIRequestCWProxy {
  AIRequest agentId(String? agentId);

  AIRequest context(Map<String, Object>? context);

  AIRequest input(String input);

  AIRequest sessionId(String? sessionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AIRequest call({
    String? agentId,
    Map<String, Object>? context,
    String? input,
    String? sessionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAIRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAIRequest.copyWith.fieldName(...)`
class _$AIRequestCWProxyImpl implements _$AIRequestCWProxy {
  const _$AIRequestCWProxyImpl(this._value);

  final AIRequest _value;

  @override
  AIRequest agentId(String? agentId) => this(agentId: agentId);

  @override
  AIRequest context(Map<String, Object>? context) => this(context: context);

  @override
  AIRequest input(String input) => this(input: input);

  @override
  AIRequest sessionId(String? sessionId) => this(sessionId: sessionId);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AIRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AIRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AIRequest call({
    Object? agentId = const $CopyWithPlaceholder(),
    Object? context = const $CopyWithPlaceholder(),
    Object? input = const $CopyWithPlaceholder(),
    Object? sessionId = const $CopyWithPlaceholder(),
  }) {
    return AIRequest(
      agentId: agentId == const $CopyWithPlaceholder()
          ? _value.agentId
          // ignore: cast_nullable_to_non_nullable
          : agentId as String?,
      context: context == const $CopyWithPlaceholder()
          ? _value.context
          // ignore: cast_nullable_to_non_nullable
          : context as Map<String, Object>?,
      input: input == const $CopyWithPlaceholder() || input == null
          ? _value.input
          // ignore: cast_nullable_to_non_nullable
          : input as String,
      sessionId: sessionId == const $CopyWithPlaceholder()
          ? _value.sessionId
          // ignore: cast_nullable_to_non_nullable
          : sessionId as String?,
    );
  }
}

extension $AIRequestCopyWith on AIRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAIRequest.copyWith(...)` or like so:`instanceOfAIRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AIRequestCWProxy get copyWith => _$AIRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIRequest _$AIRequestFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AIRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['input'],
        );
        final val = AIRequest(
          agentId:
              $checkedConvert('agent_id', (v) => v as String? ?? 'default'),
          context: $checkedConvert(
              'context',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as Object),
                  )),
          input: $checkedConvert('input', (v) => v as String),
          sessionId: $checkedConvert('session_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'agentId': 'agent_id', 'sessionId': 'session_id'},
    );

Map<String, dynamic> _$AIRequestToJson(AIRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('agent_id', instance.agentId);
  writeNotNull('context', instance.context);
  val['input'] = instance.input;
  writeNotNull('session_id', instance.sessionId);
  return val;
}
