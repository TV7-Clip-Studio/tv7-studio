// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AIRequest {
  /// Returns a new [AIRequest] instance.
  AIRequest({
    this.agentId = 'default',
    this.context,
    required this.input,
    this.sessionId,
  });

  @JsonKey(
    defaultValue: 'default',
    name: r'agent_id',
    required: false,
    includeIfNull: false,
  )
  final String? agentId;

  @JsonKey(
    name: r'context',
    required: false,
    includeIfNull: false,
  )
  final Map<String, Object>? context;

  @JsonKey(
    name: r'input',
    required: true,
    includeIfNull: false,
  )
  final String input;

  @JsonKey(
    name: r'session_id',
    required: false,
    includeIfNull: false,
  )
  final String? sessionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIRequest &&
          other.agentId == agentId &&
          other.context == context &&
          other.input == input &&
          other.sessionId == sessionId;

  @override
  int get hashCode =>
      agentId.hashCode +
      (context == null ? 0 : context.hashCode) +
      input.hashCode +
      (sessionId == null ? 0 : sessionId.hashCode);

  factory AIRequest.fromJson(Map<String, dynamic> json) =>
      _$AIRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AIRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
