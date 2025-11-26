import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/config/config_repository.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/data/local/media_service.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
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
    required this.usersApi,
    required this.onLogout,
    super.key,
  });

  final ConfigRepository configRepository;
  final LocalVideoRepository localVideoRepository;
  final AuthRepository authRepository;
  final UsersApi usersApi;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  List<VideoItem> _videos = [];
  bool _loading = true;
  String _search = '';
  final bool _autoPromptNextClip = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = true;
    });
    final videos = await widget.localVideoRepository.getVideos();
    if (mounted) {
      setState(() {
        _videos = videos;
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
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _selectedIndex == 0
                  ? _buildVideosView(context)
                  : UserPage(
                      authRepository: widget.authRepository,
                      usersApi: widget.usersApi,
                      onLogout: widget.onLogout,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosView(BuildContext context) {
    final filtered = _videos.where((v) {
      final name = p.basename(v.file.path).toLowerCase();
      return name.contains(_search.toLowerCase());
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
                  const SizedBox(height: 16),
                  _buildSearchBar(context),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...filtered.map((v) => _buildVideoCard(context, v)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => IngestPage(
                mediaService: MediaService(toolRunner: ToolRunner()),
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
                    mediaService: MediaService(toolRunner: ToolRunner()),
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

  Widget _buildVideoCard(BuildContext context, VideoItem item) {
    final stat = item.file.statSync();
    final name = item.title?.isNotEmpty ?? false
        ? item.title!
        : p.basename(item.file.path);
    final sizeMb = (stat.size / (1024 * 1024)).toStringAsFixed(1);
    final date = stat.modified.toString().split('.')[0];

    final details = [
      '$sizeMb MB',
      date,
      if (item.duration != null) item.duration,
      if (item.resolution != null) item.resolution,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: item.thumbnailPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.thumbnailPath!),
                  width: 90,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 90,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.video_file_outlined,
                  color: Colors.grey,
                ),
              ),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(details),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Open',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (context) => VideoPlayerPage(
                      videoPath: item.file.path,
                      repository: widget.localVideoRepository,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Create clip from list',
              icon: const Icon(Icons.content_cut_outlined),
              onPressed: () async {
                const start = Duration.zero;
                final end = Duration(
                  seconds: item.duration != null
                      ? int.tryParse(item.duration!.split(':').first) ?? 30
                      : 30,
                );
                await _createAndUploadClip(
                  videoPath: item.file.path,
                  start: start,
                  end: end,
                  hook:
                      'New clip from '
                      '${p.basenameWithoutExtension(item.file.path)}',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Sync to Backend',
              onPressed: () async {
                try {
                  await widget.localVideoRepository.syncVideo(item);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Video synced successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteVideo(item.file.path),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => VideoPlayerPage(
                videoPath: item.file.path,
                repository: widget.localVideoRepository,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createAndUploadClip({
    required String videoPath,
    required Duration start,
    required Duration end,
    required String hook,
  }) async {
    final toolRunner = widget.localVideoRepository.runner;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputName =
        '${p.basenameWithoutExtension(videoPath)}_clip_$timestamp.mp4';
    final outputPath = p.join(p.dirname(videoPath), outputName);
    try {
      await toolRunner.renderClip(
        videoPath,
        start.inMilliseconds / 1000.0,
        end.inMilliseconds / 1000.0,
        outputPath,
      );
      final assetUrl = await widget.localVideoRepository.uploadAsset(
        File(outputPath),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Clip uploaded! URL: $assetUrl')));
      if (_autoPromptNextClip && mounted) {
        final again = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Create another clip?'),
            content: const Text(
              'Clip uploaded successfully. Want to queue another one?',
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
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => VideoPlayerPage(
                videoPath: videoPath,
                repository: widget.localVideoRepository,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Clip upload failed: $e')));
    }
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
