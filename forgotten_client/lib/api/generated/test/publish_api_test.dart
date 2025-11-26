import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for PublishApi
void main() {
  final instance = ForgottenClientApi().getPublishApi();

  group(PublishApi, () {
    // List Publish Jobs
    //
    //Future<List<PublishJobRead>> listPublishJobsApiV1ClipsClipIdPublishGet(int clipId) async
    test('test listPublishJobsApiV1ClipsClipIdPublishGet', () async {
      // TODO
    });

    // Publish Clip
    //
    //Future<List<PublishJobRead>> publishClipApiV1ClipsClipIdPublishPost(int clipId, PublishRequest publishRequest) async
    test('test publishClipApiV1ClipsClipIdPublishPost', () async {
      // TODO
    });
  });
}
