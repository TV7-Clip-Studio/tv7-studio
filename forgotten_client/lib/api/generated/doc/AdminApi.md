# forgotten_client_api.api.AdminApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteUserEndpointAdminUsersUserIdDeletePost**](AdminApi.md#deleteuserendpointadminusersuseriddeletepost) | **POST** /admin/users/{user_id}/delete | Delete User Endpoint
[**deleteVideoAdminVideosVideoIdDeletePost**](AdminApi.md#deletevideoadminvideosvideoiddeletepost) | **POST** /admin/videos/{video_id}/delete | Delete Video
[**ingestFromDashboardAdminVideosIngestPost**](AdminApi.md#ingestfromdashboardadminvideosingestpost) | **POST** /admin/videos/ingest | Ingest From Dashboard
[**loginFormAdminLoginGet**](AdminApi.md#loginformadminloginget) | **GET** /admin/login | Login Form
[**loginSubmitAdminLoginPost**](AdminApi.md#loginsubmitadminloginpost) | **POST** /admin/login | Login Submit
[**logoutAdminLogoutPost**](AdminApi.md#logoutadminlogoutpost) | **POST** /admin/logout | Logout
[**requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost**](AdminApi.md#requestmorehighlightsadminvideosvideoidmorehighlightspost) | **POST** /admin/videos/{video_id}/more-highlights | Request More Highlights
[**toggleUserStatusAdminUsersUserIdToggleStatusPost**](AdminApi.md#toggleuserstatusadminusersuseridtogglestatuspost) | **POST** /admin/users/{user_id}/toggle-status | Toggle User Status
[**userDetailPageAdminUsersUserIdGet**](AdminApi.md#userdetailpageadminusersuseridget) | **GET** /admin/users/{user_id} | User Detail Page
[**usersDashboardAdminUsersGet**](AdminApi.md#usersdashboardadminusersget) | **GET** /admin/users | Users Dashboard
[**videoDetailAdminVideosVideoIdGet**](AdminApi.md#videodetailadminvideosvideoidget) | **GET** /admin/videos/{video_id} | Video Detail
[**videoStatusJsonAdminVideosVideoIdStatusGet**](AdminApi.md#videostatusjsonadminvideosvideoidstatusget) | **GET** /admin/videos/{video_id}/status | Video Status Json
[**videosDashboardAdminVideosGet**](AdminApi.md#videosdashboardadminvideosget) | **GET** /admin/videos | Videos Dashboard
[**youtubeCallbackAdminYoutubeCallbackGet**](AdminApi.md#youtubecallbackadminyoutubecallbackget) | **GET** /admin/youtube/callback | Youtube Callback
[**youtubeConnectAdminYoutubeConnectGet**](AdminApi.md#youtubeconnectadminyoutubeconnectget) | **GET** /admin/youtube/connect | Youtube Connect
[**youtubeDisconnectAdminYoutubeDisconnectPost**](AdminApi.md#youtubedisconnectadminyoutubedisconnectpost) | **POST** /admin/youtube/disconnect | Youtube Disconnect


# **deleteUserEndpointAdminUsersUserIdDeletePost**
> Object deleteUserEndpointAdminUsersUserIdDeletePost(userId)

Delete User Endpoint

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int userId = 56; // int | 

try {
    final response = api.deleteUserEndpointAdminUsersUserIdDeletePost(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->deleteUserEndpointAdminUsersUserIdDeletePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteVideoAdminVideosVideoIdDeletePost**
> Object deleteVideoAdminVideosVideoIdDeletePost(videoId)

Delete Video

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int videoId = 56; // int | 

try {
    final response = api.deleteVideoAdminVideosVideoIdDeletePost(videoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->deleteVideoAdminVideosVideoIdDeletePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **videoId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ingestFromDashboardAdminVideosIngestPost**
> Object ingestFromDashboardAdminVideosIngestPost()

Ingest From Dashboard

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.ingestFromDashboardAdminVideosIngestPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->ingestFromDashboardAdminVideosIngestPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginFormAdminLoginGet**
> String loginFormAdminLoginGet()

Login Form

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.loginFormAdminLoginGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->loginFormAdminLoginGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginSubmitAdminLoginPost**
> Object loginSubmitAdminLoginPost(email, password)

Login Submit

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final String email = email_example; // String | 
final String password = password_example; // String | 

try {
    final response = api.loginSubmitAdminLoginPost(email, password);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->loginSubmitAdminLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **email** | **String**|  | 
 **password** | **String**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/x-www-form-urlencoded
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logoutAdminLogoutPost**
> Object logoutAdminLogoutPost()

Logout

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.logoutAdminLogoutPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->logoutAdminLogoutPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost**
> Object requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost(videoId)

Request More Highlights

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int videoId = 56; // int | 

try {
    final response = api.requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost(videoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **videoId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **toggleUserStatusAdminUsersUserIdToggleStatusPost**
> Object toggleUserStatusAdminUsersUserIdToggleStatusPost(userId)

Toggle User Status

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int userId = 56; // int | 

try {
    final response = api.toggleUserStatusAdminUsersUserIdToggleStatusPost(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->toggleUserStatusAdminUsersUserIdToggleStatusPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userDetailPageAdminUsersUserIdGet**
> String userDetailPageAdminUsersUserIdGet(userId)

User Detail Page

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int userId = 56; // int | 

try {
    final response = api.userDetailPageAdminUsersUserIdGet(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->userDetailPageAdminUsersUserIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersDashboardAdminUsersGet**
> String usersDashboardAdminUsersGet()

Users Dashboard

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.usersDashboardAdminUsersGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->usersDashboardAdminUsersGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **videoDetailAdminVideosVideoIdGet**
> String videoDetailAdminVideosVideoIdGet(videoId)

Video Detail

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int videoId = 56; // int | 

try {
    final response = api.videoDetailAdminVideosVideoIdGet(videoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->videoDetailAdminVideosVideoIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **videoId** | **int**|  | 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **videoStatusJsonAdminVideosVideoIdStatusGet**
> Object videoStatusJsonAdminVideosVideoIdStatusGet(videoId)

Video Status Json

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final int videoId = 56; // int | 

try {
    final response = api.videoStatusJsonAdminVideosVideoIdStatusGet(videoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->videoStatusJsonAdminVideosVideoIdStatusGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **videoId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **videosDashboardAdminVideosGet**
> String videosDashboardAdminVideosGet()

Videos Dashboard

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.videosDashboardAdminVideosGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->videosDashboardAdminVideosGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **youtubeCallbackAdminYoutubeCallbackGet**
> Object youtubeCallbackAdminYoutubeCallbackGet(state, code, error)

Youtube Callback

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();
final String state = state_example; // String | 
final String code = code_example; // String | 
final String error = error_example; // String | 

try {
    final response = api.youtubeCallbackAdminYoutubeCallbackGet(state, code, error);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->youtubeCallbackAdminYoutubeCallbackGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **state** | **String**|  | [optional] 
 **code** | **String**|  | [optional] 
 **error** | **String**|  | [optional] 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **youtubeConnectAdminYoutubeConnectGet**
> Object youtubeConnectAdminYoutubeConnectGet()

Youtube Connect

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.youtubeConnectAdminYoutubeConnectGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->youtubeConnectAdminYoutubeConnectGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **youtubeDisconnectAdminYoutubeDisconnectPost**
> Object youtubeDisconnectAdminYoutubeDisconnectPost()

Youtube Disconnect

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAdminApi();

try {
    final response = api.youtubeDisconnectAdminYoutubeDisconnectPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminApi->youtubeDisconnectAdminYoutubeDisconnectPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

