// @dart=3.4
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_update_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClipUpdateRequestCWProxy {
  ClipUpdateRequest assetChecksum(String? assetChecksum);

  ClipUpdateRequest assetSizeBytes(int? assetSizeBytes);

  ClipUpdateRequest assetUrl(String? assetUrl);

  ClipUpdateRequest captionText(String? captionText);

  ClipUpdateRequest fileSizeBytes(int? fileSizeBytes);

  ClipUpdateRequest frameRate(num? frameRate);

  ClipUpdateRequest readyLocalOnly(bool? readyLocalOnly);

  ClipUpdateRequest renderHeight(int? renderHeight);

  ClipUpdateRequest renderWidth(int? renderWidth);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClipUpdateRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClipUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ClipUpdateRequest call({
    String? assetChecksum,
    int? assetSizeBytes,
    String? assetUrl,
    String? captionText,
    int? fileSizeBytes,
    num? frameRate,
    bool? readyLocalOnly,
    int? renderHeight,
    int? renderWidth,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClipUpdateRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClipUpdateRequest.copyWith.fieldName(...)`
class _$ClipUpdateRequestCWProxyImpl implements _$ClipUpdateRequestCWProxy {
  const _$ClipUpdateRequestCWProxyImpl(this._value);

  final ClipUpdateRequest _value;

  @override
  ClipUpdateRequest assetChecksum(String? assetChecksum) =>
      this(assetChecksum: assetChecksum);

  @override
  ClipUpdateRequest assetSizeBytes(int? assetSizeBytes) =>
      this(assetSizeBytes: assetSizeBytes);

  @override
  ClipUpdateRequest assetUrl(String? assetUrl) => this(assetUrl: assetUrl);

  @override
  ClipUpdateRequest captionText(String? captionText) =>
      this(captionText: captionText);

  @override
  ClipUpdateRequest fileSizeBytes(int? fileSizeBytes) =>
      this(fileSizeBytes: fileSizeBytes);

  @override
  ClipUpdateRequest frameRate(num? frameRate) => this(frameRate: frameRate);

  @override
  ClipUpdateRequest readyLocalOnly(bool? readyLocalOnly) =>
      this(readyLocalOnly: readyLocalOnly);

  @override
  ClipUpdateRequest renderHeight(int? renderHeight) =>
      this(renderHeight: renderHeight);

  @override
  ClipUpdateRequest renderWidth(int? renderWidth) =>
      this(renderWidth: renderWidth);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClipUpdateRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClipUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ClipUpdateRequest call({
    Object? assetChecksum = const $CopyWithPlaceholder(),
    Object? assetSizeBytes = const $CopyWithPlaceholder(),
    Object? assetUrl = const $CopyWithPlaceholder(),
    Object? captionText = const $CopyWithPlaceholder(),
    Object? fileSizeBytes = const $CopyWithPlaceholder(),
    Object? frameRate = const $CopyWithPlaceholder(),
    Object? readyLocalOnly = const $CopyWithPlaceholder(),
    Object? renderHeight = const $CopyWithPlaceholder(),
    Object? renderWidth = const $CopyWithPlaceholder(),
  }) {
    return ClipUpdateRequest(
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
      captionText: captionText == const $CopyWithPlaceholder()
          ? _value.captionText
          // ignore: cast_nullable_to_non_nullable
          : captionText as String?,
      fileSizeBytes: fileSizeBytes == const $CopyWithPlaceholder()
          ? _value.fileSizeBytes
          // ignore: cast_nullable_to_non_nullable
          : fileSizeBytes as int?,
      frameRate: frameRate == const $CopyWithPlaceholder()
          ? _value.frameRate
          // ignore: cast_nullable_to_non_nullable
          : frameRate as num?,
      readyLocalOnly: readyLocalOnly == const $CopyWithPlaceholder()
          ? _value.readyLocalOnly
          // ignore: cast_nullable_to_non_nullable
          : readyLocalOnly as bool?,
      renderHeight: renderHeight == const $CopyWithPlaceholder()
          ? _value.renderHeight
          // ignore: cast_nullable_to_non_nullable
          : renderHeight as int?,
      renderWidth: renderWidth == const $CopyWithPlaceholder()
          ? _value.renderWidth
          // ignore: cast_nullable_to_non_nullable
          : renderWidth as int?,
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

ClipUpdateRequest _$ClipUpdateRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ClipUpdateRequest',
      json,
      ($checkedConvert) {
        final val = ClipUpdateRequest(
          assetChecksum: $checkedConvert('asset_checksum', (v) => v as String?),
          assetSizeBytes:
              $checkedConvert('asset_size_bytes', (v) => (v as num?)?.toInt()),
          assetUrl: $checkedConvert('asset_url', (v) => v as String?),
          captionText: $checkedConvert('caption_text', (v) => v as String?),
          fileSizeBytes:
              $checkedConvert('file_size_bytes', (v) => (v as num?)?.toInt()),
          frameRate: $checkedConvert('frame_rate', (v) => v as num?),
          readyLocalOnly:
              $checkedConvert('ready_local_only', (v) => v as bool?),
          renderHeight:
              $checkedConvert('render_height', (v) => (v as num?)?.toInt()),
          renderWidth:
              $checkedConvert('render_width', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'assetChecksum': 'asset_checksum',
        'assetSizeBytes': 'asset_size_bytes',
        'assetUrl': 'asset_url',
        'captionText': 'caption_text',
        'fileSizeBytes': 'file_size_bytes',
        'frameRate': 'frame_rate',
        'readyLocalOnly': 'ready_local_only',
        'renderHeight': 'render_height',
        'renderWidth': 'render_width'
      },
    );

Map<String, dynamic> _$ClipUpdateRequestToJson(ClipUpdateRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('asset_checksum', instance.assetChecksum);
  writeNotNull('asset_size_bytes', instance.assetSizeBytes);
  writeNotNull('asset_url', instance.assetUrl);
  writeNotNull('caption_text', instance.captionText);
  writeNotNull('file_size_bytes', instance.fileSizeBytes);
  writeNotNull('frame_rate', instance.frameRate);
  writeNotNull('ready_local_only', instance.readyLocalOnly);
  writeNotNull('render_height', instance.renderHeight);
  writeNotNull('render_width', instance.renderWidth);
  return val;
}
