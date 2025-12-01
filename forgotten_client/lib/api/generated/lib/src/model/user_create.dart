// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserCreate {
  /// Returns a new [UserCreate] instance.
  UserCreate({
    required this.email,
    required this.fullName,
    required this.password,
  });

  @JsonKey(
    name: r'email',
    required: true,
    includeIfNull: false,
  )
  final String email;

  @JsonKey(
    name: r'full_name',
    required: true,
    includeIfNull: false,
  )
  final String fullName;

  @JsonKey(
    name: r'password',
    required: true,
    includeIfNull: false,
  )
  final String password;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCreate &&
          other.email == email &&
          other.fullName == fullName &&
          other.password == password;

  @override
  int get hashCode => email.hashCode + fullName.hashCode + password.hashCode;

  factory UserCreate.fromJson(Map<String, dynamic> json) =>
      _$UserCreateFromJson(json);

  Map<String, dynamic> toJson() => _$UserCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
