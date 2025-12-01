// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggested_clip.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuggestedClip {
  /// Returns a new [SuggestedClip] instance.
  SuggestedClip({
    required this.description,
    required this.endSec,
    required this.hook,
    required this.startSec,
    required this.title,
  });

  @JsonKey(
    name: r'description',
    required: true,
    includeIfNull: false,
  )
  final String description;

  @JsonKey(
    name: r'end_sec',
    required: true,
    includeIfNull: false,
  )
  final int endSec;

  @JsonKey(
    name: r'hook',
    required: true,
    includeIfNull: false,
  )
  final String hook;

  @JsonKey(
    name: r'start_sec',
    required: true,
    includeIfNull: false,
  )
  final int startSec;

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestedClip &&
          other.description == description &&
          other.endSec == endSec &&
          other.hook == hook &&
          other.startSec == startSec &&
          other.title == title;

  @override
  int get hashCode =>
      description.hashCode +
      endSec.hashCode +
      hook.hashCode +
      startSec.hashCode +
      title.hashCode;

  factory SuggestedClip.fromJson(Map<String, dynamic> json) =>
      _$SuggestedClipFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestedClipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
