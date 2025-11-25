//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'asset_upload_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssetUploadResponse {
  /// Returns a new [AssetUploadResponse] instance.
  AssetUploadResponse({

    required  this.assetUrl,

    required  this.assetChecksum,

    required  this.assetSizeBytes,

     this.contentType,
  });

  @JsonKey(
    
    name: r'asset_url',
    required: true,
    
  )


  final String assetUrl;



  @JsonKey(
    
    name: r'asset_checksum',
    required: true,
    
  )


  final String assetChecksum;



  @JsonKey(
    
    name: r'asset_size_bytes',
    required: true,
    
  )


  final int assetSizeBytes;



  @JsonKey(
    
    name: r'content_type',
    required: false,
    
  )


  final String? contentType;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AssetUploadResponse &&
      other.assetUrl == assetUrl &&
      other.assetChecksum == assetChecksum &&
      other.assetSizeBytes == assetSizeBytes &&
      other.contentType == contentType;

    @override
    int get hashCode =>
        assetUrl.hashCode +
        assetChecksum.hashCode +
        assetSizeBytes.hashCode +
        (contentType == null ? 0 : contentType.hashCode);

  factory AssetUploadResponse.fromJson(Map<String, dynamic> json) => _$AssetUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssetUploadResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

