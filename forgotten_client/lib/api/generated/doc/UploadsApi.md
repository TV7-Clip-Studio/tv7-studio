# forgotten_client_api.api.UploadsApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**uploadAssetApiV1UploadsAssetsPost**](UploadsApi.md#uploadassetapiv1uploadsassetspost) | **POST** /api/v1/uploads/assets | Upload Asset


# **uploadAssetApiV1UploadsAssetsPost**
> AssetUploadResponse uploadAssetApiV1UploadsAssetsPost(file)

Upload Asset

Accept multipart asset upload from Flutter; store under MEDIA_STORAGE_DIR.

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getUploadsApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.uploadAssetApiV1UploadsAssetsPost(file);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UploadsApi->uploadAssetApiV1UploadsAssetsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | 

### Return type

[**AssetUploadResponse**](AssetUploadResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

