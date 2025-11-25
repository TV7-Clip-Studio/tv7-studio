import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tool_runner.dart';

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

  Future<File> prepareIngestFromUrl(String url, {void Function(String)? onLog}) async {
    final workspace = await _workspace;
    // Simple naming strategy for now, ideally we'd get the title first
    final filename = 'download_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final outputPath = p.join(workspace.path, filename);

    onLog?.call('Starting download to $outputPath...');

    final stream = toolRunner.runStream(
      'yt-dlp',
      ['-o', outputPath, url],
    );

    await for (final line in stream) {
      onLog?.call(line);
    }

    return File(outputPath);
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
