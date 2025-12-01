// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'validation_error.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ValidationError {
  /// Returns a new [ValidationError] instance.
  ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
  });

  /// Location entries flattened to strings for client SDK compatibility.
  @JsonKey(
    name: r'loc',
    required: true,
    includeIfNull: false,
  )
  final List<String> loc;

  @JsonKey(
    name: r'msg',
    required: true,
    includeIfNull: false,
  )
  final String msg;

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final String type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          other.loc == loc &&
          other.msg == msg &&
          other.type == type;

  @override
  int get hashCode => loc.hashCode + msg.hashCode + type.hashCode;

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
