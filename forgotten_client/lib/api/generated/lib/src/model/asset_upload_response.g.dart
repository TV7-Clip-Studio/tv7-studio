// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_upload_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AssetUploadResponseCWProxy {
  AssetUploadResponse assetChecksum(String assetChecksum);

  AssetUploadResponse assetSizeBytes(int assetSizeBytes);

  AssetUploadResponse assetUrl(String assetUrl);

  AssetUploadResponse contentType(String? contentType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssetUploadResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssetUploadResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  AssetUploadResponse call({
    String? assetChecksum,
    int? assetSizeBytes,
    String? assetUrl,
    String? contentType,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAssetUploadResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAssetUploadResponse.copyWith.fieldName(...)`
class _$AssetUploadResponseCWProxyImpl implements _$AssetUploadResponseCWProxy {
  const _$AssetUploadResponseCWProxyImpl(this._value);

  final AssetUploadResponse _value;

  @override
  AssetUploadResponse assetChecksum(String assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  AssetUploadResponse assetSizeBytes(int assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  AssetUploadResponse assetUrl(String assetUrl) => this(assetUrl: assetUrl);

  @override
  AssetUploadResponse contentType(String? contentType) =>
      this(contentType: contentType);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssetUploadResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssetUploadResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  AssetUploadResponse call({
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
  }) {
    return AssetUploadResponse(
      assetChecksum:
          assetChecksum == const $CopyWithPlaceholder() || assetChecksum == null
              ? _value.assetChecksum
              // ignore: cast_nullable_to_non_nullable
              : assetChecksum as String,
      assetSizeBytes: assetSizeBytes == const $CopyWithPlaceholder() ||
              assetSizeBytes == null
          ? _value.assetSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : assetSizeBytes as int,
      assetUrl: assetUrl == const $CopyWithPlaceholder() || assetUrl == null
          ? _value.assetUrl
          // ignore: cast_nullable_to_non_nullable
          : assetUrl as String,
      contentType: contentType == const $CopyWithPlaceholder()
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as String?,
    );
  }
}

extension $AssetUploadResponseCopyWith on AssetUploadResponse {
  /// Returns a callable class that can be used as follows: `instanceOfAssetUploadResponse.copyWith(...)` or like so:`instanceOfAssetUploadResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AssetUploadResponseCWProxy get copyWith =>
      _$AssetUploadResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetUploadResponse _$AssetUploadResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AssetUploadResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'asset_checksum',
            'asset_size_bytes',
            'asset_url'
          ],
        );
        final val = AssetUploadResponse(
          assetChecksum: $checkedConvert('asset_checksum', (v) => v as String),
          assetSizeBytes:
              $checkedConvert('asset_size_bytes', (v) => (v as num).toInt()),
          assetUrl: $checkedConvert('asset_url', (v) => v as String),
          contentType: $checkedConvert('content_type', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'assetChecksum': 'asset_checksum',
        'assetSizeBytes': 'asset_size_bytes',
        'assetUrl': 'asset_url',
        'contentType': 'content_type'
      },
    );

Map<String, dynamic> _$AssetUploadResponseToJson(AssetUploadResponse instance) {
  final val = <String, dynamic>{
    'asset_checksum': instance.assetChecksum,
    'asset_size_bytes': instance.assetSizeBytes,
    'asset_url': instance.assetUrl,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('content_type', instance.contentType);
  return val;
}
