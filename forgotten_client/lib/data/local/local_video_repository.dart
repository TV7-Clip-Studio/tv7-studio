import 'dart:convert';
import 'dart:io';
import 'package:forgotten_client_api/forgotten_client_api.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tool_runner.dart';

class VideoItem {
  final File file;
  final String? thumbnailPath;
  final String? duration;
  final String? resolution;

  VideoItem({
    required this.file,
    this.thumbnailPath,
    this.duration,
    this.resolution,
  });
}

class LocalVideoRepository {
  LocalVideoRepository({
    required this.toolRunner,
    required this.videosApi,
  });

  final ToolRunner toolRunner;
  final VideosApi videosApi;

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
    final videoFiles = entities.whereType<File>().where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return ['.mp4', '.mkv', '.mov', '.avi', '.webm'].contains(ext);
    }).toList();

    // Sort by modification time descending (newest first)
    videoFiles.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });

    final items = <VideoItem>[];
    for (final file in videoFiles) {
      items.add(await _enrichVideo(file));
    }

    return items;
  }

  Future<void> syncVideo(VideoItem item) async {
    final metaFile = File('${item.file.path}.meta.json');
    Map<String, dynamic>? meta;

    if (await metaFile.exists()) {
      try {
        meta = jsonDecode(await metaFile.readAsString());
      } catch (_) {}
    }

    String sourceUrl = 'file://${item.file.path}';
    String? title;

    // 1. Try to get metadata from existing meta file
    if (meta != null) {
       if (meta['webpage_url'] != null) {
         sourceUrl = meta['webpage_url'];
       }
       if (meta['title'] != null) {
         title = meta['title'];
       }
       // Fallback to ffprobe tags
       if (title == null && meta['format'] != null && meta['format']['tags'] != null) {
          title = meta['format']['tags']['title'];
       }
    }

    // 2. If we have a remote URL but no title, try to fetch metadata from YouTube
    if (sourceUrl.startsWith('http') && title == null) {
       try {
         final ytMeta = await toolRunner.getYouTubeMetadata(sourceUrl);
         title = ytMeta['title'];
         // Update local meta with new info
         if (meta == null) {
           meta = ytMeta;
         } else {
           meta.addAll(ytMeta);
         }
         await metaFile.writeAsString(jsonEncode(meta));
       } catch (e) {
         print('Failed to fetch YouTube metadata: $e');
       }
    }

    final stat = await item.file.stat();
    
    // Use title as filename if available, ensuring it has an extension
    String originalFilename = p.basename(item.file.path);
    if (title != null) {
      final ext = p.extension(item.file.path);
      // Sanitize title for filename usage
      final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      originalFilename = '$safeTitle$ext';
    }

    final request = LocalVideoCreate(
      sourceUrl: sourceUrl,
      localPath: item.file.path,
      originalFilename: originalFilename,
      fileSizeBytes: stat.size,
      durationSeconds: _parseDuration(item.duration),
      status: VideoStatus.ready,
    );

    print('Syncing video: ${request.toJson()}');

    try {
      await videosApi.registerLocalVideoApiV1VideosLocalPost(localVideoCreate: request);
      // TODO: Mark as synced in local metadata
    } catch (e) {
      print('Sync failed: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  int? _parseDuration(String? duration) {
    if (duration == null) return null;
    final parts = duration.split(':');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    return null;
  }

  Future<VideoItem> _enrichVideo(File file) async {
    final metaFile = File('${file.path}.meta.json');
    final thumbFile = File('${file.path}.thumb.jpg');

    Map<String, dynamic>? meta;
    
    // 1. Metadata
    if (await metaFile.exists()) {
      try {
        meta = jsonDecode(await metaFile.readAsString());
      } catch (_) {}
    }

    if (meta == null) {
      try {
        meta = await toolRunner.getMediaInfo(file.path);
        await metaFile.writeAsString(jsonEncode(meta));
      } catch (e) {
        // print('Failed to get metadata for ${file.path}: $e');
      }
    }

    // 2. Thumbnail
    if (!await thumbFile.exists()) {
      try {
        await toolRunner.generateThumbnail(file.path, thumbFile.path);
      } catch (e) {
        // print('Failed to generate thumbnail for ${file.path}: $e');
      }
    }

    String? duration;
    String? resolution;

    if (meta != null) {
      try {
        final format = meta['format'];
        if (format != null && format['duration'] != null) {
          final seconds = double.tryParse(format['duration'].toString()) ?? 0;
          final d = Duration(seconds: seconds.toInt());
          duration = '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
        }

        final streams = meta['streams'] as List?;
        final videoStream = streams?.firstWhere(
          (s) => s['codec_type'] == 'video',
          orElse: () => null,
        );
        if (videoStream != null) {
          final width = videoStream['width'];
          final height = videoStream['height'];
          if (width != null && height != null) {
            resolution = '${width}x$height';
          }
        }
      } catch (_) {}
    }

    return VideoItem(
      file: file,
      thumbnailPath: await thumbFile.exists() ? thumbFile.path : null,
      duration: duration,
      resolution: resolution,
    );
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
