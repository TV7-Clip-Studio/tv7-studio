// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activate_license_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivateLicenseRequest {
  /// Returns a new [ActivateLicenseRequest] instance.
  ActivateLicenseRequest({
    required this.activationKey,
  });

  @JsonKey(
    name: r'activation_key',
    required: true,
    includeIfNull: false,
  )
  final String activationKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivateLicenseRequest && other.activationKey == activationKey;

  @override
  int get hashCode => activationKey.hashCode;

  factory ActivateLicenseRequest.fromJson(Map<String, dynamic> json) =>
      _$ActivateLicenseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ActivateLicenseRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
