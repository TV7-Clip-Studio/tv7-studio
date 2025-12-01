// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
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
}

class TranscriptResult {
  TranscriptResult({required this.text, this.languageCode});
  final String text;
  final String? languageCode;
}

class ClientVideoRepository {
  ClientVideoRepository({
    required ToolRunner toolRunner,
    required this.videosApi,
    required this.uploadsApi,
    required this.aiApi,
    required this.dio,
  }) : runner = toolRunner;

  final ToolRunner runner;
  final api.VideosApi videosApi;
  final api.UploadsApi uploadsApi;
  final api.AiApi aiApi;
  final Dio dio;

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
    final url = meta['webpage_url'] as String?;

    if (url == null) {
      throw Exception('No source URL found in metadata');
    }

    final lang = _selectSubtitleLanguage(meta);
    if (lang == null) {
      throw Exception('No subtitles available to download');
    }

    // Remove extension for the base path
    final transcriptBase = videoPath.replaceAll(p.extension(videoPath), '');
    await runner.downloadTranscript(url, transcriptBase, lang);
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
  }) async {
    try {
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
    } catch (e, stackTrace) {
      developer.log(
        'Highlight detection error',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
      final metaSourceUrl = meta['webpage_url'] as String?;
      if (metaSourceUrl != null) {
        sourceUrl = metaSourceUrl;
      }
      title = meta['title'] as String?;
      // Fallback to ffprobe tags
      if (title == null) {
        final format = meta['format'] as Map<String, dynamic>?;
        final tags = format?['tags'] as Map<String, dynamic>?;
        title = tags?['title'] as String?;
      }
    }

    // 2. If we have a remote URL but no title, fetch metadata from YouTube
    if (sourceUrl.startsWith('http') && title == null) {
      try {
        final ytMeta = await runner.getYouTubeMetadata(sourceUrl);
        title = ytMeta['title'] as String?;
        // Update local meta with new info
        if (meta == null) {
          meta = ytMeta;
        } else {
          meta.addAll(ytMeta);
        }
        await metaFile.writeAsString(jsonEncode(meta));
      } catch (e, stackTrace) {
        developer.log(
          'Failed to fetch YouTube metadata',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

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
      final info = await runner.getMediaInfo(path);
      final format = info['format'] as Map<String, dynamic>?;
      final formatDuration = format?['duration'];
      if (formatDuration != null) {
        final seconds = double.tryParse(formatDuration.toString());
        if (seconds != null && seconds > 0) return seconds.round();
      }
    } catch (_) {}
    return null;
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
        meta = await runner.getMediaInfo(file.path);
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
        await runner.generateThumbnail(file.path, thumbFile.path);
      } catch (e) {
        // print('Failed to generate thumbnail for ${file.path}: $e');
      }
    }

    var duration = durationFromMeta;
    String? resolution;
    String? sourceUrl;
    int? backendId;

    if (meta != null) {
      sourceUrl = meta['webpage_url'] as String?;
      backendId = meta['backend_id'] as int?;
      try {
        final format = meta['format'] as Map<String, dynamic>?;
        final formatDuration = format?['duration'];
        if (formatDuration != null) {
          final seconds = double.tryParse(formatDuration.toString()) ?? 0;
          final d = Duration(seconds: seconds.toInt());
          duration =
              '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
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
