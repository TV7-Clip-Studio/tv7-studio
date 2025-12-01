// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activate_license_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivateLicenseRequestCWProxy {
  ActivateLicenseRequest activationKey(String activationKey);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ActivateLicenseRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ActivateLicenseRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ActivateLicenseRequest call({
    String? activationKey,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfActivateLicenseRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfActivateLicenseRequest.copyWith.fieldName(...)`
class _$ActivateLicenseRequestCWProxyImpl
    implements _$ActivateLicenseRequestCWProxy {
  const _$ActivateLicenseRequestCWProxyImpl(this._value);

  final ActivateLicenseRequest _value;

  @override
  ActivateLicenseRequest activationKey(String activationKey) =>
      this(activationKey: activationKey);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ActivateLicenseRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ActivateLicenseRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ActivateLicenseRequest call({
    Object? activationKey = const $CopyWithPlaceholder(),
  }) {
    return ActivateLicenseRequest(
      activationKey:
          activationKey == const $CopyWithPlaceholder() || activationKey == null
              ? _value.activationKey
              // ignore: cast_nullable_to_non_nullable
              : activationKey as String,
    );
  }
}

extension $ActivateLicenseRequestCopyWith on ActivateLicenseRequest {
  /// Returns a callable class that can be used as follows: `instanceOfActivateLicenseRequest.copyWith(...)` or like so:`instanceOfActivateLicenseRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivateLicenseRequestCWProxy get copyWith =>
      _$ActivateLicenseRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivateLicenseRequest _$ActivateLicenseRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ActivateLicenseRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['activation_key'],
        );
        final val = ActivateLicenseRequest(
          activationKey: $checkedConvert('activation_key', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'activationKey': 'activation_key'},
    );

Map<String, dynamic> _$ActivateLicenseRequestToJson(
        ActivateLicenseRequest instance) =>
    <String, dynamic>{
      'activation_key': instance.activationKey,
    };
