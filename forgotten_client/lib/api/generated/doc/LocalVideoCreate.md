# forgotten_client_api.model.LocalVideoCreate

## Load the model package
```dart
import 'package:forgotten_client_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**clipGenerationMode** | [**ClipGenerationMode**](ClipGenerationMode.md) |  | [optional] [default to ClipGenerationMode.replace]
**clips** | [**List&lt;ClipUpsert&gt;**](ClipUpsert.md) |  | [optional] 
**durationSeconds** | **int** |  | [optional] 
**fileSizeBytes** | **int** |  | [optional] 
**localPath** | **String** |  | [optional] 
**metadataOnly** | **bool** | If true, server will not attempt to download or host the source video. | [optional] [default to false]
**originalFilename** | **String** |  | [optional] 
**sourceUrl** | **String** | Identifier for the local video (e.g., file:// or local://) | 
**status** | [**VideoStatus**](VideoStatus.md) |  | [optional] [default to VideoStatus.ready]
**title** | **String** |  | [optional] 
**transcriptLanguage** | **String** |  | [optional] 
**transcriptText** | **String** |  | [optional] 
**uploadChecksum** | **String** |  | [optional] 
**uploadFileSizeBytes** | **int** |  | [optional] 
**workspaceRoot** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


