# forgotten_client_api.api.AuthApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**loginApiV1AuthLoginPost**](AuthApi.md#loginapiv1authloginpost) | **POST** /api/v1/auth/login | Login
[**refreshTokenApiV1AuthRefreshPost**](AuthApi.md#refreshtokenapiv1authrefreshpost) | **POST** /api/v1/auth/refresh | Refresh Token


# **loginApiV1AuthLoginPost**
> Token loginApiV1AuthLoginPost(loginRequest)

Login

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAuthApi();
final LoginRequest loginRequest = ; // LoginRequest | 

try {
    final response = api.loginApiV1AuthLoginPost(loginRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->loginApiV1AuthLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**Token**](Token.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshTokenApiV1AuthRefreshPost**
> Token refreshTokenApiV1AuthRefreshPost(tokenRefreshRequest)

Refresh Token

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAuthApi();
final TokenRefreshRequest tokenRefreshRequest = ; // TokenRefreshRequest | 

try {
    final response = api.refreshTokenApiV1AuthRefreshPost(tokenRefreshRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->refreshTokenApiV1AuthRefreshPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenRefreshRequest** | [**TokenRefreshRequest**](TokenRefreshRequest.md)|  | 

### Return type

[**Token**](Token.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

