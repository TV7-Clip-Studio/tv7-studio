import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

class ToolRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) {
    return Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
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
      runInShell: false,
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

  Future<Map<String, dynamic>> getMediaInfo(String path) async {
    final result = await run('ffprobe', [
      '-v',
      'quiet',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      path,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffprobe failed: \${result.stderr}');
    }

    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  }

  Future<void> generateThumbnail(String videoPath, String thumbnailPath) async {
    final result = await run('ffmpeg', [
      '-y', // Overwrite
      '-i',
      videoPath,
      '-ss',
      '00:00:01', // Capture at 1s
      '-vframes',
      '1',
      thumbnailPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffmpeg thumbnail failed: \${result.stderr}');
    }
  }
  Future<Map<String, dynamic>> getYouTubeMetadata(String url) async {
    final result = await run('yt-dlp', [
      '--dump-json',
      '--skip-download',
      url,
    ]);

    if (result.exitCode != 0) {
      throw Exception('yt-dlp metadata failed: ${result.stderr}');
    }

    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  }
}
