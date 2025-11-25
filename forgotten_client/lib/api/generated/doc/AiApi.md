# forgotten_client_api.api.AiApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**executeApiV1AiExecutePost**](AiApi.md#executeapiv1aiexecutepost) | **POST** /api/v1/ai/execute | Execute


# **executeApiV1AiExecutePost**
> AIResponse executeApiV1AiExecutePost(aIRequest)

Execute

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAiApi();
final AIRequest aIRequest = ; // AIRequest | 

try {
    final response = api.executeApiV1AiExecutePost(aIRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AiApi->executeApiV1AiExecutePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **aIRequest** | [**AIRequest**](AIRequest.md)|  | 

### Return type

[**AIResponse**](AIResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

