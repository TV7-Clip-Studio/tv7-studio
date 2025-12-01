// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'you_tube_ingest_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YouTubeIngestRequest {
  /// Returns a new [YouTubeIngestRequest] instance.
  YouTubeIngestRequest({
    this.appendClips = false,
    required this.youtubeUrl,
  });

  @JsonKey(
    defaultValue: false,
    name: r'append_clips',
    required: false,
    includeIfNull: false,
  )
  final bool? appendClips;

  @JsonKey(
    name: r'youtube_url',
    required: true,
    includeIfNull: false,
  )
  final String youtubeUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeIngestRequest &&
          other.appendClips == appendClips &&
          other.youtubeUrl == youtubeUrl;

  @override
  int get hashCode => appendClips.hashCode + youtubeUrl.hashCode;

  factory YouTubeIngestRequest.fromJson(Map<String, dynamic> json) =>
      _$YouTubeIngestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$YouTubeIngestRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
