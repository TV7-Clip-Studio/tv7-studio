import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for ClipsApi
void main() {
  final instance = ForgottenClientApi().getClipsApi();

  group(ClipsApi, () {
    // Update Clip
    //
    //Future<ClipRead> updateClipApiV1ClipsClipIdPatch(int clipId, ClipUpdateRequest clipUpdateRequest) async
    test('test updateClipApiV1ClipsClipIdPatch', () async {
      // TODO
    });
  });
}
