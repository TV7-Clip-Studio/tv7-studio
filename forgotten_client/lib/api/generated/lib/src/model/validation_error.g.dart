// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_error.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ValidationErrorCWProxy {
  ValidationError loc(List<String> loc);

  ValidationError msg(String msg);

  ValidationError type(String type);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ValidationError(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ValidationError(...).copyWith(id: 12, name: "My name")
  /// ````
  ValidationError call({
    List<String>? loc,
    String? msg,
    String? type,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfValidationError.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfValidationError.copyWith.fieldName(...)`
class _$ValidationErrorCWProxyImpl implements _$ValidationErrorCWProxy {
  const _$ValidationErrorCWProxyImpl(this._value);

  final ValidationError _value;

  @override
  ValidationError loc(List<String> loc) => this(loc: loc);

  @override
  ValidationError msg(String msg) => this(msg: msg);

  @override
  ValidationError type(String type) => this(type: type);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ValidationError(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ValidationError(...).copyWith(id: 12, name: "My name")
  /// ````
  ValidationError call({
    Object? loc = const $CopyWithPlaceholder(),
    Object? msg = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
  }) {
    return ValidationError(
      loc: loc == const $CopyWithPlaceholder() || loc == null
          ? _value.loc
          // ignore: cast_nullable_to_non_nullable
          : loc as List<String>,
      msg: msg == const $CopyWithPlaceholder() || msg == null
          ? _value.msg
          // ignore: cast_nullable_to_non_nullable
          : msg as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
    );
  }
}

extension $ValidationErrorCopyWith on ValidationError {
  /// Returns a callable class that can be used as follows: `instanceOfValidationError.copyWith(...)` or like so:`instanceOfValidationError.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ValidationErrorCWProxy get copyWith => _$ValidationErrorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationError _$ValidationErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ValidationError',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['loc', 'msg', 'type'],
        );
        final val = ValidationError(
          loc: $checkedConvert('loc',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          msg: $checkedConvert('msg', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      'loc': instance.loc,
      'msg': instance.msg,
      'type': instance.type,
    };
