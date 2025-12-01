// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/suggested_clip.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'highlight_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HighlightResponse {
  /// Returns a new [HighlightResponse] instance.
  HighlightResponse({
    required this.clips,
  });

  @JsonKey(
    name: r'clips',
    required: true,
    includeIfNull: false,
  )
  final List<SuggestedClip> clips;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightResponse && other.clips == clips;

  @override
  int get hashCode => clips.hashCode;

  factory HighlightResponse.fromJson(Map<String, dynamic> json) =>
      _$HighlightResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HighlightResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
