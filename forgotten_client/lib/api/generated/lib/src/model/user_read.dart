// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/plan_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_read.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserRead {
  /// Returns a new [UserRead] instance.
  UserRead({
    required this.createdAt,
    required this.email,
    required this.fullName,
    required this.id,
    required this.isActive,
    required this.plan,
    this.trialExpiresAt,
    this.trialStartedAt,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

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
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final int id;

  @JsonKey(
    name: r'is_active',
    required: true,
    includeIfNull: false,
  )
  final bool isActive;

  @JsonKey(
    name: r'plan',
    required: true,
    includeIfNull: false,
  )
  final PlanType plan;

  @JsonKey(
    name: r'trial_expires_at',
    required: false,
    includeIfNull: false,
  )
  final DateTime? trialExpiresAt;

  @JsonKey(
    name: r'trial_started_at',
    required: false,
    includeIfNull: false,
  )
  final DateTime? trialStartedAt;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRead &&
          other.createdAt == createdAt &&
          other.email == email &&
          other.fullName == fullName &&
          other.id == id &&
          other.isActive == isActive &&
          other.plan == plan &&
          other.trialExpiresAt == trialExpiresAt &&
          other.trialStartedAt == trialStartedAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      createdAt.hashCode +
      email.hashCode +
      fullName.hashCode +
      id.hashCode +
      isActive.hashCode +
      plan.hashCode +
      (trialExpiresAt == null ? 0 : trialExpiresAt.hashCode) +
      (trialStartedAt == null ? 0 : trialStartedAt.hashCode) +
      updatedAt.hashCode;

  factory UserRead.fromJson(Map<String, dynamic> json) =>
      _$UserReadFromJson(json);

  Map<String, dynamic> toJson() => _$UserReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
