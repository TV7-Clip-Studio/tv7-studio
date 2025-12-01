// @dart=3.4
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
    this.assetChecksum,
    this.assetSizeBytes,
    this.assetUrl,
    required this.clipId,
    required this.createdAt,
    this.errorMessage,
    required this.id,
    required this.platform,
    this.responsePayload,
    required this.status,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'asset_checksum',
    required: false,
    includeIfNull: false,
  )
  final String? assetChecksum;

  @JsonKey(
    name: r'asset_size_bytes',
    required: false,
    includeIfNull: false,
  )
  final int? assetSizeBytes;

  @JsonKey(
    name: r'asset_url',
    required: false,
    includeIfNull: false,
  )
  final String? assetUrl;

  @JsonKey(
    name: r'clip_id',
    required: true,
    includeIfNull: false,
  )
  final int clipId;

  @JsonKey(
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

  @JsonKey(
    name: r'error_message',
    required: false,
    includeIfNull: false,
  )
  final String? errorMessage;

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final int id;

  @JsonKey(
    name: r'platform',
    required: true,
    includeIfNull: false,
  )
  final String platform;

  @JsonKey(
    name: r'response_payload',
    required: false,
    includeIfNull: false,
  )
  final String? responsePayload;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final PublishJobStatus status;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishJobRead &&
          other.assetChecksum == assetChecksum &&
          other.assetSizeBytes == assetSizeBytes &&
          other.assetUrl == assetUrl &&
          other.clipId == clipId &&
          other.createdAt == createdAt &&
          other.errorMessage == errorMessage &&
          other.id == id &&
          other.platform == platform &&
          other.responsePayload == responsePayload &&
          other.status == status &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      (assetChecksum == null ? 0 : assetChecksum.hashCode) +
      (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
      (assetUrl == null ? 0 : assetUrl.hashCode) +
      clipId.hashCode +
      createdAt.hashCode +
      (errorMessage == null ? 0 : errorMessage.hashCode) +
      id.hashCode +
      platform.hashCode +
      (responsePayload == null ? 0 : responsePayload.hashCode) +
      status.hashCode +
      updatedAt.hashCode;

  factory PublishJobRead.fromJson(Map<String, dynamic> json) =>
      _$PublishJobReadFromJson(json);

  Map<String, dynamic> toJson() => _$PublishJobReadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
