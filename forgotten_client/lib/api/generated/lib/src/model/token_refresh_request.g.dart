// @dart=3.4
// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_refresh_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TokenRefreshRequestCWProxy {
  TokenRefreshRequest refreshToken(String refreshToken);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TokenRefreshRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TokenRefreshRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  TokenRefreshRequest call({
    String? refreshToken,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTokenRefreshRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTokenRefreshRequest.copyWith.fieldName(...)`
class _$TokenRefreshRequestCWProxyImpl implements _$TokenRefreshRequestCWProxy {
  const _$TokenRefreshRequestCWProxyImpl(this._value);

  final TokenRefreshRequest _value;

  @override
  TokenRefreshRequest refreshToken(String refreshToken) =>
      this(refreshToken: refreshToken);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TokenRefreshRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TokenRefreshRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  TokenRefreshRequest call({
    Object? refreshToken = const $CopyWithPlaceholder(),
  }) {
    return TokenRefreshRequest(
      refreshToken:
          refreshToken == const $CopyWithPlaceholder() || refreshToken == null
              ? _value.refreshToken
              // ignore: cast_nullable_to_non_nullable
              : refreshToken as String,
    );
  }
}

extension $TokenRefreshRequestCopyWith on TokenRefreshRequest {
  /// Returns a callable class that can be used as follows: `instanceOfTokenRefreshRequest.copyWith(...)` or like so:`instanceOfTokenRefreshRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TokenRefreshRequestCWProxy get copyWith =>
      _$TokenRefreshRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenRefreshRequest _$TokenRefreshRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TokenRefreshRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['refresh_token'],
        );
        final val = TokenRefreshRequest(
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'refreshToken': 'refresh_token'},
    );

Map<String, dynamic> _$TokenRefreshRequestToJson(
        TokenRefreshRequest instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };
