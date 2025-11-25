// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConfigReadCWProxy {
  ConfigRead publishingEnabled(bool publishingEnabled);

  ConfigRead assetUploadRequired(bool assetUploadRequired);

  ConfigRead allowedPlatforms(List<String> allowedPlatforms);

  ConfigRead maxAssetSizeBytes(int? maxAssetSizeBytes);

  ConfigRead maxVideoDurationSeconds(int? maxVideoDurationSeconds);

  ConfigRead publishModes(List<ConfigReadPublishModesEnum>? publishModes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConfigRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConfigRead(...).copyWith(id: 12, name: "My name")
  /// ````
  ConfigRead call({
    bool publishingEnabled,
    bool assetUploadRequired,
    List<String> allowedPlatforms,
    int? maxAssetSizeBytes,
    int? maxVideoDurationSeconds,
    List<ConfigReadPublishModesEnum>? publishModes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfConfigRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfConfigRead.copyWith.fieldName(...)`
class _$ConfigReadCWProxyImpl implements _$ConfigReadCWProxy {
  const _$ConfigReadCWProxyImpl(this._value);

  final ConfigRead _value;

  @override
  ConfigRead publishingEnabled(bool publishingEnabled) =>
      this(publishingEnabled: publishingEnabled);

  @override
  ConfigRead assetUploadRequired(bool assetUploadRequired) =>
      this(assetUploadRequired: assetUploadRequired);

  @override
  ConfigRead allowedPlatforms(List<String> allowedPlatforms) =>
      this(allowedPlatforms: allowedPlatforms);

  @override
  ConfigRead maxAssetSizeBytes(int? maxAssetSizeBytes) =>
      this(maxAssetSizeBytes: maxAssetSizeBytes);

  @override
  ConfigRead maxVideoDurationSeconds(int? maxVideoDurationSeconds) =>
      this(maxVideoDurationSeconds: maxVideoDurationSeconds);

  @override
  ConfigRead publishModes(List<ConfigReadPublishModesEnum>? publishModes) =>
      this(publishModes: publishModes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConfigRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConfigRead(...).copyWith(id: 12, name: "My name")
  /// ````
  ConfigRead call({
    Object? publishingEnabled = const $CopyWithPlaceholder(),
    Object? assetUploadRequired = const $CopyWithPlaceholder(),
    Object? allowedPlatforms = const $CopyWithPlaceholder(),
    Object? maxAssetSizeBytes = const $CopyWithPlaceholder(),
    Object? maxVideoDurationSeconds = const $CopyWithPlaceholder(),
    Object? publishModes = const $CopyWithPlaceholder(),
  }) {
    return ConfigRead(
      publishingEnabled: publishingEnabled == const $CopyWithPlaceholder()
          ? _value.publishingEnabled
          // ignore: cast_nullable_to_non_nullable
          : publishingEnabled as bool,
      assetUploadRequired: assetUploadRequired == const $CopyWithPlaceholder()
          ? _value.assetUploadRequired
          // ignore: cast_nullable_to_non_nullable
          : assetUploadRequired as bool,
      allowedPlatforms: allowedPlatforms == const $CopyWithPlaceholder()
          ? _value.allowedPlatforms
          // ignore: cast_nullable_to_non_nullable
          : allowedPlatforms as List<String>,
      maxAssetSizeBytes: maxAssetSizeBytes == const $CopyWithPlaceholder()
          ? _value.maxAssetSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : maxAssetSizeBytes as int?,
      maxVideoDurationSeconds:
          maxVideoDurationSeconds == const $CopyWithPlaceholder()
          ? _value.maxVideoDurationSeconds
          // ignore: cast_nullable_to_non_nullable
          : maxVideoDurationSeconds as int?,
      publishModes: publishModes == const $CopyWithPlaceholder()
          ? _value.publishModes
          // ignore: cast_nullable_to_non_nullable
          : publishModes as List<ConfigReadPublishModesEnum>?,
    );
  }
}

extension $ConfigReadCopyWith on ConfigRead {
  /// Returns a callable class that can be used as follows: `instanceOfConfigRead.copyWith(...)` or like so:`instanceOfConfigRead.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConfigReadCWProxy get copyWith => _$ConfigReadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigRead _$ConfigReadFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ConfigRead',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'publishing_enabled',
        'asset_upload_required',
        'allowed_platforms',
      ],
    );
    final val = ConfigRead(
      publishingEnabled: $checkedConvert(
        'publishing_enabled',
        (v) => v as bool,
      ),
      assetUploadRequired: $checkedConvert(
        'asset_upload_required',
        (v) => v as bool,
      ),
      allowedPlatforms: $checkedConvert(
        'allowed_platforms',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      maxAssetSizeBytes: $checkedConvert(
        'max_asset_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      maxVideoDurationSeconds: $checkedConvert(
        'max_video_duration_seconds',
        (v) => (v as num?)?.toInt(),
      ),
      publishModes: $checkedConvert(
        'publish_modes',
        (v) => (v as List<dynamic>?)
            ?.map((e) => $enumDecode(_$ConfigReadPublishModesEnumEnumMap, e))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'publishingEnabled': 'publishing_enabled',
    'assetUploadRequired': 'asset_upload_required',
    'allowedPlatforms': 'allowed_platforms',
    'maxAssetSizeBytes': 'max_asset_size_bytes',
    'maxVideoDurationSeconds': 'max_video_duration_seconds',
    'publishModes': 'publish_modes',
  },
);

Map<String, dynamic> _$ConfigReadToJson(ConfigRead instance) =>
    <String, dynamic>{
      'publishing_enabled': instance.publishingEnabled,
      'asset_upload_required': instance.assetUploadRequired,
      'allowed_platforms': instance.allowedPlatforms,
      'max_asset_size_bytes': instance.maxAssetSizeBytes,
      'max_video_duration_seconds': instance.maxVideoDurationSeconds,
      'publish_modes': instance.publishModes
          ?.map((e) => _$ConfigReadPublishModesEnumEnumMap[e]!)
          .toList(),
    };

const _$ConfigReadPublishModesEnumEnumMap = {
  ConfigReadPublishModesEnum.backendPublish: 'backend_publish',
  ConfigReadPublishModesEnum.localOnly: 'local_only',
};
