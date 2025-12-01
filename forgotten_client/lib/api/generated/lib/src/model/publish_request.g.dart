// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishRequestCWProxy {
  PublishRequest assetChecksum(String? assetChecksum);

  PublishRequest assetSizeBytes(int? assetSizeBytes);

  PublishRequest assetUrl(String? assetUrl);

  PublishRequest platforms(List<String> platforms);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishRequest call({
    String? assetChecksum,
    int? assetSizeBytes,
    String? assetUrl,
    List<String>? platforms,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublishRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublishRequest.copyWith.fieldName(...)`
class _$PublishRequestCWProxyImpl implements _$PublishRequestCWProxy {
  const _$PublishRequestCWProxyImpl(this._value);

  final PublishRequest _value;

  @override
  PublishRequest assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  PublishRequest assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  PublishRequest assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  PublishRequest platforms(List<String> platforms) =>
      this(platforms: platforms);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishRequest call({
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? platforms = const $CopyWithPlaceholder(),
  }) {
    return PublishRequest(
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
      platforms: platforms == const $CopyWithPlaceholder() || platforms == null
          ? _value.platforms
          // ignore: cast_nullable_to_non_nullable
          : platforms as List<String>,
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
        $checkKeys(
          json,
          requiredKeys: const ['platforms'],
        );
        final val = PublishRequest(
          assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
          assetSizeBytes:
              $checkedConvert('asset_size_bytes', (v) => (v as num?)?.toInt()),
          assetUrl: $checkedConvert('asset_url', (v) => v as String?),
          platforms: $checkedConvert('platforms',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'assetChecksum': 'asset_checksum',
        'assetSizeBytes': 'asset_size_bytes',
        'assetUrl': 'asset_url'
      },
    );

Map<String, dynamic> _$PublishRequestToJson(PublishRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('asset_checksum', instance.assetChecksum);
  writeNotNull('asset_size_bytes', instance.assetSizeBytes);
  writeNotNull('asset_url', instance.assetUrl);
  val['platforms'] = instance.platforms;
  return val;
}
