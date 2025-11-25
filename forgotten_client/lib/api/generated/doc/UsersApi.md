# forgotten_client_api.api.UsersApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createUserEndpointApiV1UsersPost**](UsersApi.md#createuserendpointapiv1userspost) | **POST** /api/v1/users/ | Create User Endpoint
[**listUsersEndpointApiV1UsersGet**](UsersApi.md#listusersendpointapiv1usersget) | **GET** /api/v1/users/ | List Users Endpoint


# **createUserEndpointApiV1UsersPost**
> UserRead createUserEndpointApiV1UsersPost(userCreate)

Create User Endpoint

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getUsersApi();
final UserCreate userCreate = ; // UserCreate | 

try {
    final response = api.createUserEndpointApiV1UsersPost(userCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->createUserEndpointApiV1UsersPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userCreate** | [**UserCreate**](UserCreate.md)|  | 

### Return type

[**UserRead**](UserRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUsersEndpointApiV1UsersGet**
> List<UserRead> listUsersEndpointApiV1UsersGet()

List Users Endpoint

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getUsersApi();

try {
    final response = api.listUsersEndpointApiV1UsersGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->listUsersEndpointApiV1UsersGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;UserRead&gt;**](UserRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

