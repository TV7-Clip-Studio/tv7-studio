// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_job_poller.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart' as api;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VideoItem {
  VideoItem({
    required this.file,
    this.thumbnailPath,
    this.duration,
    this.resolution,
    this.sourceUrl,
    this.backendId,
    this.title,
    this.isClip = false,
    this.parentBasename,
    this.synced = false,
  });
  final File file;
  final String? thumbnailPath;
  final String? duration;
  final String? resolution;
  final String? sourceUrl;
  final int? backendId;
  final String? title;
  final bool isClip;
  final String? parentBasename;
  final bool synced;
}

class TranscriptResult {
  TranscriptResult({required this.text, this.languageCode});
  final String text;
  final String? languageCode;
}

class LocalTranscriptionSetupRequiredException implements Exception {
  const LocalTranscriptionSetupRequiredException({
    required this.message,
    required this.missing,
    required this.setupCapability,
  });

  factory LocalTranscriptionSetupRequiredException.fromEngine(
    EngineTranscriptionSetupRequiredException error,
  ) {
    return LocalTranscriptionSetupRequiredException(
      message: error.message,
      missing: error.missing,
      setupCapability: error.setupCapability,
    );
  }

  final String message;
  final List<String> missing;
  final String? setupCapability;

  @override
  String toString() {
    final suffix = missing.isEmpty ? '' : ' Missing: ${missing.join(', ')}.';
    return '$message$suffix';
  }
}

class VttCue {
  VttCue({required this.start, required this.end, required this.text});
  final double start;
  final double end;
  final String text;
}

List<VttCue> parseVttCues(String vttContent) {
  final cues = <VttCue>[];
  final blocks = vttContent.replaceAll('\r\n', '\n').split('\n\n');
  for (final block in blocks) {
    final trimmedBlock = block.trim();
    if (trimmedBlock.isEmpty) continue;
    final lines = trimmedBlock.split('\n');
    String? timingLine;
    final textLines = <String>[];
    for (final line in lines) {
      if (line.contains('-->')) {
        timingLine = line;
      } else if (timingLine != null) {
        textLines.add(line);
      }
    }
    if (timingLine == null) continue;
    final parts = timingLine.split('-->');
    if (parts.length != 2) continue;
    final start = _parseTimestamp(parts[0]);
    final end = _parseTimestamp(parts[1]);
    final text = textLines.join(' ').replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (text.isEmpty) continue;
    cues.add(VttCue(start: start, end: end, text: text));
  }
  return cues;
}

double _parseTimestamp(String ts) {
  final cleanTs = ts.trim().split(' ').first;
  final parts = cleanTs.split(':');
  if (parts.length == 3) {
    final hrs = double.tryParse(parts[0]) ?? 0.0;
    final mins = double.tryParse(parts[1]) ?? 0.0;
    final secsParts = parts[2].split('.');
    final secs = double.tryParse(secsParts[0]) ?? 0.0;
    final ms = secsParts.length > 1
        ? (double.tryParse(secsParts[1]) ?? 0.0)
        : 0.0;
    return hrs * 3600.0 + mins * 60.0 + secs + (ms / 1000.0);
  } else if (parts.length == 2) {
    final mins = double.tryParse(parts[0]) ?? 0.0;
    final secsParts = parts[1].split('.');
    final secs = double.tryParse(secsParts[0]) ?? 0.0;
    final ms = secsParts.length > 1
        ? (double.tryParse(secsParts[1]) ?? 0.0)
        : 0.0;
    return mins * 60.0 + secs + (ms / 1000.0);
  }
  return 0.0;
}

List<List<double>> calculateTimelineGaps(
  List<api.SuggestedClip> existingClips,
  double totalDuration,
) {
  final intervals = existingClips
      .map((c) => [c.startSec.toDouble(), c.endSec.toDouble()])
      .toList();
  intervals.sort((a, b) => a[0].compareTo(b[0]));

  final merged = <List<double>>[];
  for (final interval in intervals) {
    if (merged.isEmpty) {
      merged.add([interval[0], interval[1]]);
    } else {
      final last = merged.last;
      if (interval[0] <= last[1]) {
        last[1] = math.max(last[1], interval[1]);
      } else {
        merged.add([interval[0], interval[1]]);
      }
    }
  }

  final gaps = <List<double>>[];
  double current = 0.0;
  for (final interval in merged) {
    if (interval[0] > current) {
      gaps.add([current, interval[0]]);
    }
    current = math.max(current, interval[1]);
  }
  if (current < totalDuration) {
    gaps.add([current, totalDuration]);
  }
  return gaps;
}

String? _sourceUrlFromMetadata(Map<String, dynamic> metadata) {
  final candidates = [
    metadata['webpage_url'],
    metadata['source_url'],
    metadata['sourceUrl'],
    metadata['url'],
  ];
  for (final candidate in candidates) {
    final value = candidate?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String? _remoteSourceUrl(Map<String, dynamic> metadata) {
  final sourceUrl = _sourceUrlFromMetadata(metadata);
  if (sourceUrl == null) return null;
  final uri = Uri.tryParse(sourceUrl);
  if (uri == null || uri.scheme == 'file' || uri.scheme == 'local') {
    return null;
  }
  return sourceUrl;
}

List<api.SuggestedClip> segmentCuesIntoHighlights(
  List<VttCue> cues,
  double targetDuration,
  List<List<double>> targetGaps,
  String videoTitle,
) {
  final clips = <api.SuggestedClip>[];

  for (final gap in targetGaps) {
    final gapStart = gap[0];
    final gapEnd = gap[1];

    final gapCues = cues
        .where((c) => c.start >= gapStart && c.end <= gapEnd)
        .toList();
    if (gapCues.isEmpty) {
      final gapDuration = gapEnd - gapStart;
      if (gapDuration >= 8.0) {
        int numClips = (gapDuration / targetDuration).round();
        if (numClips < 1) numClips = 1;
        final clipLen = gapDuration / numClips;
        for (int i = 0; i < numClips; i++) {
          final start = (gapStart + i * clipLen).floor();
          final end = (gapStart + (i + 1) * clipLen).ceil();
          final hook = "Segment ${start}s - ${end}s";
          final desc =
              "Local highlight segment from $videoTitle covering timeline from $start to $end.";
          clips.add(
            api.SuggestedClip(
              startSec: start,
              endSec: end,
              title: hook,
              description: desc,
              hook: hook,
            ),
          );
        }
      }
      continue;
    }

    int cueIndex = 0;
    while (cueIndex < gapCues.length) {
      final currentSegmentCues = <VttCue>[];
      double startTime = gapCues[cueIndex].start;
      double endTime = gapCues[cueIndex].end;

      while (cueIndex < gapCues.length) {
        final cue = gapCues[cueIndex];
        currentSegmentCues.add(cue);
        endTime = cue.end;
        cueIndex++;

        if (endTime - startTime >= targetDuration) {
          if (cueIndex < gapCues.length) {
            final nextCue = gapCues[cueIndex];
            final text = cue.text.trim();
            final endsWithPunctuation =
                text.endsWith('.') || text.endsWith('?') || text.endsWith('!');
            if (!endsWithPunctuation &&
                (nextCue.end - startTime) < targetDuration + 5.0) {
              currentSegmentCues.add(nextCue);
              endTime = nextCue.end;
              cueIndex++;
            }
          }
          break;
        }
      }

      if (currentSegmentCues.isEmpty) continue;

      final startSec = startTime.floor();
      final endSec = endTime.ceil();
      final dialogueText = currentSegmentCues.map((c) => c.text).join(' ');

      final generated = generateHookAndPost(
        dialogueText,
        videoTitle,
        startSec,
        endSec,
      );

      clips.add(
        api.SuggestedClip(
          startSec: startSec,
          endSec: endSec,
          title: generated['title']!,
          description: generated['description']!,
          hook: generated['title']!,
        ),
      );
    }
  }

  return clips;
}

Map<String, String> generateHookAndPost(
  String dialogue,
  String videoTitle,
  int startSec,
  int endSec,
) {
  String title = "";
  final questionRegex = RegExp(r'([^.!?]*\?[^.!?]*)', caseSensitive: false);
  final questionMatch = questionRegex.firstMatch(dialogue);
  if (questionMatch != null) {
    final rawQ = questionMatch.group(0)!.trim();
    if (rawQ.split(' ').length >= 3 && rawQ.split(' ').length <= 10) {
      title = "${_cleanText(rawQ)} 😮";
    }
  }

  if (title.isEmpty) {
    final exclamationRegex = RegExp(r'([^.!?]*\![^.!?]*)');
    final exclamationMatch = exclamationRegex.firstMatch(dialogue);
    if (exclamationMatch != null) {
      final rawEx = exclamationMatch.group(0)!.trim();
      if (rawEx.split(' ').length >= 3 && rawEx.split(' ').length <= 10) {
        title = "${_cleanText(rawEx)} 🔥";
      }
    }
  }

  if (title.isEmpty) {
    final words = dialogue
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (words.length >= 4) {
      final phrase = words.take(math.min(6, words.length)).join(' ');
      title = "${_capitalize(phrase)}... ⏳";
    } else {
      title = "Highlight from $videoTitle! 🎬";
    }
  }

  if (title.length > 60) {
    title = "${title.substring(0, 57)}...";
  }

  final startLabel = _formatSeconds(startSec);
  final endLabel = _formatSeconds(endSec);
  final cleanDialogue = dialogue.length > 150
      ? "${dialogue.substring(0, 147)}..."
      : dialogue;

  final description =
      "👀 Must-watch highlight from our latest video: \"$videoTitle\"!\n\n"
      "Here is a key moment covering the conversation from $startLabel to $endLabel:\n"
      "\"$cleanDialogue\"\n\n"
      "🔥 Check out the full video on our channel for more details! #highlights #clips #content #shorts";

  return {'title': title, 'description': description};
}

String _cleanText(String text) {
  var cleaned = text.trim();
  if (cleaned.startsWith('"') || cleaned.startsWith('\'')) {
    cleaned = cleaned.substring(1);
  }
  if (cleaned.endsWith('"') || cleaned.endsWith('\'')) {
    cleaned = cleaned.substring(0, cleaned.length - 1);
  }
  return cleaned;
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _formatSeconds(int totalSecs) {
  final mins = totalSecs ~/ 60;
  final secs = totalSecs % 60;
  return "$mins:${secs.toString().padLeft(2, '0')}";
}

class ClientVideoRepository {
  ClientVideoRepository({
    required ToolRunner toolRunner,
    required this.engineClient,
    required this.videosApi,
    required this.uploadsApi,
    required this.aiApi,
    required this.dio,
    EngineJobPoller? jobPoller,
    EngineJobPollingPolicy pollingPolicy = const EngineJobPollingPolicy(),
  }) : runner = toolRunner,
       _jobPoller =
           jobPoller ??
           EngineJobPoller(engineClient: engineClient, policy: pollingPolicy);

  final ToolRunner runner;
  final EngineClient engineClient;
  final api.VideosApi videosApi;
  final api.UploadsApi uploadsApi;
  final api.AiApi aiApi;
  final Dio dio;
  final EngineJobPoller _jobPoller;

  Future<Directory> get _workspace async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final workspace = Directory(p.join(appDocDir.path, 'forgotten_workspace'));
    if (!await workspace.exists()) {
      await workspace.create(recursive: true);
    }
    return workspace;
  }

  Future<List<VideoItem>> getVideos() async {
    final workspace = await _workspace;
    if (!await workspace.exists()) {
      return [];
    }

    final entities = await workspace.list().toList();
    final videoFiles =
        entities.whereType<File>().where((file) {
            final ext = p.extension(file.path).toLowerCase();
            return ['.mp4', '.mkv', '.mov', '.avi', '.webm'].contains(ext);
          }).toList()
          // Sort by modification time descending (newest first)
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );

    final items = <VideoItem>[];
    for (final file in videoFiles) {
      items.add(await _enrichVideo(file));
    }

    return items;
  }

  Future<void> downloadTranscript(String videoPath) async {
    final metaFile = File('$videoPath.meta.json');
    if (!await metaFile.exists()) {
      throw Exception('No metadata found for video');
    }

    final meta =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final url = _remoteSourceUrl(meta);

    if (url == null) {
      throw Exception(
        'Transcript download requires original remote source URL metadata',
      );
    }

    final lang = _selectSubtitleLanguage(meta);
    if (lang == null) {
      throw Exception('No subtitles available to download');
    }

    final transcriptPath = videoPath.replaceAll(p.extension(videoPath), '.vtt');
    final job = await engineClient.startTranscriptDownload(
      url: url,
      outputPath: transcriptPath,
      language: lang,
    );
    final completed = await _jobPoller.waitFor(job);
    if (completed.status != 'succeeded') {
      throw Exception(completed.error ?? 'Transcript job ${completed.status}');
    }
  }

  Future<TranscriptResult?> generateTranscript(
    String videoPath, {
    String language = 'en',
    void Function(String)? onLog,
    void Function(double progress)? onProgress,
  }) async {
    final transcriptPath = videoPath.replaceAll(p.extension(videoPath), '.vtt');
    EngineJob job;
    try {
      job = await engineClient.startTranscriptGenerate(
        mediaPath: videoPath,
        outputPath: transcriptPath,
        language: language,
      );
    } on EngineTranscriptionSetupRequiredException catch (error) {
      throw LocalTranscriptionSetupRequiredException.fromEngine(error);
    }

    final completed = await _jobPoller.waitFor(
      job,
      onLog: onLog,
      onProgress: onProgress,
    );
    if (completed.status != 'succeeded') {
      throw Exception(completed.error ?? 'Transcript job ${completed.status}');
    }

    final result = completed.result == null
        ? null
        : EngineTranscriptDownloadResult.fromJson(completed.result!);
    final generatedPath = result?.transcriptPath;
    if (generatedPath != null &&
        generatedPath.isNotEmpty &&
        generatedPath != transcriptPath) {
      final generatedFile = File(generatedPath);
      if (await generatedFile.exists()) {
        await generatedFile.copy(transcriptPath);
      }
    }

    return getTranscript(videoPath);
  }

  Future<TranscriptResult?> getTranscript(String videoPath) async {
    final base = videoPath.replaceAll(p.extension(videoPath), '');
    final candidates = Directory(p.dirname(videoPath))
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              f.path.startsWith(base) && f.path.toLowerCase().endsWith('.vtt'),
        );

    for (final file in candidates) {
      try {
        final raw = await file.readAsString();
        final text = _normalizeTranscript(raw, file.path);
        final language = _inferLanguageCode(file.path);
        return TranscriptResult(text: text, languageCode: language);
      } catch (_) {}
    }
    return null;
  }

  String _absoluteUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(dio.options.baseUrl);
    return base.resolve(url.startsWith('/') ? url : '/$url').toString();
  }

  String _normalizeTranscript(String raw, String path) {
    final lower = path.toLowerCase();
    if (!lower.endsWith('.vtt')) return raw;

    final buffer = StringBuffer();
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.toUpperCase() == 'WEBVTT') continue;
      if (trimmed.contains('-->')) continue;
      if (int.tryParse(trimmed) != null) continue;
      buffer.write('$trimmed ');
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<api.HighlightResponse> detectHighlights(
    String transcript,
    int durationSeconds, {
    String? transcriptLanguage,
    String? prompt,
    int? maxClips,
    String? videoPath,
    String? durationPreset,
    bool gapsOnly = true,
  }) async {
    if (videoPath != null) {
      try {
        final base = videoPath.replaceAll(p.extension(videoPath), '');
        final vttCandidates = Directory(p.dirname(videoPath))
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  f.path.startsWith(base) &&
                  f.path.toLowerCase().endsWith('.vtt'),
            )
            .toList();

        if (vttCandidates.isNotEmpty) {
          final vttFile = vttCandidates.first;
          final vttContent = await vttFile.readAsString();
          final cues = parseVttCues(vttContent);

          if (cues.isNotEmpty) {
            double targetDuration = 35.0; // default
            if (durationPreset == 'short') {
              targetDuration = 12.0;
            } else if (durationPreset == 'medium') {
              targetDuration = 35.0;
            } else if (durationPreset == 'long') {
              targetDuration = 75.0;
            } else {
              targetDuration = (durationSeconds / 5.0).clamp(10.0, 60.0);
            }

            final existingClips = await loadLocalClipsForSource(videoPath);
            final videoTitle = p.basenameWithoutExtension(videoPath);

            final targetGaps = <List<double>>[];
            if (gapsOnly && existingClips.isNotEmpty) {
              targetGaps.addAll(
                calculateTimelineGaps(
                  existingClips,
                  durationSeconds.toDouble(),
                ),
              );
            } else {
              targetGaps.add([0.0, durationSeconds.toDouble()]);
            }

            final localClips = segmentCuesIntoHighlights(
              cues,
              targetDuration,
              targetGaps,
              videoTitle,
            );
            if (localClips.isNotEmpty) {
              return api.HighlightResponse(clips: localClips);
            }
          }
        }
      } catch (e, stackTrace) {
        developer.log(
          'Smart local highlight generation failed, falling back to smart split',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      final double targetDuration = durationPreset == 'short'
          ? 12.0
          : durationPreset == 'medium'
          ? 35.0
          : durationPreset == 'long'
          ? 75.0
          : 35.0;

      final existingClips = videoPath != null
          ? await loadLocalClipsForSource(videoPath)
          : <api.SuggestedClip>[];
      final videoTitle = videoPath != null
          ? p.basenameWithoutExtension(videoPath)
          : 'Video';

      final targetGaps = <List<double>>[];
      if (gapsOnly && existingClips.isNotEmpty) {
        targetGaps.addAll(
          calculateTimelineGaps(existingClips, durationSeconds.toDouble()),
        );
      } else {
        targetGaps.add([0.0, durationSeconds.toDouble()]);
      }

      final localClips = <api.SuggestedClip>[];
      for (final gap in targetGaps) {
        final gapDuration = gap[1] - gap[0];
        if (gapDuration < 8.0) continue;
        int numClips = (gapDuration / targetDuration).round();
        if (numClips < 1) numClips = 1;
        final clipLen = gapDuration / numClips;
        for (int i = 0; i < numClips; i++) {
          final start = (gap[0] + i * clipLen).floor();
          final end = (gap[0] + (i + 1) * clipLen).ceil();
          final hook = "Segment ${start}s - ${end}s 🎬";
          final desc =
              "Local highlight segment from $videoTitle covering timeline from $start to $end.";
          localClips.add(
            api.SuggestedClip(
              startSec: start,
              endSec: end,
              title: hook,
              description: desc,
              hook: hook,
            ),
          );
        }
      }

      if (localClips.isNotEmpty) {
        return api.HighlightResponse(clips: localClips);
      }
    } catch (_) {}

    final response = await aiApi.generateHighlightsApiV1AiHighlightsPost(
      highlightRequest: api.HighlightRequest(
        transcript: transcript,
        durationSeconds: durationSeconds,
        transcriptLanguage: transcriptLanguage,
        prompt: prompt,
        maxClips: maxClips,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Highlight detection returned empty payload');
    }
    return data;
  }

  Future<List<api.SuggestedClip>> loadLocalClipsForSource(
    String sourcePath,
  ) async {
    final directory = File(sourcePath).parent;
    if (!await directory.exists()) return [];

    final sourceBase = p.basenameWithoutExtension(sourcePath);
    final entities = await directory.list().toList();
    final clips = <api.SuggestedClip>[];

    for (final entity in entities.whereType<File>()) {
      final ext = p.extension(entity.path).toLowerCase();
      if (!['.mp4', '.mkv', '.mov', '.avi', '.webm'].contains(ext)) continue;

      final metaFile = File('${entity.path}.meta.json');
      if (!await metaFile.exists()) continue;

      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        final isClip = meta['is_clip'] as bool? ?? false;
        final parent = meta['parent_basename'] as String?;
        if (!isClip) continue;
        // If parent basename is missing, best-effort derive from filename.
        final parentName =
            parent ??
            (() {
              final name = p.basenameWithoutExtension(entity.path);
              final index = name.indexOf('_clip_');
              if (index != -1) return name.substring(0, index);
              return null;
            })();
        if (parentName == null || parentName != sourceBase) continue;

        final start = meta['start_sec'] as int?;
        final end = meta['end_sec'] as int?;
        if (start == null || end == null || end <= start) continue;

        final hook =
            meta['hook'] as String? ??
            meta['title'] as String? ??
            p.basename(entity.path);
        final description = meta['description'] as String? ?? '';
        final title = meta['title'] as String? ?? hook;

        clips.add(
          api.SuggestedClip(
            startSec: start,
            endSec: end,
            title: title,
            description: description,
            hook: hook,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    // Sort by start time for stable rendering.
    clips.sort((a, b) => a.startSec.compareTo(b.startSec));
    return clips;
  }

  Future<Map<String, bool>> loadClipSyncStatus(String sourcePath) async {
    final directory = File(sourcePath).parent;
    if (!await directory.exists()) return {};

    final sourceBase = p.basenameWithoutExtension(sourcePath);
    final entities = await directory.list().toList();
    final syncMap = <String, bool>{};

    for (final entity in entities.whereType<File>()) {
      final ext = p.extension(entity.path).toLowerCase();
      if (!['.mp4', '.mkv', '.mov', '.avi', '.webm'].contains(ext)) continue;

      final metaFile = File('${entity.path}.meta.json');
      if (!await metaFile.exists()) continue;

      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        final isClip = meta['is_clip'] as bool? ?? false;
        final parent = meta['parent_basename'] as String?;
        if (!isClip) continue;
        final parentName =
            parent ??
            (() {
              final name = p.basenameWithoutExtension(entity.path);
              final index = name.indexOf('_clip_');
              if (index != -1) return name.substring(0, index);
              return null;
            })();
        if (parentName == null || parentName != sourceBase) continue;

        final start = meta['start_sec'] as int?;
        final end = meta['end_sec'] as int?;
        if (start == null || end == null) continue;

        final synced = meta['synced'] == true || meta['asset_url'] != null;
        syncMap['${start}_${end}'] = synced;
      } catch (_) {
        continue;
      }
    }
    return syncMap;
  }

  String? _selectSubtitleLanguage(Map<String, dynamic> meta) {
    // Prefer explicit subtitles if present, then automatic captions.
    final subtitles = meta['subtitles'] as Map<String, dynamic>?;
    final autoSubs = meta['automatic_captions'] as Map<String, dynamic>?;

    String? pickFrom(Map<String, dynamic>? source) {
      if (source == null || source.isEmpty) return null;
      // Prefer English if available, otherwise first entry.
      if (source.containsKey('en')) return 'en';
      return source.keys.first;
    }

    return pickFrom(subtitles) ?? pickFrom(autoSubs);
  }

  Future<String> uploadAsset(File file) async {
    final fileName = p.basename(file.path);
    final multipartFile = await MultipartFile.fromFile(
      file.path,
      filename: fileName,
    );
    final formData = FormData.fromMap({'file': multipartFile});

    final response = await dio.post<Map<String, dynamic>>(
      '/api/v1/uploads/assets',
      data: formData,
    );

    if (response.data == null || response.data!['asset_url'] == null) {
      throw Exception('Upload failed: No data returned');
    }

    final url = _absoluteUrl(response.data!['asset_url'] as String);
    developer.log('Uploaded asset', error: {'path': file.path, 'url': url});
    return url;
  }

  Future<api.VideoRead> syncVideo(VideoItem item) async {
    if (item.isClip) {
      developer.log('Skipping sync for clip item', error: item.file.path);
      return Future.error(
        Exception('Cannot sync a clip as a video. Use clip APIs instead.'),
      );
    }
    final metaFile = File('${item.file.path}.meta.json');
    Map<String, dynamic>? meta;

    if (await metaFile.exists()) {
      try {
        meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    var sourceUrl = 'file://${item.file.path}';
    String? title;

    // 1. Try to get metadata from existing meta file
    if (meta != null) {
      final metaSourceUrl = _sourceUrlFromMetadata(meta);
      if (metaSourceUrl != null) {
        sourceUrl = metaSourceUrl;
      }
      title = meta['title'] as String?;
      // Fallback to media container tags.
      if (title == null) {
        final format = meta['format'] as Map<String, dynamic>?;
        final tags = format?['tags'] as Map<String, dynamic>?;
        title = tags?['title'] as String?;
      }
    }

    // Remote metadata is captured by Engine during URL ingest. Do not run
    // yt-dlp directly from Studio if old metadata is incomplete.

    final stat = await item.file.stat();

    // Use title as filename if available, ensuring it has an extension
    var originalFilename = p.basename(item.file.path);
    if (title != null) {
      final ext = p.extension(item.file.path);
      // Sanitize title for filename usage
      final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      originalFilename = '$safeTitle$ext';
    }

    // 3. Check for transcript
    String? transcriptText;
    String? transcriptLanguage;

    final transcriptResult = await getTranscript(item.file.path);
    if (transcriptResult != null) {
      transcriptText = transcriptResult.text;
      transcriptLanguage = transcriptResult.languageCode;
    }

    final request = api.LocalVideoCreate(
      sourceUrl: sourceUrl,
      localPath: item.file.path,
      originalFilename: originalFilename,
      fileSizeBytes: stat.size,
      durationSeconds: _parseDuration(item.duration),
      transcriptText: transcriptText,
      transcriptLanguage: transcriptLanguage,
    );

    developer.log('Syncing video: ${request.toJson()}');

    try {
      final response = await videosApi.registerLocalVideoApiV1VideosLocalPost(
        localVideoCreate: request,
      );
      if (response.data == null) {
        throw Exception('Sync failed: No data returned');
      }

      final video = response.data!;

      // Save backend ID to metadata
      meta ??= {};
      meta['backend_id'] = video.id;
      await metaFile.writeAsString(jsonEncode(meta));

      return video;
    } catch (e, stackTrace) {
      developer.log('Sync failed', error: e, stackTrace: stackTrace);
      if (e is DioException) {
        developer.log('Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<void> deleteVideoById(int videoId) async {
    await dio.delete<void>('/api/v1/videos/$videoId');
  }

  Future<void> createClipForVideo(int videoId, api.ClipUpsert clip) async {
    try {
      developer.log('Creating clip for video $videoId', error: clip.toJson());
      // Use the generated API client instead of raw Dio call
      await videosApi.createClipForVideoApiV1VideosVideoIdClipsPost(
        videoId: videoId,
        clipUpsert: clip,
      );
      developer.log('Created clip successfully');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add clip to video',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is DioException) {
        developer.log('Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  String? _inferLanguageCode(String filePath) {
    final name = p.basename(filePath).toLowerCase();
    final parts = name.split('.');
    // expecting something like base.en.vtt -> language before last extension
    if (parts.length >= 3) {
      final lang = parts[parts.length - 2];
      if (lang.length <= 5) {
        return lang;
      }
    }
    return null;
  }

  int? _parseDuration(String? duration) {
    if (duration == null) return null;
    final parts = duration.split(':');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    return null;
  }

  Future<int?> probeDurationSeconds(String path) async {
    // Try meta first
    final metaFile = File('$path.meta.json');
    if (await metaFile.exists()) {
      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        final duration = meta['duration'] as String?;
        final parsed = _parseDuration(duration);
        if (parsed != null && parsed > 0) return parsed;
      } catch (_) {}
    }

    try {
      final info = await probeMediaInfo(path);
      final format = info['format'] as Map<String, dynamic>?;
      final formatDuration = format?['duration'];
      if (formatDuration != null) {
        final seconds = double.tryParse(formatDuration.toString());
        if (seconds != null && seconds > 0) return seconds.round();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> probeMediaInfo(String path) async {
    final metadata = await engineClient.probeMedia(path);
    return metadata.toFfprobeLikeJson();
  }

  Future<void> generateThumbnail(String videoPath, String thumbnailPath) async {
    await engineClient.generateThumbnail(
      inputPath: videoPath,
      outputPath: thumbnailPath,
    );
  }

  Future<void> renderClip(
    String videoPath,
    double startSeconds,
    double endSeconds,
    String outputPath,
  ) async {
    await engineClient.renderClip(
      inputPath: videoPath,
      outputPath: outputPath,
      startSeconds: startSeconds,
      endSeconds: endSeconds,
    );
  }

  Future<VideoItem> _enrichVideo(File file) async {
    final metaFile = File('${file.path}.meta.json');
    final thumbFile = File('${file.path}.thumb.jpg');

    Map<String, dynamic>? meta;
    String? title;
    bool? isClipMeta;
    String? parentBasenameMeta;
    String? durationFromMeta;

    // 1. Metadata
    if (await metaFile.exists()) {
      try {
        final parsedMeta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        meta = parsedMeta;
        title = parsedMeta['title'] as String?;
        isClipMeta = parsedMeta['is_clip'] as bool?;
        parentBasenameMeta = parsedMeta['parent_basename'] as String?;
        durationFromMeta = parsedMeta['duration'] as String?;
      } catch (_) {}
    }

    if (meta == null) {
      try {
        meta = await probeMediaInfo(file.path);
        await metaFile.writeAsString(jsonEncode(meta));
        final format = meta['format'] as Map<String, dynamic>?;
        final tags = format?['tags'] as Map<String, dynamic>?;
        title = tags?['title'] as String?;
      } catch (e) {
        // print('Failed to get metadata for ${file.path}: $e');
      }
    }

    // 2. Thumbnail
    if (!await thumbFile.exists()) {
      try {
        await generateThumbnail(file.path, thumbFile.path);
      } catch (e) {
        // print('Failed to generate thumbnail for ${file.path}: $e');
      }
    }

    var duration = durationFromMeta;
    String? resolution;
    String? sourceUrl;
    int? backendId;

    if (meta != null) {
      sourceUrl = _sourceUrlFromMetadata(meta);
      backendId = meta['backend_id'] as int?;

      // Try top-level duration field first (common in yt-dlp metadata)
      final rawDuration = meta['duration'];
      if (rawDuration is num) {
        final d = Duration(seconds: rawDuration.toInt());
        duration =
            '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      } else if (rawDuration is String) {
        final parsed = double.tryParse(rawDuration);
        if (parsed != null) {
          final d = Duration(seconds: parsed.toInt());
          duration =
              '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
        }
      }

      try {
        if (duration == null || duration.isEmpty) {
          final format = meta['format'] as Map<String, dynamic>?;
          final formatDuration = format?['duration'];
          if (formatDuration != null) {
            final seconds = double.tryParse(formatDuration.toString()) ?? 0;
            final d = Duration(seconds: seconds.toInt());
            duration =
                '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
          }
        }

        final streams = (meta['streams'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>();
        Map<String, dynamic>? videoStream;
        if (streams != null) {
          for (final stream in streams) {
            if (stream['codec_type'] == 'video') {
              videoStream = stream;
              break;
            }
          }
        }
        if (videoStream != null) {
          final width = videoStream['width'] as int?;
          final height = videoStream['height'] as int?;
          if (width != null && height != null) {
            resolution = '${width}x$height';
          }
        }
      } catch (_) {}
    }

    final isClip = isClipMeta ?? file.path.contains('_clip_');
    var parentBasename = parentBasenameMeta;
    if (parentBasename == null && isClip) {
      final name = p.basenameWithoutExtension(file.path);
      final index = name.indexOf('_clip_');
      if (index != -1) {
        parentBasename = name.substring(0, index);
      }
    }

    final synced = isClip
        ? (meta != null &&
              (meta['synced'] == true || meta['asset_url'] != null))
        : (backendId != null);

    return VideoItem(
      file: file,
      thumbnailPath: await thumbFile.exists() ? thumbFile.path : null,
      duration: duration,
      resolution: resolution,
      sourceUrl: sourceUrl,
      backendId: backendId,
      title: title,
      isClip: isClip,
      parentBasename: parentBasename,
      synced: synced,
    );
  }

  Future<void> deleteAllVideos() async {
    final workspace = await _workspace;
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
      await workspace.create();
    }
  }

  Future<void> deleteVideo(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    // Cleanup sidecars
    final metaFile = File('$path.meta.json');
    if (await metaFile.exists()) await metaFile.delete();

    final thumbFile = File('$path.thumb.jpg');
    if (await thumbFile.exists()) await thumbFile.delete();
  }
}

typedef LocalVideoRepository = ClientVideoRepository;
