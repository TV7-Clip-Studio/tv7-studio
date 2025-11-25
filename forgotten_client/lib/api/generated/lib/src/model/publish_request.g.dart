// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishRequestCWProxy {
  PublishRequest platforms(List<String> platforms);

  PublishRequest assetUrl(String? assetUrl);

  PublishRequest assetChecksum(String? assetChecksum);

  PublishRequest assetSizeBytes(int? assetSizeBytes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishRequest call({
    List<String> platforms,
    String? assetUrl,
    String? assetChecksum,
    int? assetSizeBytes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublishRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublishRequest.copyWith.fieldName(...)`
class _$PublishRequestCWProxyImpl implements _$PublishRequestCWProxy {
  const _$PublishRequestCWProxyImpl(this._value);

  final PublishRequest _value;

  @override
  PublishRequest platforms(List<String> platforms) =>
      this(platforms: platforms);

  @override
  PublishRequest assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  PublishRequest assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  PublishRequest assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishRequest call({
    Object? platforms = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
  }) {
    return PublishRequest(
      platforms: platforms == const $CopyWithPlaceholder()
          ? _value.platforms
          // ignore: cast_nullable_to_non_nullable
          : platforms as List<String>,
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
    );
  }
}

extension $PublishRequestCopyWith on PublishRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPublishRequest.copyWith(...)` or like so:`instanceOfPublishRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublishRequestCWProxy get copyWith => _$PublishRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishRequest _$PublishRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublishRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['platforms']);
        final val = PublishRequest(
          platforms: $checkedConvert(
            'platforms',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          assetUrl: $checkedConvert('asset_url', (v) => v as String?),
          assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
          assetSizeBytes: $checkedConvert(
            'asset_size_bytes',
            (v) => (v as num?)?.toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'assetUrl': 'asset_url',
        'assetChecksum': 'asset_checksum',
        'assetSizeBytes': 'asset_size_bytes',
      },
    );

Map<String, dynamic> _$PublishRequestToJson(PublishRequest instance) =>
    <String, dynamic>{
      'platforms': instance.platforms,
      'asset_url': instance.assetUrl,
      'asset_checksum': instance.assetChecksum,
      'asset_size_bytes': instance.assetSizeBytes,
    };
