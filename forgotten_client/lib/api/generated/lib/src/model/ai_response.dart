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

    required  this.output,

     this.meta,
  });

  @JsonKey(
    
    name: r'output',
    required: true,
    
  )


  final String output;



  @JsonKey(
    
    name: r'meta',
    required: false,
    
  )


  final Map<String, Object>? meta;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AIResponse &&
      other.output == output &&
      other.meta == meta;

    @override
    int get hashCode =>
        output.hashCode +
        meta.hashCode;

  factory AIResponse.fromJson(Map<String, dynamic> json) => _$AIResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AIResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

