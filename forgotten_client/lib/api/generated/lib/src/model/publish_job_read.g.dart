// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_job_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishJobReadCWProxy {
  PublishJobRead assetChecksum(String? assetChecksum);

  PublishJobRead assetSizeBytes(int? assetSizeBytes);

  PublishJobRead assetUrl(String? assetUrl);

  PublishJobRead clipId(int clipId);

  PublishJobRead createdAt(DateTime createdAt);

  PublishJobRead errorMessage(String? errorMessage);

  PublishJobRead id(int id);

  PublishJobRead platform(String platform);

  PublishJobRead responsePayload(String? responsePayload);

  PublishJobRead status(PublishJobStatus status);

  PublishJobRead updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishJobRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishJobRead(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishJobRead call({
    String? assetChecksum,
    int? assetSizeBytes,
    String? assetUrl,
    int? clipId,
    DateTime? createdAt,
    String? errorMessage,
    int? id,
    String? platform,
    String? responsePayload,
    PublishJobStatus? status,
    DateTime? updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublishJobRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublishJobRead.copyWith.fieldName(...)`
class _$PublishJobReadCWProxyImpl implements _$PublishJobReadCWProxy {
  const _$PublishJobReadCWProxyImpl(this._value);

  final PublishJobRead _value;

  @override
  PublishJobRead assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  PublishJobRead assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  PublishJobRead assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  PublishJobRead clipId(int clipId) => this(clipId: clipId);

  @override
  PublishJobRead createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  PublishJobRead errorMessage(String? errorMessage) =>
      this(errorMessage: errorMessage);

  @override
  PublishJobRead id(int id) => this(id: id);

  @override
  PublishJobRead platform(String platform) => this(platform: platform);

  @override
  PublishJobRead responsePayload(String? responsePayload) =>
      this(responsePayload: responsePayload);

  @override
  PublishJobRead status(PublishJobStatus status) => this(status: status);

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
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? clipId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? errorMessage = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? responsePayload = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return PublishJobRead(
      assetChecksum: assetChecksum == const $CopyWithPlaceholder()
          ? _value.assetChecksum
          // ignore: cast_nullable_to_non_nullable
          : assetChecksum as String?,
      assetSizeBytes: assetSizeBytes == const $CopyWithPlaceholder()
          ? _value.assetSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : assetSizeBytes as int?,
      assetUrl: assetUrl == const $CopyWithPlaceholder()
          ? _value.assetUrl
          // ignore: cast_nullable_to_non_nullable
          : assetUrl as String?,
      clipId: clipId == const $CopyWithPlaceholder() || clipId == null
          ? _value.clipId
          // ignore: cast_nullable_to_non_nullable
          : clipId as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      errorMessage: errorMessage == const $CopyWithPlaceholder()
          ? _value.errorMessage
          // ignore: cast_nullable_to_non_nullable
          : errorMessage as String?,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String,
      responsePayload: responsePayload == const $CopyWithPlaceholder()
          ? _value.responsePayload
          // ignore: cast_nullable_to_non_nullable
          : responsePayload as String?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PublishJobStatus,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
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
            'clip_id',
            'created_at',
            'id',
            'platform',
            'status',
            'updated_at'
          ],
        );
        final val = PublishJobRead(
          assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
          assetSizeBytes:
              $checkedConvert('asset_size_bytes', (v) => (v as num?)?.toInt()),
          assetUrl: $checkedConvert('asset_url', (v) => v as String?),
          clipId: $checkedConvert('clip_id', (v) => (v as num).toInt()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          errorMessage: $checkedConvert('error_message', (v) => v as String?),
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          platform: $checkedConvert('platform', (v) => v as String),
          responsePayload:
              $checkedConvert('response_payload', (v) => v as String?),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$PublishJobStatusEnumMap, v)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'assetChecksum': 'asset_checksum',
        'assetSizeBytes': 'asset_size_bytes',
        'assetUrl': 'asset_url',
        'clipId': 'clip_id',
        'createdAt': 'created_at',
        'errorMessage': 'error_message',
        'responsePayload': 'response_payload',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$PublishJobReadToJson(PublishJobRead instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('asset_checksum', instance.assetChecksum);
  writeNotNull('asset_size_bytes', instance.assetSizeBytes);
  writeNotNull('asset_url', instance.assetUrl);
  val['clip_id'] = instance.clipId;
  val['created_at'] = instance.createdAt.toIso8601String();
  writeNotNull('error_message', instance.errorMessage);
  val['id'] = instance.id;
  val['platform'] = instance.platform;
  writeNotNull('response_payload', instance.responsePayload);
  val['status'] = _$PublishJobStatusEnumMap[instance.status]!;
  val['updated_at'] = instance.updatedAt.toIso8601String();
  return val;
}

const _$PublishJobStatusEnumMap = {
  PublishJobStatus.pending: 'pending',
  PublishJobStatus.queued: 'queued',
  PublishJobStatus.publishing: 'publishing',
  PublishJobStatus.partial: 'partial',
  PublishJobStatus.complete: 'complete',
  PublishJobStatus.failed: 'failed',
};
