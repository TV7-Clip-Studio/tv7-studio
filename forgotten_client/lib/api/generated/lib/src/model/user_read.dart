//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
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

    required  this.id,

    required  this.email,

    required  this.fullName,

    required  this.isActive,

    required  this.createdAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    
  )


  final int id;



  @JsonKey(
    
    name: r'email',
    required: true,
    
  )


  final String email;



  @JsonKey(
    
    name: r'full_name',
    required: true,
    
  )


  final String fullName;



  @JsonKey(
    
    name: r'is_active',
    required: true,
    
  )


  final bool isActive;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UserRead &&
      other.id == id &&
      other.email == email &&
      other.fullName == fullName &&
      other.isActive == isActive &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        email.hashCode +
        fullName.hashCode +
        isActive.hashCode +
        createdAt.hashCode +
        updatedAt.hashCode;

  factory UserRead.fromJson(Map<String, dynamic> json) => _$UserReadFromJson(json);

  Map<String, dynamic> toJson() => _$UserReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

