import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Studio generated API does not expose Backend cloud AI execution', () {
    final generatedDir = Directory('lib/api/generated');
    if (!generatedDir.existsSync()) {
      return;
    }

    final generatedSource = generatedDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(generatedSource, isNot(contains('/api/v1/cloud-ai/engine/execute')));
    expect(generatedSource, isNot(contains('executeEngineCloudAi')));
  });
}
