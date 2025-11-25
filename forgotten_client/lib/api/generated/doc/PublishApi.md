# forgotten_client_api.api.PublishApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listPublishJobsApiV1ClipsClipIdPublishGet**](PublishApi.md#listpublishjobsapiv1clipsclipidpublishget) | **GET** /api/v1/clips/{clip_id}/publish | List Publish Jobs
[**publishClipApiV1ClipsClipIdPublishPost**](PublishApi.md#publishclipapiv1clipsclipidpublishpost) | **POST** /api/v1/clips/{clip_id}/publish | Publish Clip


# **listPublishJobsApiV1ClipsClipIdPublishGet**
> List<PublishJobRead> listPublishJobsApiV1ClipsClipIdPublishGet(clipId)

List Publish Jobs

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getPublishApi();
final int clipId = 56; // int | 

try {
    final response = api.listPublishJobsApiV1ClipsClipIdPublishGet(clipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PublishApi->listPublishJobsApiV1ClipsClipIdPublishGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **clipId** | **int**|  | 

### Return type

[**List&lt;PublishJobRead&gt;**](PublishJobRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publishClipApiV1ClipsClipIdPublishPost**
> List<PublishJobRead> publishClipApiV1ClipsClipIdPublishPost(clipId, publishRequest)

Publish Clip

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getPublishApi();
final int clipId = 56; // int | 
final PublishRequest publishRequest = ; // PublishRequest | 

try {
    final response = api.publishClipApiV1ClipsClipIdPublishPost(clipId, publishRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PublishApi->publishClipApiV1ClipsClipIdPublishPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **clipId** | **int**|  | 
 **publishRequest** | [**PublishRequest**](PublishRequest.md)|  | 

### Return type

[**List&lt;PublishJobRead&gt;**](PublishJobRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

