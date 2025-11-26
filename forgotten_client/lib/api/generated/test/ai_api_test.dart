import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for AiApi
void main() {
  final instance = ForgottenClientApi().getAiApi();

  group(AiApi, () {
    // Execute
    //
    //Future<AIResponse> executeApiV1AiExecutePost(AIRequest aIRequest) async
    test('test executeApiV1AiExecutePost', () async {
      // TODO
    });
  });
}
