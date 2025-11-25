//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_refresh_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokenRefreshRequest {
  /// Returns a new [TokenRefreshRequest] instance.
  TokenRefreshRequest({

    required  this.refreshToken,
  });

  @JsonKey(
    
    name: r'refresh_token',
    required: true,
    
  )


  final String refreshToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TokenRefreshRequest &&
      other.refreshToken == refreshToken;

    @override
    int get hashCode =>
        refreshToken.hashCode;

  factory TokenRefreshRequest.fromJson(Map<String, dynamic> json) => _$TokenRefreshRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TokenRefreshRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

