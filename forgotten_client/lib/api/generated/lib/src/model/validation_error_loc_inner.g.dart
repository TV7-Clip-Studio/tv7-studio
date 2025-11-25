// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_error_loc_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ValidationErrorLocInnerCWProxy {
  ValidationErrorLocInner dummy(String? dummy);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ValidationErrorLocInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ValidationErrorLocInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ValidationErrorLocInner call({String? dummy});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfValidationErrorLocInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfValidationErrorLocInner.copyWith.fieldName(...)`
class _$ValidationErrorLocInnerCWProxyImpl
    implements _$ValidationErrorLocInnerCWProxy {
  const _$ValidationErrorLocInnerCWProxyImpl(this._value);

  final ValidationErrorLocInner _value;

  @override
  ValidationErrorLocInner dummy(String? dummy) => this(dummy: dummy);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ValidationErrorLocInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ValidationErrorLocInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ValidationErrorLocInner call({Object? dummy = const $CopyWithPlaceholder()}) {
    return ValidationErrorLocInner(
      dummy: dummy == const $CopyWithPlaceholder()
          ? _value.dummy
          // ignore: cast_nullable_to_non_nullable
          : dummy as String?,
    );
  }
}

extension $ValidationErrorLocInnerCopyWith on ValidationErrorLocInner {
  /// Returns a callable class that can be used as follows: `instanceOfValidationErrorLocInner.copyWith(...)` or like so:`instanceOfValidationErrorLocInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ValidationErrorLocInnerCWProxy get copyWith =>
      _$ValidationErrorLocInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationErrorLocInner _$ValidationErrorLocInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ValidationErrorLocInner', json, ($checkedConvert) {
  final val = ValidationErrorLocInner(
    dummy: $checkedConvert('dummy', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$ValidationErrorLocInnerToJson(
  ValidationErrorLocInner instance,
) => <String, dynamic>{'dummy': instance.dummy};
