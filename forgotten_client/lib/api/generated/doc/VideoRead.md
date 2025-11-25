# forgotten_client_api.model.VideoRead

## Load the model package
```dart
import 'package:forgotten_client_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | 
**sourceUrl** | **String** |  | 
**localPath** | **String** |  | 
**ingestType** | [**VideoIngestType**](VideoIngestType.md) |  | 
**originalFilename** | **String** |  | [optional] 
**uploadChecksum** | **String** |  | [optional] 
**uploadFileSizeBytes** | **int** |  | [optional] 
**transcriptText** | **String** |  | 
**transcriptLanguage** | **String** |  | [optional] 
**durationSeconds** | **int** |  | [optional] 
**fileSizeBytes** | **int** |  | [optional] 
**errorMessage** | **String** |  | [optional] 
**workspaceRoot** | **String** |  | [optional] 
**status** | [**VideoStatus**](VideoStatus.md) |  | 
**clipGenerationMode** | [**ClipGenerationMode**](ClipGenerationMode.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**requestedByUserId** | **int** |  | [optional] 
**clips** | [**List&lt;ClipRead&gt;**](ClipRead.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


