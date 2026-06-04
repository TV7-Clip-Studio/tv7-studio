// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/config/config_repository.dart';
import 'package:forgotten_client/data/local/diagnostics_log.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/data/local/media_service.dart';
import 'package:forgotten_client/data/local/studio_diagnostics_service.dart';
import 'package:forgotten_client/features/dashboard/clip_creation_dialog.dart';
import 'package:forgotten_client/features/diagnostics/diagnostics_page.dart';
import 'package:forgotten_client/features/ingest/ingest_page.dart';
import 'package:forgotten_client/features/player/video_player_page.dart';
import 'package:forgotten_client/features/user/user_page.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';
import 'package:path/path.dart' as p;

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.configRepository,
    required this.localVideoRepository,
    required this.authRepository,
    required this.appConfig,
    required this.dio,
    required this.engineClient,
    required this.engineStartup,
    required this.diagnosticsLog,
    required this.usersApi,
    required this.onLogout,
    super.key,
  });

  final ConfigRepository configRepository;
  final LocalVideoRepository localVideoRepository;
  final AuthRepository authRepository;
  final AppConfig appConfig;
  final Dio dio;
  final EngineClient engineClient;
  final EngineStartupResult engineStartup;
  final DiagnosticsLog diagnosticsLog;
  final UsersApi usersApi;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  List<VideoItem> _videos = [];
  Map<String, List<VideoItem>> _groupedVideos = {};
  final Map<String, int> _groupBackendIds = {};
  bool _loading = true;
  String _search = '';
  final bool _autoPromptNextClip = true;
  bool _isAutoClipping = false;
  String _autoClipStatus = '';
  int _autoClipCompleted = 0;
  int _autoClipTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<int> _ensureBackendVideo(
    String groupKey,
    VideoItem sourceVideo, {
    bool recreate = false,
  }) async {
    int? backendId = _groupBackendIds[groupKey] ?? sourceVideo.backendId;
    if (recreate && backendId != null) {
      await widget.localVideoRepository.deleteVideoById(backendId);
      backendId = null;
    }

    if (backendId != null) {
      return backendId;
    }

    final created = await widget.localVideoRepository.syncVideo(sourceVideo);
    final createdId = created.id;
    _groupBackendIds[groupKey] = createdId;
    return createdId;
  }

  Future<void> _syncAllForVideo(
    VideoItem sourceVideo,
    List<VideoItem> clips,
    String groupKey,
  ) async {
    try {
      final videoId = await _ensureBackendVideo(
        groupKey,
        sourceVideo,
        recreate: true,
      );
      var success = 0;
      final clipItems = clips.where((c) => c.isClip).toList();
      for (final clip in clipItems) {
        await _syncClipWithVideoId(clip, videoId);
        success++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced $success/${clipItems.length} clips')),
        );
      }
      await _loadVideos();
    } catch (e) {
      widget.diagnosticsLog.record('Sync all', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync all failed: $e')));
      }
    }
  }

  Future<void> _syncSingleClip(
    VideoItem clip, {
    required String sourceKey,
  }) async {
    try {
      // Find source video from the grouped map
      final sourceGroup = _groupedVideos[sourceKey];
      final sourceVideo = sourceGroup?.firstWhere(
        (v) => !v.isClip,
        orElse: () => sourceGroup.first,
      );
      if (sourceVideo == null) {
        throw Exception('Source video not found for $sourceKey');
      }
      final videoId = await _ensureBackendVideo(sourceKey, sourceVideo);
      await _syncClipWithVideoId(clip, videoId);
      await _loadVideos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncClipWithVideoId(VideoItem clip, int videoId) async {
    final clipData = await _buildClipPayload(clip);
    final assetUrl = await widget.localVideoRepository.uploadAsset(
      clipData.videoFile,
    );
    final thumbUrl = await widget.localVideoRepository.uploadAsset(
      clipData.thumbFile,
    );
    final stat = await clipData.videoFile.stat();

    final payload = ClipUpsert(
      startSec: clipData.startSec,
      endSec: clipData.endSec,
      assetUrl: assetUrl,
      thumbnailPath: thumbUrl,
      captionText: clipData.hook,
      fileSizeBytes: stat.size,
    );

    await widget.localVideoRepository.createClipForVideo(videoId, payload);

    // Save synced state to meta file
    final metaFile = File('${clip.file.path}.meta.json');
    Map<String, dynamic> meta = {};
    if (await metaFile.exists()) {
      try {
        meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }
    meta['synced'] = true;
    meta['asset_url'] = assetUrl;
    meta['thumbnail_url'] = thumbUrl;
    meta['parent_backend_id'] = videoId;
    await metaFile.writeAsString(jsonEncode(meta));
  }

  Future<_ClipPayload> _buildClipPayload(VideoItem clip) async {
    final metaFile = File('${clip.file.path}.meta.json');
    int? startSec;
    int? endSec;
    String? hook;
    if (await metaFile.exists()) {
      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        startSec = meta['start_sec'] as int?;
        endSec = meta['end_sec'] as int?;
        hook = meta['hook'] as String?;
      } catch (_) {}
    }

    if (startSec == null || endSec == null) {
      final name = p.basenameWithoutExtension(clip.file.path);
      final parts = name.split('_').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3) {
        final maybeEnd = int.tryParse(parts[parts.length - 2]);
        final maybeStart = int.tryParse(parts[parts.length - 3]);
        if (maybeStart != null && maybeEnd != null) {
          startSec = maybeStart;
          endSec = maybeEnd;
        }
      }
    }

    if (startSec == null || endSec == null) {
      throw Exception(
        'Clip ${clip.file.path} is missing start/end metadata; cannot sync.',
      );
    }

    hook ??= clip.title ?? p.basenameWithoutExtension(clip.file.path);

    final thumbPath = '${clip.file.path}.jpg';
    final thumbFile = File(thumbPath);
    if (!await thumbFile.exists()) {
      await widget.localVideoRepository.generateThumbnail(
        clip.file.path,
        thumbPath,
      );
    }

    return _ClipPayload(
      startSec: startSec,
      endSec: endSec,
      hook: hook,
      videoFile: clip.file,
      thumbFile: thumbFile,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = true;
    });
    final videos = await widget.localVideoRepository.getVideos();

    // Group videos
    final grouped = <String, List<VideoItem>>{};
    for (final video in videos) {
      final key =
          video.parentBasename ?? p.basenameWithoutExtension(video.file.path);
      grouped.putIfAbsent(key, () => []).add(video);
      if (!video.isClip && video.backendId != null) {
        _groupBackendIds[key] = video.backendId!;
      }
    }

    if (mounted) {
      setState(() {
        _videos = videos;
        _groupedVideos = grouped;
        _loading = false;
      });
    }
  }

  Future<void> _deleteVideo(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await widget.localVideoRepository.deleteVideo(path);
      await _loadVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: Text('Videos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('User'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text('Diagnostics'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _buildSelectedPage(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPage(BuildContext context) {
    return switch (_selectedIndex) {
      0 => _buildVideosView(context),
      1 => UserPage(
        authRepository: widget.authRepository,
        usersApi: widget.usersApi,
        diagnosticsLog: widget.diagnosticsLog,
        onOpenDiagnostics: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
        onLogout: widget.onLogout,
      ),
      _ => DiagnosticsPage(
        diagnosticsLog: widget.diagnosticsLog,
        service: StudioDiagnosticsService(
          appConfig: widget.appConfig,
          engineClient: widget.engineClient,
          dio: widget.dio,
          diagnosticsLog: widget.diagnosticsLog,
          engineStartup: () => widget.engineStartup,
        ),
      ),
    };
  }

  Widget _buildVideosView(BuildContext context) {
    final filteredKeys = _groupedVideos.keys.where((key) {
      return key.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    final totalSizeMb = _videos.fold<double>(
      0,
      (sum, v) => sum + v.file.statSync().size / (1024 * 1024),
    );

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVideos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(context, totalSizeMb),
                  if (_isAutoClipping)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16, top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quick Clipping Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _autoClipStatus,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (_autoClipTotal > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '$_autoClipCompleted / $_autoClipTotal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_autoClipTotal > 0) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _autoClipCompleted / _autoClipTotal,
                                minHeight: 6,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildSearchBar(context),
                  const SizedBox(height: 12),
                  if (filteredKeys.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...filteredKeys.map(
                      (key) => _buildVideoGroupCard(
                        context,
                        key,
                        _groupedVideos[key]!,
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => IngestPage(
                mediaService: MediaService(engineClient: widget.engineClient),
              ),
            ),
          );
          // Refresh list when returning
          await _loadVideos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ingest Video'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double totalSizeMb) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Videos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse ingested files, generate clips, '
                  'and sync with the backend.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      context,
                      Icons.video_collection_outlined,
                      '${_videos.length} files',
                    ),
                    _chip(
                      context,
                      Icons.sd_storage_rounded,
                      '${totalSizeMb.toStringAsFixed(1)} MB',
                    ),
                    _chip(context, Icons.refresh, 'Tap to refresh'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadVideos,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All Videos',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete All Videos?'),
                  content: const Text(
                    'This will permanently delete all videos in the workspace. '
                    'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );

              if (confirm ?? false) {
                await widget.localVideoRepository.deleteAllVideos();
                await _loadVideos();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All videos deleted')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search by filename...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text('No videos yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Ingest your first video to generate clips and transcripts.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => IngestPage(
                    mediaService: MediaService(
                      engineClient: widget.engineClient,
                    ),
                  ),
                ),
              );
              await _loadVideos();
            },
            icon: const Icon(Icons.add),
            label: const Text('Ingest Video'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGroupCard(
    BuildContext context,
    String groupKey,
    List<VideoItem> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Identify source video (not a clip)
    final sourceVideo = items.firstWhere(
      (item) => !item.isClip,
      orElse: () => items.first,
    );

    final clips = items.where((item) => item.isClip).toList()
      // Sort clips by creation time (newest first)
      ..sort((a, b) {
        final aModified = a.file.statSync().modified;
        final bModified = b.file.statSync().modified;
        return bModified.compareTo(aModified);
      });

    // Detect Ingest Type
    final sourceUrl = sourceVideo.sourceUrl ?? '';
    final isYouTube =
        sourceUrl.contains('youtube.com') || sourceUrl.contains('youtu.be');

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey(groupKey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: _buildThumbnail(
          sourceVideo,
          width: 100,
          height: 60,
          showBadges: true,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sourceVideo.title ?? p.basename(sourceVideo.file.path),
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Ingest source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isYouTube
                    ? Colors.red.withValues(alpha: 0.1)
                    : colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isYouTube ? 'YouTube Ingest' : 'Local Import',
                style: textTheme.labelSmall?.copyWith(
                  color: isYouTube
                      ? Colors.red.shade800
                      : colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _buildVideoStatsRow(context, sourceVideo, clips),
        ),
        children: [
          const Divider(height: 20),
          // Source video actions row (sleek compact filled tonal and filled buttons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              primary: false,
              controller: ScrollController(keepScrollOffset: false),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => VideoPlayerPage(
                            videoPath: sourceVideo.file.path,
                            repository: widget.localVideoRepository,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text(
                      'Play Source',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => VideoPlayerPage(
                            videoPath: sourceVideo.file.path,
                            repository: widget.localVideoRepository,
                            enableEditing: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline, size: 16),
                    label: const Text(
                      'Edit Clips',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await _showQuickClipSettingsSheet(
                        context,
                        sourceVideo,
                        groupKey,
                      );
                    },
                    icon: const Icon(Icons.content_cut, size: 16),
                    label: const Text(
                      'Quick Clip',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      await _syncAllForVideo(sourceVideo, clips, groupKey);
                    },
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text(
                      'Sync All',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteVideo(sourceVideo.file.path),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete Source',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (clips.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No clips created yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'Generated Clips',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            ...clips.map((clip) => _buildClipRow(context, clip, groupKey)),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoStatsRow(
    BuildContext context,
    VideoItem sourceVideo,
    List<VideoItem> clips,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalClips = clips.length;
    final syncedClips = clips.where((c) => c.synced).length;

    // Calculate total size including video file and clips
    int totalBytes = 0;
    try {
      if (sourceVideo.file.existsSync()) {
        totalBytes += sourceVideo.file.lengthSync();
      }
      for (final clip in clips) {
        if (clip.file.existsSync()) {
          totalBytes += clip.file.lengthSync();
        }
      }
    } catch (_) {}
    final sizeMb = totalBytes / (1024 * 1024);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Clips Count Badge
        _miniBadge(
          context,
          icon: Icons.movie_creation_outlined,
          label: '$totalClips clips',
          backgroundColor: colorScheme.secondaryContainer.withValues(
            alpha: 0.7,
          ),
          textColor: colorScheme.onSecondaryContainer,
          iconColor: colorScheme.onSecondaryContainer,
        ),
        // Sync Ratio Badge
        _miniBadge(
          context,
          icon: Icons.cloud_done_outlined,
          label: '$syncedClips/$totalClips Synced',
          backgroundColor: syncedClips == totalClips && totalClips > 0
              ? Colors.green.withValues(alpha: 0.15)
              : (syncedClips > 0
                    ? Colors.blue.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.8,
                      )),
          textColor: syncedClips == totalClips && totalClips > 0
              ? Colors.green.shade800
              : (syncedClips > 0
                    ? Colors.blue.shade800
                    : colorScheme.onSurfaceVariant),
          iconColor: syncedClips == totalClips && totalClips > 0
              ? Colors.green.shade800
              : (syncedClips > 0
                    ? Colors.blue.shade800
                    : colorScheme.onSurfaceVariant),
        ),
        // Workspace File Size Badge
        _miniBadge(
          context,
          icon: Icons.sd_storage_outlined,
          label: '${sizeMb.toStringAsFixed(1)} MB',
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
          textColor: colorScheme.onPrimaryContainer,
          iconColor: colorScheme.onPrimaryContainer,
        ),
        // Source Synced State
        _miniBadge(
          context,
          icon: sourceVideo.synced ? Icons.link : Icons.link_off,
          label: sourceVideo.synced ? 'Registered' : 'Local Only',
          backgroundColor: sourceVideo.synced
              ? Colors.teal.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.12),
          textColor: sourceVideo.synced
              ? Colors.teal.shade800
              : Colors.orange.shade800,
          iconColor: sourceVideo.synced
              ? Colors.teal.shade800
              : Colors.orange.shade800,
        ),
      ],
    );
  }

  Widget _miniBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    VideoItem item, {
    double width = 80,
    double height = 50,
    bool showBadges = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final imageWidget = item.thumbnailPath != null
        ? Image.file(
            File(item.thumbnailPath!),
            width: width,
            height: height,
            fit: BoxFit.cover,
          )
        : Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.video_file_outlined,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: height * 0.4,
            ),
          );

    if (!showBadges) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageWidget,
      );
    }

    final durationText = item.duration ?? '';
    final resolutionText = item.resolution ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: imageWidget),
            // Top-left resolution badge
            if (resolutionText.isNotEmpty)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    resolutionText.contains('x')
                        ? resolutionText.split('x')[1] + 'p'
                        : resolutionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Bottom-right duration badge
            if (durationText.isNotEmpty)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    durationText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipRow(BuildContext context, VideoItem clip, String groupKey) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final stat = clip.file.statSync();
    final sizeMb = (stat.size / (1024 * 1024)).toStringAsFixed(1);
    final name = clip.title ?? p.basename(clip.file.path);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _buildThumbnail(clip, width: 70, height: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$sizeMb MB',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (clip.duration != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              clip.duration!,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 9.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Play Clip',
                icon: const Icon(Icons.play_circle_outline, size: 20),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => VideoPlayerPage(
                        videoPath: clip.file.path,
                        repository: widget.localVideoRepository,
                      ),
                    ),
                  );
                },
              ),
              if (clip.synced)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_done,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                  tooltip: 'Sync Clip',
                  onPressed: () async {
                    try {
                      await _syncSingleClip(clip, sourceKey: groupKey);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clip synced successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      widget.diagnosticsLog.record('Sync clip', e);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e')),
                        );
                      }
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete Clip',
                onPressed: () => _deleteVideo(clip.file.path),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<void> _createAndUploadClip({
    required String videoPath,
    required Duration totalDuration,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputName =
        '${p.basenameWithoutExtension(videoPath)}_clip_$timestamp.mp4';
    final outputPath = p.join(p.dirname(videoPath), outputName);

    // Prompt for clip details
    Map<String, dynamic>? result;
    if (mounted) {
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => ClipCreationDialog(totalDuration: totalDuration),
      );
    }

    if (result == null) return; // User cancelled

    final clipTitle = result['title'] as String;
    final start = result['start'] as Duration;
    final duration = result['duration'] as Duration;
    final end = start + duration;

    try {
      await widget.localVideoRepository.renderClip(
        videoPath,
        start.inMilliseconds / 1000.0,
        end.inMilliseconds / 1000.0,
        outputPath,
      );

      // Write metadata for the clip
      final metaFile = File('$outputPath.meta.json');
      await metaFile.writeAsString('{"title": "$clipTitle"}');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clip created!')));

      // Reload to show the new clip
      await _loadVideos();

      if (_autoPromptNextClip && mounted) {
        final again = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Create another clip?'),
            content: const Text(
              'Clip created successfully. Want to queue another one?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if ((again ?? false) && mounted) {
          // Re-open dialog for the same video
          await _createAndUploadClip(
            videoPath: videoPath,
            totalDuration: totalDuration,
          );
        }
      }
    } catch (e) {
      widget.diagnosticsLog.record('Clip creation', e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Clip creation failed: $e')));
    }
  }

  Future<TranscriptResult?> _ensureTranscript(VideoItem sourceVideo) async {
    var transcript = await widget.localVideoRepository.getTranscript(
      sourceVideo.file.path,
    );
    if (transcript != null) return transcript;

    try {
      await widget.localVideoRepository.downloadTranscript(
        sourceVideo.file.path,
      );
      transcript = await widget.localVideoRepository.getTranscript(
        sourceVideo.file.path,
      );
    } catch (e) {
      widget.diagnosticsLog.record('Transcript download', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcript download failed: $e')),
        );
      }
    }
    return transcript;
  }

  int _durationSeconds(String? durationLabel) {
    if (durationLabel == null || durationLabel.isEmpty) return 0;
    final parts = durationLabel.split(':').map(int.tryParse).toList();
    if (parts.length == 3 &&
        parts[0] != null &&
        parts[1] != null &&
        parts[2] != null) {
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    }
    if (parts.length == 2 && parts[0] != null && parts[1] != null) {
      return parts[0]! * 60 + parts[1]!;
    }
    return int.tryParse(durationLabel) ?? 0;
  }

  String _formatSeconds(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '$mins:${secs.toString().padLeft(2, "0")}';
  }

  Future<void> _showQuickClipSettingsSheet(
    BuildContext context,
    VideoItem sourceVideo,
    String groupKey,
  ) async {
    final existingClips = await widget.localVideoRepository
        .loadLocalClipsForSource(sourceVideo.file.path);

    int durationSecs = _durationSeconds(sourceVideo.duration);
    if (durationSecs <= 1) {
      final probed = await widget.localVideoRepository.probeDurationSeconds(
        sourceVideo.file.path,
      );
      if (probed != null && probed > 0) {
        durationSecs = probed;
      }
    }

    final gaps = calculateTimelineGaps(existingClips, durationSecs.toDouble());
    final totalGapSecs = gaps
        .fold<double>(0.0, (prev, element) => prev + (element[1] - element[0]))
        .toInt();

    String durationPreset = 'medium';
    bool gapsOnly = true;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.content_cut,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quick Clip Settings',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatically detect highlights and render clips locally using the Media Engine sidecar.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CLIP DURATION',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChoiceChip(
                          context,
                          label: 'Short (10-15s)',
                          selected: durationPreset == 'short',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => durationPreset = 'short');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          context,
                          label: 'Medium (30-45s)',
                          selected: durationPreset == 'medium',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => durationPreset = 'medium');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          context,
                          label: 'Long (60-90s)',
                          selected: durationPreset == 'long',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => durationPreset = 'long');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'TIMELINE TARGET',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              gapsOnly
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: gapsOnly
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            title: const Text(
                              'Unclipped Gaps Only (Recommended)',
                            ),
                            subtitle: Text(
                              existingClips.isEmpty
                                  ? 'Targets the entire video (${_formatSeconds(durationSecs)})'
                                  : 'Targets ${gaps.length} timeline gaps (total ${_formatSeconds(totalGapSecs)})',
                            ),
                            onTap: () {
                              setModalState(() => gapsOnly = true);
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: Icon(
                              !gapsOnly
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: !gapsOnly
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            title: const Text('Entire Video'),
                            subtitle: Text(
                              'Ignores existing clips and re-segments all ${sourceVideo.duration ?? ""}',
                            ),
                            onTap: () {
                              setModalState(() => gapsOnly = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _autoCreateClipsFromHighlights(
                          groupKey,
                          sourceVideo,
                          durationPreset: durationPreset,
                          gapsOnly: gapsOnly,
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            existingClips.isEmpty
                                ? 'GENERATE CLIPS'
                                : gapsOnly
                                ? 'GENERATE CLIPS IN GAPS'
                                : 'RE-GENERATE ALL CLIPS',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _autoCreateClipsFromHighlights(
    String groupKey,
    VideoItem sourceVideo, {
    String durationPreset = 'medium',
    bool gapsOnly = true,
  }) async {
    if (_isAutoClipping) return;

    setState(() {
      _isAutoClipping = true;
      _autoClipStatus = 'Ensuring transcript...';
      _autoClipCompleted = 0;
      _autoClipTotal = 0;
    });

    try {
      final transcript = await _ensureTranscript(sourceVideo);
      if (transcript == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transcript available for highlights'),
            ),
          );
        }
        return;
      }

      var effectiveDuration = _durationSeconds(
        sourceVideo.duration,
      ).clamp(1, 24 * 3600);
      if (effectiveDuration <= 1) {
        final probed = await widget.localVideoRepository.probeDurationSeconds(
          sourceVideo.file.path,
        );
        if (probed != null && probed > 0) {
          effectiveDuration = probed;
        }
      }
      if (effectiveDuration <= 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to determine video duration for highlights',
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _autoClipStatus = 'Requesting highlights...';
      });

      HighlightResponse highlightResult;
      try {
        highlightResult = await widget.localVideoRepository.detectHighlights(
          transcript.text,
          effectiveDuration,
          transcriptLanguage: transcript.languageCode,
          videoPath: sourceVideo.file.path,
          durationPreset: durationPreset,
          gapsOnly: gapsOnly,
        );
      } catch (e) {
        widget.diagnosticsLog.record('Highlight detection', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Highlights failed: $e')));
        }
        return;
      }

      final clips = highlightResult.clips;
      if (clips.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Highlights unavailable; no clips created'),
            ),
          );
        }
        return;
      }

      final videoId = await _ensureBackendVideo(groupKey, sourceVideo);

      _autoClipTotal = clips.length;
      var successCount = 0;

      for (var i = 0; i < clips.length; i++) {
        final clip = clips[i];
        setState(() {
          _autoClipStatus =
              'Rendering clip ${i + 1} (${clip.startSec}-${clip.endSec}s)';
        });
        try {
          await _renderUploadAndCreateClip(
            sourceVideo: sourceVideo,
            suggestion: clip,
            videoId: videoId,
          );
          successCount++;
        } catch (e) {
          widget.diagnosticsLog.record('Auto clip render', e);
          debugPrint('Auto clip ${i + 1} failed: $e');
        }
        setState(() {
          _autoClipCompleted = i + 1;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto clips created: $successCount/${clips.length}'),
          ),
        );
        await _loadVideos();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoClipping = false;
          _autoClipStatus = '';
          _autoClipCompleted = 0;
          _autoClipTotal = 0;
        });
      }
    }
  }

  Future<void> _renderUploadAndCreateClip({
    required VideoItem sourceVideo,
    required SuggestedClip suggestion,
    required int videoId,
  }) async {
    final outputBase =
        '${p.basenameWithoutExtension(sourceVideo.file.path)}_'
        '${suggestion.startSec}_${suggestion.endSec}_'
        '${DateTime.now().millisecondsSinceEpoch}';
    final outputPath = p.join(
      p.dirname(sourceVideo.file.path),
      '$outputBase.mp4',
    );
    final thumbPath = '$outputPath.jpg';

    await widget.localVideoRepository.renderClip(
      sourceVideo.file.path,
      suggestion.startSec.toDouble(),
      suggestion.endSec.toDouble(),
      outputPath,
    );
    await widget.localVideoRepository.generateThumbnail(outputPath, thumbPath);

    final outputFile = File(outputPath);
    final thumbFile = File(thumbPath);
    final parentBase = p.basenameWithoutExtension(sourceVideo.file.path);
    final clipDuration = Duration(
      seconds: suggestion.endSec - suggestion.startSec,
    );

    // Write meta early to keep grouping even if uploads fail.
    final metaFile = File('$outputPath.meta.json');
    final meta = {
      'title': suggestion.hook,
      'is_clip': true,
      'parent_basename': parentBase,
      'duration':
          '${clipDuration.inMinutes}:'
          '${(clipDuration.inSeconds % 60).toString().padLeft(2, '0')}',
      'start_sec': suggestion.startSec,
      'end_sec': suggestion.endSec,
      'hook': suggestion.hook,
    };
    await metaFile.writeAsString(jsonEncode(meta));

    final assetUrl = await widget.localVideoRepository.uploadAsset(outputFile);
    final thumbUrl = await widget.localVideoRepository.uploadAsset(thumbFile);

    // Save synced state to meta file
    meta['synced'] = true;
    meta['asset_url'] = assetUrl;
    meta['thumbnail_url'] = thumbUrl;
    meta['parent_backend_id'] = videoId;
    await metaFile.writeAsString(jsonEncode(meta));

    final stat = await outputFile.stat();

    final clip = ClipUpsert(
      startSec: suggestion.startSec,
      endSec: suggestion.endSec,
      assetUrl: assetUrl,
      thumbnailPath: thumbUrl,
      captionText: suggestion.hook,
      fileSizeBytes: stat.size,
    );

    await widget.localVideoRepository.createClipForVideo(videoId, clip);
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _ClipPayload {
  _ClipPayload({
    required this.startSec,
    required this.endSec,
    required this.hook,
    required this.videoFile,
    required this.thumbFile,
  });

  final int startSec;
  final int endSec;
  final String hook;
  final File videoFile;
  final File thumbFile;
}
