// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_update_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClipUpdateRequestCWProxy {
  ClipUpdateRequest assetUrl(String? assetUrl);

  ClipUpdateRequest assetChecksum(String? assetChecksum);

  ClipUpdateRequest assetSizeBytes(int? assetSizeBytes);

  ClipUpdateRequest renderWidth(int? renderWidth);

  ClipUpdateRequest renderHeight(int? renderHeight);

  ClipUpdateRequest frameRate(num? frameRate);

  ClipUpdateRequest fileSizeBytes(int? fileSizeBytes);

  ClipUpdateRequest captionText(String? captionText);

  ClipUpdateRequest readyLocalOnly(bool? readyLocalOnly);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClipUpdateRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClipUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ClipUpdateRequest call({
    String? assetUrl,
    String? assetChecksum,
    int? assetSizeBytes,
    int? renderWidth,
    int? renderHeight,
    num? frameRate,
    int? fileSizeBytes,
    String? captionText,
    bool? readyLocalOnly,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClipUpdateRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClipUpdateRequest.copyWith.fieldName(...)`
class _$ClipUpdateRequestCWProxyImpl implements _$ClipUpdateRequestCWProxy {
  const _$ClipUpdateRequestCWProxyImpl(this._value);

  final ClipUpdateRequest _value;

  @override
  ClipUpdateRequest assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  ClipUpdateRequest assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  ClipUpdateRequest assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  ClipUpdateRequest renderWidth(int? renderWidth) =>
      this(renderWidth: renderWidth);

  @override
  ClipUpdateRequest renderHeight(int? renderHeight) =>
      this(renderHeight: renderHeight);

  @override
  ClipUpdateRequest frameRate(num? frameRate) => this(frameRate: frameRate);

  @override
  ClipUpdateRequest fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  ClipUpdateRequest captionText(String? captionText) =>
      this(captionText: captionText);

  @override
  ClipUpdateRequest readyLocalOnly(bool? readyLocalOnly) =>
      this(readyLocalOnly: readyLocalOnly);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClipUpdateRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClipUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ClipUpdateRequest call({
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? renderWidth = const $CopyWithPlaceholder(),
    Object? renderHeight = const $CopyWithPlaceholder(),
    Object? frameRate = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? captionText = const $CopyWithPlaceholder(),
    Object? readyLocalOnly = const $CopyWithPlaceholder(),
  }) {
    return ClipUpdateRequest(
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
      captionText: captionText == const $CopyWithPlaceholder()
          ? _value.captionText
          // ignore: cast_nullable_to_non_nullable
          : captionText as String?,
      readyLocalOnly: readyLocalOnly == const $CopyWithPlaceholder()
          ? _value.readyLocalOnly
          // ignore: cast_nullable_to_non_nullable
          : readyLocalOnly as bool?,
    );
  }
}

extension $ClipUpdateRequestCopyWith on ClipUpdateRequest {
  /// Returns a callable class that can be used as follows: `instanceOfClipUpdateRequest.copyWith(...)` or like so:`instanceOfClipUpdateRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClipUpdateRequestCWProxy get copyWith =>
      _$ClipUpdateRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClipUpdateRequest _$ClipUpdateRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ClipUpdateRequest',
  json,
  ($checkedConvert) {
    final val = ClipUpdateRequest(
      assetUrl: $checkedConvert('asset_url', (v) => v as String?),
      assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
      assetSizeBytes: $checkedConvert(
        'asset_size_bytes',
        (v) => (v as num?)?.toInt(),
      ),
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
      captionText: $checkedConvert('caption_text', (v) => v as String?),
      readyLocalOnly: $checkedConvert('ready_local_only', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'assetUrl': 'asset_url',
    'assetChecksum': 'asset_checksum',
    'assetSizeBytes': 'asset_size_bytes',
    'renderWidth': 'render_width',
    'renderHeight': 'render_height',
    'frameRate': 'frame_rate',
    'fileSizeBytes': 'file_size_bytes',
    'captionText': 'caption_text',
    'readyLocalOnly': 'ready_local_only',
  },
);

Map<String, dynamic> _$ClipUpdateRequestToJson(ClipUpdateRequest instance) =>
    <String, dynamic>{
      'asset_url': instance.assetUrl,
      'asset_checksum': instance.assetChecksum,
      'asset_size_bytes': instance.assetSizeBytes,
      'render_width': instance.renderWidth,
      'render_height': instance.renderHeight,
      'frame_rate': instance.frameRate,
      'file_size_bytes': instance.fileSizeBytes,
      'caption_text': instance.captionText,
      'ready_local_only': instance.readyLocalOnly,
    };
