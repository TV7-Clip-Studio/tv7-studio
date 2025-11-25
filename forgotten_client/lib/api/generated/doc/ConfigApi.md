# forgotten_client_api.api.ConfigApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getConfigApiV1ConfigGet**](ConfigApi.md#getconfigapiv1configget) | **GET** /api/v1/config | Get Config


# **getConfigApiV1ConfigGet**
> ConfigRead getConfigApiV1ConfigGet()

Get Config

Expose feature flags and limits for the Flutter client.

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getConfigApi();

try {
    final response = api.getConfigApiV1ConfigGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ConfigApi->getConfigApiV1ConfigGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ConfigRead**](ConfigRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

