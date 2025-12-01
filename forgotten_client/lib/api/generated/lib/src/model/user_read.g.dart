// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserReadCWProxy {
  UserRead createdAt(DateTime createdAt);

  UserRead email(String email);

  UserRead fullName(String fullName);

  UserRead id(int id);

  UserRead isActive(bool isActive);

  UserRead plan(PlanType plan);

  UserRead trialExpiresAt(DateTime? trialExpiresAt);

  UserRead trialStartedAt(DateTime? trialStartedAt);

  UserRead updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserRead(...).copyWith(id: 12, name: "My name")
  /// ````
  UserRead call({
    DateTime? createdAt,
    String? email,
    String? fullName,
    int? id,
    bool? isActive,
    PlanType? plan,
    DateTime? trialExpiresAt,
    DateTime? trialStartedAt,
    DateTime? updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUserRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUserRead.copyWith.fieldName(...)`
class _$UserReadCWProxyImpl implements _$UserReadCWProxy {
  const _$UserReadCWProxyImpl(this._value);

  final UserRead _value;

  @override
  UserRead createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  UserRead email(String email) => this(email: email);

  @override
  UserRead fullName(String fullName) => this(fullName: fullName);

  @override
  UserRead id(int id) => this(id: id);

  @override
  UserRead isActive(bool isActive) => this(isActive: isActive);

  @override
  UserRead plan(PlanType plan) => this(plan: plan);

  @override
  UserRead trialExpiresAt(DateTime? trialExpiresAt) =>
      this(trialExpiresAt: trialExpiresAt);

  @override
  UserRead trialStartedAt(DateTime? trialStartedAt) =>
      this(trialStartedAt: trialStartedAt);

  @override
  UserRead updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserRead(...).copyWith(id: 12, name: "My name")
  /// ````
  UserRead call({
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? fullName = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? isActive = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? trialExpiresAt = const $CopyWithPlaceholder(),
    Object? trialStartedAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return UserRead(
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      fullName: fullName == const $CopyWithPlaceholder() || fullName == null
          ? _value.fullName
          // ignore: cast_nullable_to_non_nullable
          : fullName as String,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      isActive: isActive == const $CopyWithPlaceholder() || isActive == null
          ? _value.isActive
          // ignore: cast_nullable_to_non_nullable
          : isActive as bool,
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
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $UserReadCopyWith on UserRead {
  /// Returns a callable class that can be used as follows: `instanceOfUserRead.copyWith(...)` or like so:`instanceOfUserRead.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserReadCWProxy get copyWith => _$UserReadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRead _$UserReadFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserRead',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'created_at',
            'email',
            'full_name',
            'id',
            'is_active',
            'plan',
            'updated_at'
          ],
        );
        final val = UserRead(
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          email: $checkedConvert('email', (v) => v as String),
          fullName: $checkedConvert('full_name', (v) => v as String),
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          isActive: $checkedConvert('is_active', (v) => v as bool),
          plan:
              $checkedConvert('plan', (v) => $enumDecode(_$PlanTypeEnumMap, v)),
          trialExpiresAt: $checkedConvert('trial_expires_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          trialStartedAt: $checkedConvert('trial_started_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'fullName': 'full_name',
        'isActive': 'is_active',
        'trialExpiresAt': 'trial_expires_at',
        'trialStartedAt': 'trial_started_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$UserReadToJson(UserRead instance) {
  final val = <String, dynamic>{
    'created_at': instance.createdAt.toIso8601String(),
    'email': instance.email,
    'full_name': instance.fullName,
    'id': instance.id,
    'is_active': instance.isActive,
    'plan': _$PlanTypeEnumMap[instance.plan]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('trial_expires_at', instance.trialExpiresAt?.toIso8601String());
  writeNotNull('trial_started_at', instance.trialStartedAt?.toIso8601String());
  val['updated_at'] = instance.updatedAt.toIso8601String();
  return val;
}

const _$PlanTypeEnumMap = {
  PlanType.trial: 'trial',
  PlanType.core: 'core',
  PlanType.pro: 'pro',
};
