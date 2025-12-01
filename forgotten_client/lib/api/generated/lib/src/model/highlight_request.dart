// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'highlight_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HighlightRequest {
  /// Returns a new [HighlightRequest] instance.
  HighlightRequest({
    required this.durationSeconds,
    this.maxClips,
    this.prompt,
    required this.transcript,
    this.transcriptLanguage,
    this.videoId = 0,
  });

  @JsonKey(
    name: r'duration_seconds',
    required: true,
    includeIfNull: false,
  )
  final int durationSeconds;

  // minimum: 1
  // maximum: 8
  @JsonKey(
    name: r'max_clips',
    required: false,
    includeIfNull: false,
  )
  final int? maxClips;

  @JsonKey(
    name: r'prompt',
    required: false,
    includeIfNull: false,
  )
  final String? prompt;

  @JsonKey(
    name: r'transcript',
    required: true,
    includeIfNull: false,
  )
  final String transcript;

  @JsonKey(
    name: r'transcript_language',
    required: false,
    includeIfNull: false,
  )
  final String? transcriptLanguage;

  @JsonKey(
    defaultValue: 0,
    name: r'video_id',
    required: false,
    includeIfNull: false,
  )
  final int? videoId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightRequest &&
          other.durationSeconds == durationSeconds &&
          other.maxClips == maxClips &&
          other.prompt == prompt &&
          other.transcript == transcript &&
          other.transcriptLanguage == transcriptLanguage &&
          other.videoId == videoId;

  @override
  int get hashCode =>
      durationSeconds.hashCode +
      (maxClips == null ? 0 : maxClips.hashCode) +
      (prompt == null ? 0 : prompt.hashCode) +
      transcript.hashCode +
      (transcriptLanguage == null ? 0 : transcriptLanguage.hashCode) +
      videoId.hashCode;

  factory HighlightRequest.fromJson(Map<String, dynamic> json) =>
      _$HighlightRequestFromJson(json);

  Map<String, dynamic> toJson() => _$HighlightRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
