// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:io';

import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_job_poller.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  MediaService({
    required this.engineClient,
    EngineJobPoller? jobPoller,
    EngineJobPollingPolicy pollingPolicy = const EngineJobPollingPolicy(),
  }) : _jobPoller =
           jobPoller ??
           EngineJobPoller(engineClient: engineClient, policy: pollingPolicy);

  final EngineClient engineClient;
  final EngineJobPoller _jobPoller;

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
    void Function(double progress)? onProgress,
    void Function(String jobId)? onJobStarted,
  }) async {
    final workspace = await _workspace;
    final filename = 'download_${DateTime.now().millisecondsSinceEpoch}';

    onLog?.call('Starting Engine URL ingest...');

    final started = await engineClient.startUrlIngest(
      url: url,
      outputDir: workspace.path,
      outputTemplate: '$filename.%(ext)s',
    );
    onJobStarted?.call(started.id);
    final completed = await _jobPoller.waitFor(
      started,
      onLog: onLog,
      onProgress: onProgress,
    );
    if (completed.status != 'succeeded') {
      throw StateError(
        completed.error == null || completed.error!.isEmpty
            ? 'Engine ingest job ${completed.status}'
            : completed.error!,
      );
    }

    final ingestResult = EngineUrlIngestResult.fromJson(
      completed.result ?? const {},
    );
    final mediaPath = ingestResult.mediaPath;
    if (mediaPath == null || mediaPath.isEmpty) {
      throw StateError('Engine ingest completed without a media path');
    }
    final actualFile = File(mediaPath);

    final meta = <String, dynamic>{
      ...ingestResult.metadata,
      'webpage_url': ingestResult.url.isEmpty ? url : ingestResult.url,
    };
    final metaFile = File('${actualFile.path}.meta.json');
    await metaFile.writeAsString(jsonEncode(meta));
    onLog?.call('Metadata saved to ${metaFile.path}');

    onLog?.call('Downloading transcript...');
    try {
      final transcriptPath = actualFile.path.replaceAll(
        p.extension(actualFile.path),
        '.vtt',
      );
      final transcriptJob = await engineClient.startTranscriptDownload(
        url: url,
        outputPath: transcriptPath,
        language: 'en',
      );
      onJobStarted?.call(transcriptJob.id);
      final transcriptCompleted = await _jobPoller.waitFor(
        transcriptJob,
        onLog: onLog,
        onProgress: onProgress,
      );
      if (transcriptCompleted.status == 'succeeded') {
        final transcript = EngineTranscriptDownloadResult.fromJson(
          transcriptCompleted.result ?? const {},
        );
        onLog?.call(
          'Transcript downloaded: ${transcript.transcriptPath ?? transcriptPath}',
        );
      } else {
        onLog?.call(
          'Transcript download failed: ${transcriptCompleted.error ?? transcriptCompleted.status}',
        );
      }
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
