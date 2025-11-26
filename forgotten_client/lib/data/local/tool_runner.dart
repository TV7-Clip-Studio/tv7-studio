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
      throw Exception(r'ffprobe failed: ${result.stderr}');
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
      throw Exception(r'ffmpeg thumbnail failed: ${result.stderr}');
    }
  }

  Future<Map<String, dynamic>> getYouTubeMetadata(String url) async {
    final result = await run('yt-dlp', ['--dump-json', '--skip-download', url]);

    if (result.exitCode != 0) {
      throw Exception('yt-dlp metadata failed: ${result.stderr}');
    }

    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  }

  Future<void> downloadTranscript(
    String url,
    String outputPath,
    String language,
  ) async {
    // yt-dlp will append .en.vtt to the output path if we don't be careful
    // We use -o to specify the base name
    final result = await run('yt-dlp', [
      '--write-auto-sub',
      '--sub-lang',
      language,
      '--sub-format',
      'vtt',
      '--skip-download',
      '-o',
      outputPath.replaceAll('.vtt', ''), // yt-dlp adds extension
      url,
    ]);

    if (result.exitCode != 0) {
      throw Exception('yt-dlp transcript failed: ${result.stderr}');
    }
  }

  Future<void> renderClip(
    String sourcePath,
    double start,
    double end,
    String outputPath,
  ) async {
    // Using re-encode for frame accuracy. -ss after -i is slower but accurate.
    final result = await run('ffmpeg', [
      '-y',
      '-i',
      sourcePath,
      '-ss',
      start.toString(),
      '-to',
      end.toString(),
      '-c:v',
      'libx264',
      '-c:a',
      'aac',
      outputPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffmpeg clip render failed: ${result.stderr}');
    }
  }
}
