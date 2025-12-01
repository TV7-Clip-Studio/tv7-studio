// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:io';

import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  MediaService({required this.toolRunner});

  final ToolRunner toolRunner;

  Future<Directory> get _workspace async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final workspace = Directory(p.join(appDocDir.path, 'forgotten_workspace'));
    if (!await workspace.exists()) {
      await workspace.create(recursive: true);
    }
    return workspace;
  }

  Future<File> prepareIngestFromUrl(
    String url, {
    void Function(String)? onLog,
  }) async {
    final workspace = await _workspace;
    // Use base name without extension, let yt-dlp add the correct one
    final filename = 'download_${DateTime.now().millisecondsSinceEpoch}';
    final outputPath = p.join(workspace.path, filename);

    onLog?.call('Starting download...');

    final collected = <String>[];
    final stream = toolRunner.runStream('yt-dlp', [
      '--ignore-config',
      '--no-progress',
      '--no-cache-dir',
      '-f',
      'bv*[height<=720]+ba/b[height<=720]/best',
      '-o',
      outputPath,
      url,
    ]);

    try {
      await for (final line in stream) {
        collected.add(line);
        onLog?.call(line);
      }
    } on ProcessException catch (e) {
      final tail = collected.length > 10
          ? collected.sublist(collected.length - 10).join('\n')
          : collected.join('\n');
      // Preserve failure shape for callers/tests expecting ProcessException.
      throw ProcessException(
        e.executable,
        e.arguments,
        'yt-dlp failed (exit ${e.errorCode}): ${e.message}\n$tail',
        e.errorCode,
      );
    }

    // Find the actual file created (yt-dlp adds extension)
    File? actualFile;
    try {
      final files = workspace.listSync();
      // Find file that starts with our base name and is a video
      actualFile = files.whereType<File>().firstWhere(
        (f) =>
            p.basename(f.path).startsWith(filename) &&
            !f.path.endsWith('.part') &&
            !f.path.endsWith('.ytdl'),
        orElse: () => File(outputPath), // Fallback
      );
    } catch (e) {
      onLog?.call('Error finding downloaded file: $e');
      actualFile = File(outputPath);
    }

    // Save metadata using the ACTUAL filename
    onLog?.call('Fetching metadata...');
    try {
      final meta = await toolRunner.getYouTubeMetadata(url);
      final metaFile = File('${actualFile.path}.meta.json');
      await metaFile.writeAsString(jsonEncode(meta));
      onLog?.call('Metadata saved to ${metaFile.path}');
    } catch (e) {
      onLog?.call('Failed to save metadata: $e');
    }

    onLog?.call('Downloading transcript...');
    // Transcript should use the base name so it matches the expected pattern.
    // Repo expects: videoPath (minus extension) + .en.vtt
    // If video is foo.webm, repo looks for foo.en.vtt
    // So we download to outputPath (which is 'foo')
    try {
      await toolRunner.downloadTranscript(url, outputPath, 'en');
      onLog?.call('Transcript downloaded.');
    } catch (e) {
      onLog?.call('Transcript download failed: $e');
    }

    return actualFile;
  }

  Future<File> prepareIngestFromFile(String sourcePath) async {
    final workspace = await _workspace;
    final sourceFile = File(sourcePath);
    final filename = p.basename(sourcePath);
    final destPath = p.join(workspace.path, filename);

    // Copy to workspace to keep things contained
    return sourceFile.copy(destPath);
  }
}
