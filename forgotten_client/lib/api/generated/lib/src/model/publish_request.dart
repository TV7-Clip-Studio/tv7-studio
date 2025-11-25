//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publish_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishRequest {
  /// Returns a new [PublishRequest] instance.
  PublishRequest({

    required  this.platforms,

     this.assetUrl,

     this.assetChecksum,

     this.assetSizeBytes,
  });

  @JsonKey(
    
    name: r'platforms',
    required: true,
    
  )


  final List<String> platforms;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublishRequest &&
      other.platforms == platforms &&
      other.assetUrl == assetUrl &&
      other.assetChecksum == assetChecksum &&
      other.assetSizeBytes == assetSizeBytes;

    @override
    int get hashCode =>
        platforms.hashCode +
        (assetUrl == null ? 0 : assetUrl.hashCode) +
        (assetChecksum == null ? 0 : assetChecksum.hashCode) +
        (assetSizeBytes == null ? 0 : assetSizeBytes.hashCode);

  factory PublishRequest.fromJson(Map<String, dynamic> json) => _$PublishRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublishRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

