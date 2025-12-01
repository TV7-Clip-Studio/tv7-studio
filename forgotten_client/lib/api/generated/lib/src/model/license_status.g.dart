// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LicenseStatusCWProxy {
  LicenseStatus expiresAt(DateTime expiresAt);

  LicenseStatus licenseToken(String licenseToken);

  LicenseStatus plan(PlanType plan);

  LicenseStatus trialExpiresAt(DateTime? trialExpiresAt);

  LicenseStatus trialStartedAt(DateTime? trialStartedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LicenseStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LicenseStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  LicenseStatus call({
    DateTime? expiresAt,
    String? licenseToken,
    PlanType? plan,
    DateTime? trialExpiresAt,
    DateTime? trialStartedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLicenseStatus.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLicenseStatus.copyWith.fieldName(...)`
class _$LicenseStatusCWProxyImpl implements _$LicenseStatusCWProxy {
  const _$LicenseStatusCWProxyImpl(this._value);

  final LicenseStatus _value;

  @override
  LicenseStatus expiresAt(DateTime expiresAt) => this(expiresAt: expiresAt);

  @override
  LicenseStatus licenseToken(String licenseToken) =>
      this(licenseToken: licenseToken);

  @override
  LicenseStatus plan(PlanType plan) => this(plan: plan);

  @override
  LicenseStatus trialExpiresAt(DateTime? trialExpiresAt) =>
      this(trialExpiresAt: trialExpiresAt);

  @override
  LicenseStatus trialStartedAt(DateTime? trialStartedAt) =>
      this(trialStartedAt: trialStartedAt);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LicenseStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LicenseStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  LicenseStatus call({
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? licenseToken = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? trialExpiresAt = const $CopyWithPlaceholder(),
    Object? trialStartedAt = const $CopyWithPlaceholder(),
  }) {
    return LicenseStatus(
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      licenseToken:
          licenseToken == const $CopyWithPlaceholder() || licenseToken == null
              ? _value.licenseToken
              // ignore: cast_nullable_to_non_nullable
              : licenseToken as String,
      plan: plan == const $CopyWithPlaceholder() || plan == null
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as PlanType,
      trialExpiresAt: trialExpiresAt == const $CopyWithPlaceholder()
          ? _value.trialExpiresAt
          // ignore: cast_nullable_to_non_nullable
          : trialExpiresAt as DateTime?,
      trialStartedAt: trialStartedAt == const $CopyWithPlaceholder()
          ? _value.trialStartedAt
          // ignore: cast_nullable_to_non_nullable
          : trialStartedAt as DateTime?,
    );
  }
}

extension $LicenseStatusCopyWith on LicenseStatus {
  /// Returns a callable class that can be used as follows: `instanceOfLicenseStatus.copyWith(...)` or like so:`instanceOfLicenseStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LicenseStatusCWProxy get copyWith => _$LicenseStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LicenseStatus _$LicenseStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LicenseStatus',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['expires_at', 'license_token', 'plan'],
        );
        final val = LicenseStatus(
          expiresAt:
              $checkedConvert('expires_at', (v) => DateTime.parse(v as String)),
          licenseToken: $checkedConvert('license_token', (v) => v as String),
          plan:
              $checkedConvert('plan', (v) => $enumDecode(_$PlanTypeEnumMap, v)),
          trialExpiresAt: $checkedConvert('trial_expires_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          trialStartedAt: $checkedConvert('trial_started_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'expiresAt': 'expires_at',
        'licenseToken': 'license_token',
        'trialExpiresAt': 'trial_expires_at',
        'trialStartedAt': 'trial_started_at'
      },
    );

Map<String, dynamic> _$LicenseStatusToJson(LicenseStatus instance) {
  final val = <String, dynamic>{
    'expires_at': instance.expiresAt.toIso8601String(),
    'license_token': instance.licenseToken,
    'plan': _$PlanTypeEnumMap[instance.plan]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('trial_expires_at', instance.trialExpiresAt?.toIso8601String());
  writeNotNull('trial_started_at', instance.trialStartedAt?.toIso8601String());
  return val;
}

const _$PlanTypeEnumMap = {
  PlanType.trial: 'trial',
  PlanType.core: 'core',
  PlanType.pro: 'pro',
};
