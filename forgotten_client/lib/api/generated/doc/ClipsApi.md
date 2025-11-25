# forgotten_client_api.api.ClipsApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**updateClipApiV1ClipsClipIdPatch**](ClipsApi.md#updateclipapiv1clipsclipidpatch) | **PATCH** /api/v1/clips/{clip_id} | Update Clip


# **updateClipApiV1ClipsClipIdPatch**
> ClipRead updateClipApiV1ClipsClipIdPatch(clipId, clipUpdateRequest)

Update Clip

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getClipsApi();
final int clipId = 56; // int | 
final ClipUpdateRequest clipUpdateRequest = ; // ClipUpdateRequest | 

try {
    final response = api.updateClipApiV1ClipsClipIdPatch(clipId, clipUpdateRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ClipsApi->updateClipApiV1ClipsClipIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **clipId** | **int**|  | 
 **clipUpdateRequest** | [**ClipUpdateRequest**](ClipUpdateRequest.md)|  | 

### Return type

[**ClipRead**](ClipRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

