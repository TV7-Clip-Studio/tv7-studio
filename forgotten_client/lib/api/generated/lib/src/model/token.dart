//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Token {
  /// Returns a new [Token] instance.
  Token({

    required  this.accessToken,

     this.refreshToken,

     this.tokenType = 'bearer',
  });

  @JsonKey(
    
    name: r'access_token',
    required: true,
    
  )


  final String accessToken;



  @JsonKey(
    
    name: r'refresh_token',
    required: false,
    
  )


  final String? refreshToken;



  @JsonKey(
    defaultValue: 'bearer',
    name: r'token_type',
    required: false,
    
  )


  final String? tokenType;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Token &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.tokenType == tokenType;

    @override
    int get hashCode =>
        accessToken.hashCode +
        (refreshToken == null ? 0 : refreshToken.hashCode) +
        tokenType.hashCode;

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

