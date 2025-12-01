# forgotten_client_api.api.AuthApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**activateLicenseApiV1AuthActivatePost**](AuthApi.md#activatelicenseapiv1authactivatepost) | **POST** /api/v1/auth/activate | Activate License
[**getLicenseApiV1AuthLicenseGet**](AuthApi.md#getlicenseapiv1authlicenseget) | **GET** /api/v1/auth/license | Get License
[**loginApiV1AuthLoginPost**](AuthApi.md#loginapiv1authloginpost) | **POST** /api/v1/auth/login | Login
[**refreshLicenseApiV1AuthLicenseRefreshPost**](AuthApi.md#refreshlicenseapiv1authlicenserefreshpost) | **POST** /api/v1/auth/license/refresh | Refresh License
[**refreshTokenApiV1AuthRefreshPost**](AuthApi.md#refreshtokenapiv1authrefreshpost) | **POST** /api/v1/auth/refresh | Refresh Token
[**registerApiV1AuthRegisterPost**](AuthApi.md#registerapiv1authregisterpost) | **POST** /api/v1/auth/register | Register


# **activateLicenseApiV1AuthActivatePost**
> LicenseStatus activateLicenseApiV1AuthActivatePost(activateLicenseRequest)

Activate License

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAuthApi();
final ActivateLicenseRequest activateLicenseRequest = ; // ActivateLicenseRequest | 

try {
    final response = api.activateLicenseApiV1AuthActivatePost(activateLicenseRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->activateLicenseApiV1AuthActivatePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **activateLicenseRequest** | [**ActivateLicenseRequest**](ActivateLicenseRequest.md)|  | 

### Return type

[**LicenseStatus**](LicenseStatus.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLicenseApiV1AuthLicenseGet**
> LicenseStatus getLicenseApiV1AuthLicenseGet()

Get License

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAuthApi();

try {
    final response = api.getLicenseApiV1AuthLicenseGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->getLicenseApiV1AuthLicenseGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**LicenseStatus**](LicenseStatus.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **refreshLicenseApiV1AuthLicenseRefreshPost**
> LicenseStatus refreshLicenseApiV1AuthLicenseRefreshPost()

Refresh License

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAuthApi();

try {
    final response = api.refreshLicenseApiV1AuthLicenseRefreshPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->refreshLicenseApiV1AuthLicenseRefreshPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**LicenseStatus**](LicenseStatus.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
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

# **registerApiV1AuthRegisterPost**
> Token registerApiV1AuthRegisterPost(userCreate)

Register

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAuthApi();
final UserCreate userCreate = ; // UserCreate | 

try {
    final response = api.registerApiV1AuthRegisterPost(userCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->registerApiV1AuthRegisterPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userCreate** | [**UserCreate**](UserCreate.md)|  | 

### Return type

[**Token**](Token.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

