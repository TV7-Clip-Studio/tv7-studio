//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/video_read.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'video_ingest_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VideoIngestResponse {
  /// Returns a new [VideoIngestResponse] instance.
  VideoIngestResponse({
    required this.video,

    this.queued = true,

    required this.created,
  });

  @JsonKey(name: r'video', required: true)
  final VideoRead video;

  @JsonKey(defaultValue: true, name: r'queued', required: false)
  final bool? queued;

  @JsonKey(name: r'created', required: true)
  final bool created;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoIngestResponse &&
          other.video == video &&
          other.queued == queued &&
          other.created == created;

  @override
  int get hashCode => video.hashCode + queued.hashCode + created.hashCode;

  factory VideoIngestResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoIngestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoIngestResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
