// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AIResponse {
  /// Returns a new [AIResponse] instance.
  AIResponse({
    this.meta,
    required this.output,
  });

  @JsonKey(
    name: r'meta',
    required: false,
    includeIfNull: false,
  )
  final Map<String, Object>? meta;

  @JsonKey(
    name: r'output',
    required: true,
    includeIfNull: false,
  )
  final String output;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIResponse && other.meta == meta && other.output == output;

  @override
  int get hashCode => meta.hashCode + output.hashCode;

  factory AIResponse.fromJson(Map<String, dynamic> json) =>
      _$AIResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AIResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
