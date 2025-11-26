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
  YouTubeIngestRequest({required this.youtubeUrl, this.appendClips = false});

  @JsonKey(name: r'youtube_url', required: true)
  final String youtubeUrl;

  @JsonKey(defaultValue: false, name: r'append_clips', required: false)
  final bool? appendClips;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeIngestRequest &&
          other.youtubeUrl == youtubeUrl &&
          other.appendClips == appendClips;

  @override
  int get hashCode => youtubeUrl.hashCode + appendClips.hashCode;

  factory YouTubeIngestRequest.fromJson(Map<String, dynamic> json) =>
      _$YouTubeIngestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$YouTubeIngestRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
