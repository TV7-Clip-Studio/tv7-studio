//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clip_update_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClipUpdateRequest {
  /// Returns a new [ClipUpdateRequest] instance.
  ClipUpdateRequest({

     this.assetUrl,

     this.assetChecksum,

     this.assetSizeBytes,

     this.renderWidth,

     this.renderHeight,

     this.frameRate,

     this.fileSizeBytes,

     this.captionText,

     this.readyLocalOnly,
  });

  @JsonKey(
    
    name: r'asset_url',
    required: false,
    
  )


  final String? assetUrl;



  @JsonKey(
    
    name: r'asset_checksum',
    required: false,
    
  )


  final String? assetChecksum;



  @JsonKey(
    
    name: r'asset_size_bytes',
    required: false,
    
  )


  final int? assetSizeBytes;



  @JsonKey(
    
    name: r'render_width',
    required: false,
    
  )


  final int? renderWidth;



  @JsonKey(
    
    name: r'render_height',
    required: false,
    
  )


  final int? renderHeight;



  @JsonKey(
    
    name: r'frame_rate',
    required: false,
    
  )


  final num? frameRate;



  @JsonKey(
    
    name: r'file_size_bytes',
    required: false,
    
  )


  final int? fileSizeBytes;



  @JsonKey(
    
    name: r'caption_text',
    required: false,
    
  )


  final String? captionText;



  @JsonKey(
    
    name: r'ready_local_only',
    required: false,
    
  )


  final bool? readyLocalOnly;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClipUpdateRequest &&
      other.assetUrl == assetUrl &&
      other.assetChecksum == assetChecksum &&
      other.assetSizeBytes == assetSizeBytes &&
      other.renderWidth == renderWidth &&
      other.renderHeight == renderHeight &&
      other.frameRate == frameRate &&
      other.fileSizeBytes == fileSizeBytes &&
      other.captionText == captionText &&
      other.readyLocalOnly == readyLocalOnly;

    @override
    int get hashCode =>
        (assetUrl == null ? 0 : assetUrl.hashCode) +
        (assetChecksum == null ? 0 : assetChecksum.hashCode) +
        (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode) +
        (renderWidth == null ? 0 : renderWidth.hashCode) +
        (renderHeight == null ? 0 : renderHeight.hashCode) +
        (frameRate == null ? 0 : frameRate.hashCode) +
        (fileSizeBytes == null ? 0 : fileSizeBytes.hashCode) +
        (captionText == null ? 0 : captionText.hashCode) +
        (readyLocalOnly == null ? 0 : readyLocalOnly.hashCode);

  factory ClipUpdateRequest.fromJson(Map<String, dynamic> json) => _$ClipUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClipUpdateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

