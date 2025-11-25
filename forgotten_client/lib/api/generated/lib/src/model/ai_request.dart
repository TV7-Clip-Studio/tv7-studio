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

    required  this.input,

     this.sessionId,

     this.context,
  });

  @JsonKey(
    defaultValue: 'default',
    name: r'agent_id',
    required: false,
    
  )


  final String? agentId;



  @JsonKey(
    
    name: r'input',
    required: true,
    
  )


  final String input;



  @JsonKey(
    
    name: r'session_id',
    required: false,
    
  )


  final String? sessionId;



  @JsonKey(
    
    name: r'context',
    required: false,
    
  )


  final Map<String, Object>? context;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AIRequest &&
      other.agentId == agentId &&
      other.input == input &&
      other.sessionId == sessionId &&
      other.context == context;

    @override
    int get hashCode =>
        agentId.hashCode +
        input.hashCode +
        (sessionId == null ? 0 : sessionId.hashCode) +
        (context == null ? 0 : context.hashCode);

  factory AIRequest.fromJson(Map<String, dynamic> json) => _$AIRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AIRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

