// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  MediaService({
    required this.engineClient,
    this.pollInterval = const Duration(milliseconds: 250),
    this.jobTimeout = const Duration(minutes: 30),
  });

  final EngineClient engineClient;
  final Duration pollInterval;
  final Duration jobTimeout;

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
    final filename = 'download_${DateTime.now().millisecondsSinceEpoch}';

    onLog?.call('Starting Engine URL ingest...');

    final started = await engineClient.startUrlIngest(
      url: url,
      outputDir: workspace.path,
      outputTemplate: '$filename.%(ext)s',
    );
    final completed = await _waitForJob(started, onLog: onLog);
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
      final transcriptCompleted = await _waitForJob(
        transcriptJob,
        onLog: onLog,
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

  Future<EngineJob> _waitForJob(
    EngineJob started, {
    void Function(String)? onLog,
  }) async {
    var job = started;
    final seenLogs = <String>{};
    final deadline = DateTime.now().add(jobTimeout);

    while (!job.isTerminal) {
      for (final line in job.logs) {
        if (seenLogs.add(line)) onLog?.call(line);
      }
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Engine job timed out: ${job.id}', jobTimeout);
      }
      await Future<void>.delayed(pollInterval);
      job = await engineClient.getJob(job.id);
      try {
        final logs = await engineClient.getJobLogs(job.id);
        for (final line in logs.logs) {
          if (seenLogs.add(line)) onLog?.call(line);
        }
      } catch (_) {}
    }

    for (final line in job.logs) {
      if (seenLogs.add(line)) onLog?.call(line);
    }
    return job;
  }
}
