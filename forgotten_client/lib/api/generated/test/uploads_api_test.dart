import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for UploadsApi
void main() {
  final instance = ForgottenClientApi().getUploadsApi();

  group(UploadsApi, () {
    // Upload Asset
    //
    // Accept multipart asset upload from Flutter; store under MEDIA_STORAGE_DIR.
    //
    //Future<AssetUploadResponse> uploadAssetApiV1UploadsAssetsPost(MultipartFile file) async
    test('test uploadAssetApiV1UploadsAssetsPost', () async {
      // TODO
    });
  });
}
