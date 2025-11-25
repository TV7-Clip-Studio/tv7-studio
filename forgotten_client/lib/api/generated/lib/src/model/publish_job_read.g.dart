// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_job_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishJobReadCWProxy {
  PublishJobRead id(int id);

  PublishJobRead clipId(int clipId);

  PublishJobRead platform(String platform);

  PublishJobRead status(PublishJobStatus status);

  PublishJobRead assetUrl(String? assetUrl);

  PublishJobRead assetChecksum(String? assetChecksum);

  PublishJobRead assetSizeBytes(int? assetSizeBytes);

  PublishJobRead responsePayload(String? responsePayload);

  PublishJobRead errorMessage(String? errorMessage);

  PublishJobRead createdAt(DateTime createdAt);

  PublishJobRead updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishJobRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishJobRead(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishJobRead call({
    int id,
    int clipId,
    String platform,
    PublishJobStatus status,
    String? assetUrl,
    String? assetChecksum,
    int? assetSizeBytes,
    String? responsePayload,
    String? errorMessage,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublishJobRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublishJobRead.copyWith.fieldName(...)`
class _$PublishJobReadCWProxyImpl implements _$PublishJobReadCWProxy {
  const _$PublishJobReadCWProxyImpl(this._value);

  final PublishJobRead _value;

  @override
  PublishJobRead id(int id) => this(id: id);

  @override
  PublishJobRead clipId(int clipId) => this(clipId: clipId);

  @override
  PublishJobRead platform(String platform) => this(platform: platform);

  @override
  PublishJobRead status(PublishJobStatus status) => this(status: status);

  @override
  PublishJobRead assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  PublishJobRead assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  PublishJobRead assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  PublishJobRead responsePayload(String? responsePayload) =>
      this(responsePayload: responsePayload);

  @override
  PublishJobRead errorMessage(String? errorMessage) =>
      this(errorMessage: errorMessage);

  @override
  PublishJobRead createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  PublishJobRead updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishJobRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishJobRead(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishJobRead call({
    Object? id = const $CopyWithPlaceholder(),
    Object? clipId = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? responsePayload = const $CopyWithPlaceholder(),
    Object? errorMessage = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return PublishJobRead(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      clipId: clipId == const $CopyWithPlaceholder()
          ? _value.clipId
          // ignore: cast_nullable_to_non_nullable
          : clipId as int,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PublishJobStatus,
      assetUrl: assetUrl == const $CopyWithPlaceholder()
          ? _value.assetUrl
          // ignore: cast_nullable_to_non_nullable
          : assetUrl as String?,
      assetChecksum: assetChecksum == const $CopyWithPlaceholder()
          ? _value.assetChecksum
          // ignore: cast_nullable_to_non_nullable
          : assetChecksum as String?,
      assetSizeBytes: assetSizeBytes == const $CopyWithPlaceholder()
          ? _value.assetSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : assetSizeBytes as int?,
      responsePayload: responsePayload == const $CopyWithPlaceholder()
          ? _value.responsePayload
          // ignore: cast_nullable_to_non_nullable
          : responsePayload as String?,
      errorMessage: errorMessage == const $CopyWithPlaceholder()
          ? _value.errorMessage
          // ignore: cast_nullable_to_non_nullable
          : errorMessage as String?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $PublishJobReadCopyWith on PublishJobRead {
  /// Returns a callable class that can be used as follows: `instanceOfPublishJobRead.copyWith(...)` or like so:`instanceOfPublishJobRead.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublishJobReadCWProxy get copyWith => _$PublishJobReadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishJobRead _$PublishJobReadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublishJobRead',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'clip_id',
            'platform',
            'status',
            'created_at',
            'updated_at',
          ],
        );
        final val = PublishJobRead(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          clipId: $checkedConvert('clip_id', (v) => (v as num).toInt()),
          platform: $checkedConvert('platform', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$PublishJobStatusEnumMap, v),
          ),
          assetUrl: $checkedConvert('asset_url', (v) => v as String?),
          assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
          assetSizeBytes: $checkedConvert(
            'asset_size_bytes',
            (v) => (v as num?)?.toInt(),
          ),
          responsePayload: $checkedConvert(
            'response_payload',
            (v) => v as String?,
          ),
          errorMessage: $checkedConvert('error_message', (v) => v as String?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'clipId': 'clip_id',
        'assetUrl': 'asset_url',
        'assetChecksum': 'asset_checksum',
        'assetSizeBytes': 'asset_size_bytes',
        'responsePayload': 'response_payload',
        'errorMessage': 'error_message',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$PublishJobReadToJson(PublishJobRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clip_id': instance.clipId,
      'platform': instance.platform,
      'status': _$PublishJobStatusEnumMap[instance.status]!,
      'asset_url': instance.assetUrl,
      'asset_checksum': instance.assetChecksum,
      'asset_size_bytes': instance.assetSizeBytes,
      'response_payload': instance.responsePayload,
      'error_message': instance.errorMessage,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$PublishJobStatusEnumMap = {
  PublishJobStatus.pending: 'pending',
  PublishJobStatus.queued: 'queued',
  PublishJobStatus.publishing: 'publishing',
  PublishJobStatus.partial: 'partial',
  PublishJobStatus.complete: 'complete',
  PublishJobStatus.failed: 'failed',
};
