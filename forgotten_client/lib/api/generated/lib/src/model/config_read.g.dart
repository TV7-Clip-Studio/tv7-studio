// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_read.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConfigReadCWProxy {
  ConfigRead allowedPlatforms(List<String> allowedPlatforms);

  ConfigRead assetUploadRequired(bool assetUploadRequired);

  ConfigRead highlightsEnabled(bool? highlightsEnabled);

  ConfigRead maxAssetSizeBytes(int? maxAssetSizeBytes);

  ConfigRead maxVideoDurationSeconds(int? maxVideoDurationSeconds);

  ConfigRead openaiMode(ConfigReadOpenaiModeEnum? openaiMode);

  ConfigRead publishModes(List<ConfigReadPublishModesEnum>? publishModes);

  ConfigRead publishingEnabled(bool publishingEnabled);

  ConfigRead schedulingEnabled(bool? schedulingEnabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConfigRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConfigRead(...).copyWith(id: 12, name: "My name")
  /// ````
  ConfigRead call({
    List<String>? allowedPlatforms,
    bool? assetUploadRequired,
    bool? highlightsEnabled,
    int? maxAssetSizeBytes,
    int? maxVideoDurationSeconds,
    ConfigReadOpenaiModeEnum? openaiMode,
    List<ConfigReadPublishModesEnum>? publishModes,
    bool? publishingEnabled,
    bool? schedulingEnabled,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfConfigRead.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfConfigRead.copyWith.fieldName(...)`
class _$ConfigReadCWProxyImpl implements _$ConfigReadCWProxy {
  const _$ConfigReadCWProxyImpl(this._value);

  final ConfigRead _value;

  @override
  ConfigRead allowedPlatforms(List<String> allowedPlatforms) =>
      this(allowedPlatforms: allowedPlatforms);

  @override
  ConfigRead assetUploadRequired(bool assetUploadRequired) =>
      this(assetUploadRequired: assetUploadRequired);

  @override
  ConfigRead highlightsEnabled(bool? highlightsEnabled) =>
      this(highlightsEnabled: highlightsEnabled);

  @override
  ConfigRead maxAssetSizeBytes(int? maxAssetSizeBytes) =>
      this(maxAssetSizeBytes: maxAssetSizeBytes);

  @override
  ConfigRead maxVideoDurationSeconds(int? maxVideoDurationSeconds) =>
      this(maxVideoDurationSeconds: maxVideoDurationSeconds);

  @override
  ConfigRead openaiMode(ConfigReadOpenaiModeEnum? openaiMode) =>
      this(openaiMode: openaiMode);

  @override
  ConfigRead publishModes(List<ConfigReadPublishModesEnum>? publishModes) =>
      this(publishModes: publishModes);

  @override
  ConfigRead publishingEnabled(bool publishingEnabled) =>
      this(publishingEnabled: publishingEnabled);

  @override
  ConfigRead schedulingEnabled(bool? schedulingEnabled) =>
      this(schedulingEnabled: schedulingEnabled);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConfigRead(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConfigRead(...).copyWith(id: 12, name: "My name")
  /// ````
  ConfigRead call({
    Object? allowedPlatforms = const $CopyWithPlaceholder(),
    Object? assetUploadRequired = const $CopyWithPlaceholder(),
    Object? highlightsEnabled = const $CopyWithPlaceholder(),
    Object? maxAssetSizeBytes = const $CopyWithPlaceholder(),
    Object? maxVideoDurationSeconds = const $CopyWithPlaceholder(),
    Object? openaiMode = const $CopyWithPlaceholder(),
    Object? publishModes = const $CopyWithPlaceholder(),
    Object? publishingEnabled = const $CopyWithPlaceholder(),
    Object? schedulingEnabled = const $CopyWithPlaceholder(),
  }) {
    return ConfigRead(
      allowedPlatforms: allowedPlatforms == const $CopyWithPlaceholder() ||
              allowedPlatforms == null
          ? _value.allowedPlatforms
          // ignore: cast_nullable_to_non_nullable
          : allowedPlatforms as List<String>,
      assetUploadRequired:
          assetUploadRequired == const $CopyWithPlaceholder() ||
                  assetUploadRequired == null
              ? _value.assetUploadRequired
              // ignore: cast_nullable_to_non_nullable
              : assetUploadRequired as bool,
      highlightsEnabled: highlightsEnabled == const $CopyWithPlaceholder()
          ? _value.highlightsEnabled
          // ignore: cast_nullable_to_non_nullable
          : highlightsEnabled as bool?,
      maxAssetSizeBytes: maxAssetSizeBytes == const $CopyWithPlaceholder()
          ? _value.maxAssetSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : maxAssetSizeBytes as int?,
      maxVideoDurationSeconds:
          maxVideoDurationSeconds == const $CopyWithPlaceholder()
              ? _value.maxVideoDurationSeconds
              // ignore: cast_nullable_to_non_nullable
              : maxVideoDurationSeconds as int?,
      openaiMode: openaiMode == const $CopyWithPlaceholder()
          ? _value.openaiMode
          // ignore: cast_nullable_to_non_nullable
          : openaiMode as ConfigReadOpenaiModeEnum?,
      publishModes: publishModes == const $CopyWithPlaceholder()
          ? _value.publishModes
          // ignore: cast_nullable_to_non_nullable
          : publishModes as List<ConfigReadPublishModesEnum>?,
      publishingEnabled: publishingEnabled == const $CopyWithPlaceholder() ||
              publishingEnabled == null
          ? _value.publishingEnabled
          // ignore: cast_nullable_to_non_nullable
          : publishingEnabled as bool,
      schedulingEnabled: schedulingEnabled == const $CopyWithPlaceholder()
          ? _value.schedulingEnabled
          // ignore: cast_nullable_to_non_nullable
          : schedulingEnabled as bool?,
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
            'allowed_platforms',
            'asset_upload_required',
            'publishing_enabled'
          ],
        );
        final val = ConfigRead(
          allowedPlatforms: $checkedConvert('allowed_platforms',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          assetUploadRequired:
              $checkedConvert('asset_upload_required', (v) => v as bool),
          highlightsEnabled:
              $checkedConvert('highlights_enabled', (v) => v as bool? ?? true),
          maxAssetSizeBytes: $checkedConvert(
              'max_asset_size_bytes', (v) => (v as num?)?.toInt()),
          maxVideoDurationSeconds: $checkedConvert(
              'max_video_duration_seconds', (v) => (v as num?)?.toInt()),
          openaiMode: $checkedConvert(
              'openai_mode',
              (v) =>
                  $enumDecodeNullable(_$ConfigReadOpenaiModeEnumEnumMap, v) ??
                  ConfigReadOpenaiModeEnum.backend),
          publishModes: $checkedConvert(
              'publish_modes',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      $enumDecode(_$ConfigReadPublishModesEnumEnumMap, e))
                  .toList()),
          publishingEnabled:
              $checkedConvert('publishing_enabled', (v) => v as bool),
          schedulingEnabled:
              $checkedConvert('scheduling_enabled', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {
        'allowedPlatforms': 'allowed_platforms',
        'assetUploadRequired': 'asset_upload_required',
        'highlightsEnabled': 'highlights_enabled',
        'maxAssetSizeBytes': 'max_asset_size_bytes',
        'maxVideoDurationSeconds': 'max_video_duration_seconds',
        'openaiMode': 'openai_mode',
        'publishModes': 'publish_modes',
        'publishingEnabled': 'publishing_enabled',
        'schedulingEnabled': 'scheduling_enabled'
      },
    );

Map<String, dynamic> _$ConfigReadToJson(ConfigRead instance) {
  final val = <String, dynamic>{
    'allowed_platforms': instance.allowedPlatforms,
    'asset_upload_required': instance.assetUploadRequired,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('highlights_enabled', instance.highlightsEnabled);
  writeNotNull('max_asset_size_bytes', instance.maxAssetSizeBytes);
  writeNotNull('max_video_duration_seconds', instance.maxVideoDurationSeconds);
  writeNotNull(
      'openai_mode', _$ConfigReadOpenaiModeEnumEnumMap[instance.openaiMode]);
  writeNotNull(
      'publish_modes',
      instance.publishModes
          ?.map((e) => _$ConfigReadPublishModesEnumEnumMap[e]!)
          .toList());
  val['publishing_enabled'] = instance.publishingEnabled;
  writeNotNull('scheduling_enabled', instance.schedulingEnabled);
  return val;
}

const _$ConfigReadOpenaiModeEnumEnumMap = {
  ConfigReadOpenaiModeEnum.backend: 'backend',
  ConfigReadOpenaiModeEnum.clientSupplied: 'client_supplied',
  ConfigReadOpenaiModeEnum.disabled: 'disabled',
};

const _$ConfigReadPublishModesEnumEnumMap = {
  ConfigReadPublishModesEnum.backendPublish: 'backend_publish',
  ConfigReadPublishModesEnum.localOnly: 'local_only',
};
