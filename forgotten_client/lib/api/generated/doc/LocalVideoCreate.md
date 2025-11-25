# forgotten_client_api.model.LocalVideoCreate

## Load the model package
```dart
import 'package:forgotten_client_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**sourceUrl** | **String** | Identifier for the local video (e.g., file:// or local://) | 
**localPath** | **String** |  | [optional] 
**originalFilename** | **String** |  | [optional] 
**uploadChecksum** | **String** |  | [optional] 
**uploadFileSizeBytes** | **int** |  | [optional] 
**durationSeconds** | **int** |  | [optional] 
**fileSizeBytes** | **int** |  | [optional] 
**transcriptText** | **String** |  | [optional] 
**transcriptLanguage** | **String** |  | [optional] 
**workspaceRoot** | **String** |  | [optional] 
**status** | [**VideoStatus**](VideoStatus.md) |  | [optional] [default to VideoStatus.ready]
**clipGenerationMode** | [**ClipGenerationMode**](ClipGenerationMode.md) |  | [optional] [default to ClipGenerationMode.replace]
**clips** | [**List&lt;ClipUpsert&gt;**](ClipUpsert.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


