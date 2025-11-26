//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:forgotten_client_api/src/model/publish_job_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publish_job_read.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishJobRead {
  /// Returns a new [PublishJobRead] instance.
  PublishJobRead({
    required this.id,

    required this.clipId,

    required this.platform,

    required this.status,

    this.assetUrl,

    this.assetChecksum,

    this.assetSizeBytes,

    this.responsePayload,

    this.errorMessage,

    required this.createdAt,

    required this.updatedAt,
  });

  @JsonKey(name: r'id', required: true)
  final int id;

  @JsonKey(name: r'clip_id', required: true)
  final int clipId;

  @JsonKey(name: r'platform', required: true)
  final String platform;

  @JsonKey(name: r'status', required: true)
  final PublishJobStatus status;

  @JsonKey(name: r'asset_url', required: false)
  final String? assetUrl;

  @JsonKey(name: r'asset_checksum', required: false)
  final String? assetChecksum;

  @JsonKey(name: r'asset_size_bytes', required: false)
  final int? assetSizeBytes;

  @JsonKey(name: r'response_payload', required: false)
  final String? responsePayload;

  @JsonKey(name: r'error_message', required: false)
  final String? errorMessage;

  @JsonKey(name: r'created_at', required: true)
  final DateTime createdAt;

  @JsonKey(name: r'updated_at', required: true)
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishJobRead &&
          other.id == id &&
          other.clipId == clipId &&
          other.platform == platform &&
          other.status == status &&
          other.assetUrl == assetUrl &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.responsePayload == responsePayload &&
          other.errorMessage == errorMessage &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      clipId.hashCode +
      platform.hashCode +
      status.hashCode +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      (responsePayload == null ? 0 : responsePayload.hashCode) +
      (errorMessage == null ? 0 : errorMessage.hashCode) +
      createdAt.hashCode +
      updatedAt.hashCode;

  factory PublishJobRead.fromJson(Map<String, dynamic> json) =>
      _$PublishJobReadFromJson(json);

  Map<String, dynamic> toJson() => _$PublishJobReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
