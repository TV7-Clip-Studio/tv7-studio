import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

class ToolRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) {
    return Process.run(executable, args, workingDirectory: workingDirectory);
  }

  Stream<String> runStream(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async* {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
    );

    final outputStream = StreamGroup.merge([
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()),
    ]);

    yield* outputStream;

    final code = await process.exitCode;
    if (code != 0) {
      throw ProcessException(executable, args, 'Exit code $code', code);
    }
  }
}
