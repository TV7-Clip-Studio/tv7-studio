// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserReadCWProxy {
  UserRead id(int id);

  UserRead email(String email);

  UserRead fullName(String fullName);

  UserRead isActive(bool isActive);

  UserRead createdAt(DateTime createdAt);

  UserRead updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserRead(...).copyWith(id: 12, name: "My name")
  /// ````
  UserRead call({
    int id,
    String email,
    String fullName,
    bool isActive,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUserRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUserRead.copyWith.fieldName(...)`
class _$UserReadCWProxyImpl implements _$UserReadCWProxy {
  const _$UserReadCWProxyImpl(this._value);

  final UserRead _value;

  @override
  UserRead id(int id) => this(id: id);

  @override
  UserRead email(String email) => this(email: email);

  @override
  UserRead fullName(String fullName) => this(fullName: fullName);

  @override
  UserRead isActive(bool isActive) => this(isActive: isActive);

  @override
  UserRead createdAt(DateTime createdAt) => this(createdAt: createdAt);

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
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? fullName = const $CopyWithPlaceholder(),
    Object? isActive = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return UserRead(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      fullName: fullName == const $CopyWithPlaceholder()
          ? _value.fullName
          // ignore: cast_nullable_to_non_nullable
          : fullName as String,
      isActive: isActive == const $CopyWithPlaceholder()
          ? _value.isActive
          // ignore: cast_nullable_to_non_nullable
          : isActive as bool,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
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
        'id',
        'email',
        'full_name',
        'is_active',
        'created_at',
        'updated_at',
      ],
    );
    final val = UserRead(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      email: $checkedConvert('email', (v) => v as String),
      fullName: $checkedConvert('full_name', (v) => v as String),
      isActive: $checkedConvert('is_active', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'fullName': 'full_name',
    'isActive': 'is_active',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$UserReadToJson(UserRead instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
