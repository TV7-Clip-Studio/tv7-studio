# forgotten_client_api.api.DefaultApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthHealthGet**](DefaultApi.md#healthhealthget) | **GET** /health | Health
[**metricsMetricsGet**](DefaultApi.md#metricsmetricsget) | **GET** /metrics | Metrics
[**readyzReadyzGet**](DefaultApi.md#readyzreadyzget) | **GET** /readyz | Readyz
[**versionVersionGet**](DefaultApi.md#versionversionget) | **GET** /version | Version


# **healthHealthGet**
> Map<String, String> healthHealthGet()

Health

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getDefaultApi();

try {
    final response = api.healthHealthGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->healthHealthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map&lt;String, String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **metricsMetricsGet**
> Object metricsMetricsGet()

Metrics

Endpoint that serves Prometheus metrics.

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getDefaultApi();

try {
    final response = api.metricsMetricsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->metricsMetricsGet: $e\n');
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

# **readyzReadyzGet**
> Map<String, String> readyzReadyzGet()

Readyz

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getDefaultApi();

try {
    final response = api.readyzReadyzGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->readyzReadyzGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map&lt;String, String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **versionVersionGet**
> Map<String, String> versionVersionGet()

Version

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getDefaultApi();

try {
    final response = api.versionVersionGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->versionVersionGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map&lt;String, String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

