// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/plan_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'license_status.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LicenseStatus {
  /// Returns a new [LicenseStatus] instance.
  LicenseStatus({
    required this.expiresAt,
    required this.licenseToken,
    required this.plan,
    this.trialExpiresAt,
    this.trialStartedAt,
  });

  @JsonKey(
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime expiresAt;

  @JsonKey(
    name: r'license_token',
    required: true,
    includeIfNull: false,
  )
  final String licenseToken;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenseStatus &&
          other.expiresAt == expiresAt &&
          other.licenseToken == licenseToken &&
          other.plan == plan &&
          other.trialExpiresAt == trialExpiresAt &&
          other.trialStartedAt == trialStartedAt;

  @override
  int get hashCode =>
      expiresAt.hashCode +
      licenseToken.hashCode +
      plan.hashCode +
      (trialExpiresAt == null ? 0 : trialExpiresAt.hashCode) +
      (trialStartedAt == null ? 0 : trialStartedAt.hashCode);

  factory LicenseStatus.fromJson(Map<String, dynamic> json) =>
      _$LicenseStatusFromJson(json);

  Map<String, dynamic> toJson() => _$LicenseStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
