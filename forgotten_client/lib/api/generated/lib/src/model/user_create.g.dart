// @dart=3.4
// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserCreateCWProxy {
  UserCreate email(String email);

  UserCreate fullName(String fullName);

  UserCreate password(String password);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  UserCreate call({
    String? email,
    String? fullName,
    String? password,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUserCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUserCreate.copyWith.fieldName(...)`
class _$UserCreateCWProxyImpl implements _$UserCreateCWProxy {
  const _$UserCreateCWProxyImpl(this._value);

  final UserCreate _value;

  @override
  UserCreate email(String email) => this(email: email);

  @override
  UserCreate fullName(String fullName) => this(fullName: fullName);

  @override
  UserCreate password(String password) => this(password: password);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  UserCreate call({
    Object? email = const $CopyWithPlaceholder(),
    Object? fullName = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
  }) {
    return UserCreate(
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      fullName: fullName == const $CopyWithPlaceholder() || fullName == null
          ? _value.fullName
          // ignore: cast_nullable_to_non_nullable
          : fullName as String,
      password: password == const $CopyWithPlaceholder() || password == null
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
    );
  }
}

extension $UserCreateCopyWith on UserCreate {
  /// Returns a callable class that can be used as follows: `instanceOfUserCreate.copyWith(...)` or like so:`instanceOfUserCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserCreateCWProxy get copyWith => _$UserCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCreate _$UserCreateFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['email', 'full_name', 'password'],
        );
        final val = UserCreate(
          email: $checkedConvert('email', (v) => v as String),
          fullName: $checkedConvert('full_name', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'fullName': 'full_name'},
    );

Map<String, dynamic> _$UserCreateToJson(UserCreate instance) =>
    <String, dynamic>{
      'email': instance.email,
      'full_name': instance.fullName,
      'password': instance.password,
    };
