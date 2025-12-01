# forgotten_client_api.api.AiApi

## Load the API package
```dart
import 'package:forgotten_client_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**executeApiV1AiExecutePost**](AiApi.md#executeapiv1aiexecutepost) | **POST** /api/v1/ai/execute | Execute
[**generateHighlightsApiV1AiHighlightsPost**](AiApi.md#generatehighlightsapiv1aihighlightspost) | **POST** /api/v1/ai/highlights | Generate Highlights


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

# **generateHighlightsApiV1AiHighlightsPost**
> HighlightResponse generateHighlightsApiV1AiHighlightsPost(highlightRequest)

Generate Highlights

### Example
```dart
import 'package:forgotten_client_api/api.dart';

final api = ForgottenClientApi().getAiApi();
final HighlightRequest highlightRequest = ; // HighlightRequest | 

try {
    final response = api.generateHighlightsApiV1AiHighlightsPost(highlightRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AiApi->generateHighlightsApiV1AiHighlightsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **highlightRequest** | [**HighlightRequest**](HighlightRequest.md)|  | 

### Return type

[**HighlightResponse**](HighlightResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

