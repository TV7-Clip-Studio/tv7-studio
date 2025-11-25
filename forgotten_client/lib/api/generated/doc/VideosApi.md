# forgotten_client_api.api.VideosApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getVideoStatusApiV1VideosVideoIdGet**](VideosApi.md#getvideostatusapiv1videosvideoidget) | **GET** /api/v1/videos/{video_id} | Get Video Status
[**ingestUploadEndpointApiV1VideosIngestUploadPost**](VideosApi.md#ingestuploadendpointapiv1videosingestuploadpost) | **POST** /api/v1/videos/ingest/upload | Ingest Upload Endpoint
[**ingestYoutubeEndpointApiV1VideosIngestYoutubePost**](VideosApi.md#ingestyoutubeendpointapiv1videosingestyoutubepost) | **POST** /api/v1/videos/ingest/youtube | Ingest Youtube Endpoint
[**registerLocalVideoApiV1VideosLocalPost**](VideosApi.md#registerlocalvideoapiv1videoslocalpost) | **POST** /api/v1/videos/local | Register Local Video


# **getVideoStatusApiV1VideosVideoIdGet**
> VideoRead getVideoStatusApiV1VideosVideoIdGet(videoId)

Get Video Status

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getVideosApi();
final int videoId = 56; // int | 

try {
    final response = api.getVideoStatusApiV1VideosVideoIdGet(videoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling VideosApi->getVideoStatusApiV1VideosVideoIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **videoId** | **int**|  | 

### Return type

[**VideoRead**](VideoRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ingestUploadEndpointApiV1VideosIngestUploadPost**
> VideoIngestResponse ingestUploadEndpointApiV1VideosIngestUploadPost(file, appendClips)

Ingest Upload Endpoint

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getVideosApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 
final bool appendClips = true; // bool | 

try {
    final response = api.ingestUploadEndpointApiV1VideosIngestUploadPost(file, appendClips);
    print(response);
} catch on DioException (e) {
    print('Exception when calling VideosApi->ingestUploadEndpointApiV1VideosIngestUploadPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | 
 **appendClips** | **bool**|  | [optional] [default to false]

### Return type

[**VideoIngestResponse**](VideoIngestResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ingestYoutubeEndpointApiV1VideosIngestYoutubePost**
> VideoIngestResponse ingestYoutubeEndpointApiV1VideosIngestYoutubePost(youTubeIngestRequest)

Ingest Youtube Endpoint

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getVideosApi();
final YouTubeIngestRequest youTubeIngestRequest = ; // YouTubeIngestRequest | 

try {
    final response = api.ingestYoutubeEndpointApiV1VideosIngestYoutubePost(youTubeIngestRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling VideosApi->ingestYoutubeEndpointApiV1VideosIngestYoutubePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **youTubeIngestRequest** | [**YouTubeIngestRequest**](YouTubeIngestRequest.md)|  | 

### Return type

[**VideoIngestResponse**](VideoIngestResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerLocalVideoApiV1VideosLocalPost**
> VideoRead registerLocalVideoApiV1VideosLocalPost(localVideoCreate)

Register Local Video

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getVideosApi();
final LocalVideoCreate localVideoCreate = ; // LocalVideoCreate | 

try {
    final response = api.registerLocalVideoApiV1VideosLocalPost(localVideoCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling VideosApi->registerLocalVideoApiV1VideosLocalPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **localVideoCreate** | [**LocalVideoCreate**](LocalVideoCreate.md)|  | 

### Return type

[**VideoRead**](VideoRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

