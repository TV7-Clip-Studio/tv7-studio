// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_upsert.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClipUpsertCWProxy {
  ClipUpsert startSec(int startSec);

  ClipUpsert endSec(int endSec);

  ClipUpsert localPath(String? localPath);

  ClipUpsert assetUrl(String? assetUrl);

  ClipUpsert assetChecksum(String? assetChecksum);

  ClipUpsert assetSizeBytes(int? assetSizeBytes);

  ClipUpsert readyLocalOnly(bool? readyLocalOnly);

  ClipUpsert captionText(String? captionText);

  ClipUpsert renderWidth(int? renderWidth);

  ClipUpsert renderHeight(int? renderHeight);

  ClipUpsert frameRate(num? frameRate);

  ClipUpsert fileSizeBytes(int? fileSizeBytes);

  ClipUpsert status(ClipStatus? status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClipUpsert(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClipUpsert(...).copyWith(id: 12, name: "My name")
  /// ````
  ClipUpsert call({
    int startSec,
    int endSec,
    String? localPath,
    String? assetUrl,
    String? assetChecksum,
    int? assetSizeBytes,
    bool? readyLocalOnly,
    String? captionText,
    int? renderWidth,
    int? renderHeight,
    num? frameRate,
    int? fileSizeBytes,
    ClipStatus? status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClipUpsert.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClipUpsert.copyWith.fieldName(...)`
class _$ClipUpsertCWProxyImpl implements _$ClipUpsertCWProxy {
  const _$ClipUpsertCWProxyImpl(this._value);

  final ClipUpsert _value;

  @override
  ClipUpsert startSec(int startSec) => this(startSec: startSec);

  @override
  ClipUpsert endSec(int endSec) => this(endSec: endSec);

  @override
  ClipUpsert localPath(String? localPath) => this(localPath: localPath);

  @override
  ClipUpsert assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  ClipUpsert assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  ClipUpsert assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  ClipUpsert readyLocalOnly(bool? readyLocalOnly) =>
      this(readyLocalOnly: readyLocalOnly);

  @override
  ClipUpsert captionText(String? captionText) => this(captionText: captionText);

  @override
  ClipUpsert renderWidth(int? renderWidth) => this(renderWidth: renderWidth);

  @override
  ClipUpsert renderHeight(int? renderHeight) =>
      this(renderHeight: renderHeight);

  @override
  ClipUpsert frameRate(num? frameRate) => this(frameRate: frameRate);

  @override
  ClipUpsert fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  ClipUpsert status(ClipStatus? status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClipUpsert(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClipUpsert(...).copyWith(id: 12, name: "My name")
  /// ````
  ClipUpsert call({
    Object? startSec = const $CopyWithPlaceholder(),
    Object? endSec = const $CopyWithPlaceholder(),
    Object? localPath = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? readyLocalOnly = const $CopyWithPlaceholder(),
    Object? captionText = const $CopyWithPlaceholder(),
    Object? renderWidth = const $CopyWithPlaceholder(),
    Object? renderHeight = const $CopyWithPlaceholder(),
    Object? frameRate = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return ClipUpsert(
      startSec: startSec == const $CopyWithPlaceholder()
          ? _value.startSec
          // ignore: cast_nullable_to_non_nullable
          : startSec as int,
      endSec: endSec == const $CopyWithPlaceholder()
          ? _value.endSec
          // ignore: cast_nullable_to_non_nullable
          : endSec as int,
      localPath: localPath == const $CopyWithPlaceholder()
          ? _value.localPath
          // ignore: cast_nullable_to_non_nullable
          : localPath as String?,
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
      readyLocalOnly: readyLocalOnly == const $CopyWithPlaceholder()
          ? _value.readyLocalOnly
          // ignore: cast_nullable_to_non_nullable
          : readyLocalOnly as bool?,
      captionText: captionText == const $CopyWithPlaceholder()
          ? _value.captionText
          // ignore: cast_nullable_to_non_nullable
          : captionText as String?,
      renderWidth: renderWidth == const $CopyWithPlaceholder()
          ? _value.renderWidth
          // ignore: cast_nullable_to_non_nullable
          : renderWidth as int?,
      renderHeight: renderHeight == const $CopyWithPlaceholder()
          ? _value.renderHeight
          // ignore: cast_nullable_to_non_nullable
          : renderHeight as int?,
      frameRate: frameRate == const $CopyWithPlaceholder()
          ? _value.frameRate
          // ignore: cast_nullable_to_non_nullable
          : frameRate as num?,
      fileSizeBytes: fileSizeBytes == const $CopyWithPlaceholder()
          ? _value.fileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : fileSizeBytes as int?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ClipStatus?,
    );
  }
}

extension $ClipUpsertCopyWith on ClipUpsert {
  /// Returns a callable class that can be used as follows: `instanceOfClipUpsert.copyWith(...)` or like so:`instanceOfClipUpsert.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClipUpsertCWProxy get copyWith => _$ClipUpsertCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClipUpsert _$ClipUpsertFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ClipUpsert',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['start_sec', 'end_sec']);
    final val = ClipUpsert(
      startSec: $checkedConvert('start_sec', (v) => (v as num).toInt()),
      endSec: $checkedConvert('end_sec', (v) => (v as num).toInt()),
      localPath: $checkedConvert('local_path', (v) => v as String?),
      assetUrl: $checkedConvert('asset_url', (v) => v as String?),
      assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
      assetSizeBytes: $checkedConvert(
        'asset_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      readyLocalOnly: $checkedConvert(
        'ready_local_only',
        (v) => v as bool? ?? false,
      ),
      captionText: $checkedConvert('caption_text', (v) => v as String?),
      renderWidth: $checkedConvert('render_width', (v) => (v as num?)?.toInt()),
      renderHeight: $checkedConvert(
        'render_height',
        (v) => (v as num?)?.toInt(),
      ),
      frameRate: $checkedConvert('frame_rate', (v) => v as num?),
      fileSizeBytes: $checkedConvert(
        'file_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecodeNullable(_$ClipStatusEnumMap, v) ?? ClipStatus.ready,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'startSec': 'start_sec',
    'endSec': 'end_sec',
    'localPath': 'local_path',
    'assetUrl': 'asset_url',
    'assetChecksum': 'asset_checksum',
    'assetSizeBytes': 'asset_size_bytes',
    'readyLocalOnly': 'ready_local_only',
    'captionText': 'caption_text',
    'renderWidth': 'render_width',
    'renderHeight': 'render_height',
    'frameRate': 'frame_rate',
    'fileSizeBytes': 'file_size_bytes',
  },
);

Map<String, dynamic> _$ClipUpsertToJson(ClipUpsert instance) =>
    <String, dynamic>{
      'start_sec': instance.startSec,
      'end_sec': instance.endSec,
      'local_path': instance.localPath,
      'asset_url': instance.assetUrl,
      'asset_checksum': instance.assetChecksum,
      'asset_size_bytes': instance.assetSizeBytes,
      'ready_local_only': instance.readyLocalOnly,
      'caption_text': instance.captionText,
      'render_width': instance.renderWidth,
      'render_height': instance.renderHeight,
      'frame_rate': instance.frameRate,
      'file_size_bytes': instance.fileSizeBytes,
      'status': _$ClipStatusEnumMap[instance.status],
    };

const _$ClipStatusEnumMap = {
  ClipStatus.rendering: 'rendering',
  ClipStatus.ready: 'ready',
  ClipStatus.publishedPartial: 'published_partial',
  ClipStatus.publishedAll: 'published_all',
  ClipStatus.error: 'error',
};
