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
  Map<String, List<VideoItem>> _groupedVideos = {};
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

    // Group videos
    final grouped = <String, List<VideoItem>>{};
    for (final video in videos) {
      final key =
          video.parentBasename ?? p.basenameWithoutExtension(video.file.path);
      grouped.putIfAbsent(key, () => []).add(video);
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

  Widget _buildVideoGroupCard(
    BuildContext context,
    String groupKey,
    List<VideoItem> items,
  ) {
    // Identify source video (not a clip)
    final sourceVideo = items.firstWhere(
      (item) => !item.isClip,
      orElse: () => items
          .first, // Fallback if only clips exist (shouldn't happen ideally)
    );

    final clips = items.where((item) => item.isClip).toList()
      // Sort clips by creation time (newest first)
      ..sort((a, b) {
        final aModified = a.file.statSync().modified;
        final bModified = b.file.statSync().modified;
        return bModified.compareTo(aModified);
      });

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: _buildThumbnail(sourceVideo),
        title: Text(
          sourceVideo.title ?? p.basename(sourceVideo.file.path),
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${clips.length} clips • '
          '${sourceVideo.duration ?? "Unknown duration"}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // Source video actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
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
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Source'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  const start = Duration.zero;
                  final end = _parseDurationLabel(sourceVideo.duration);
                  await _createAndUploadClip(
                    videoPath: sourceVideo.file.path,
                    start: start,
                    end: end,
                    hook:
                        'New clip from '
                        '${p.basenameWithoutExtension(sourceVideo.file.path)}',
                  );
                },
                icon: const Icon(Icons.content_cut),
                label: const Text('Quick Clip'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteVideo(sourceVideo.file.path),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Source',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const Divider(),
          if (clips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No clips created yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...clips.map((clip) => _buildClipRow(context, clip)),
        ],
      ),
    );
  }

  Widget _buildThumbnail(VideoItem item) {
    return item.thumbnailPath != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(item.thumbnailPath!),
              width: 60,
              height: 40,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            width: 60,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.video_file_outlined,
              color: Colors.grey,
              size: 20,
            ),
          );
  }

  Widget _buildClipRow(BuildContext context, VideoItem clip) {
    final stat = clip.file.statSync();
    final sizeMb = (stat.size / (1024 * 1024)).toStringAsFixed(1);
    // Prefer the title; fallback to filename.
    final name = clip.title ?? p.basename(clip.file.path);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _buildThumbnail(clip),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('$sizeMb MB • ${clip.duration ?? "Unknown"}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Play Clip',
            icon: const Icon(Icons.play_circle_outline),
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
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Sync Clip to Backend',
            onPressed: () async {
              try {
                await widget.localVideoRepository.syncVideo(clip);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clip synced successfully')),
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
            onPressed: () => _deleteVideo(clip.file.path),
          ),
        ],
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

    // Prompt for title
    String? clipTitle;
    if (mounted) {
      clipTitle = await showDialog<String>(
        context: context,
        builder: (context) {
          var value = hook;
          return AlertDialog(
            title: const Text('Name your clip'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter clip title'),
              controller: TextEditingController(text: value),
              onChanged: (v) => value = v,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, value),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    }

    if (clipTitle == null) return; // User cancelled

    try {
      await toolRunner.renderClip(
        videoPath,
        start.inMilliseconds / 1000.0,
        end.inMilliseconds / 1000.0,
        outputPath,
      );

      // Write meta so the title persists until a backend sync happens.
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
      ).showSnackBar(SnackBar(content: Text('Clip creation failed: $e')));
    }
  }

  Duration _parseDurationLabel(String? label) {
    if (label == null || label.isEmpty) {
      return const Duration(seconds: 30);
    }

    final parts = label.split(':').map(int.tryParse).toList();
    if (parts.length == 3 &&
        parts[0] != null &&
        parts[1] != null &&
        parts[2] != null) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }

    if (parts.length == 2 && parts[0] != null && parts[1] != null) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }

    final seconds = int.tryParse(label);
    return Duration(seconds: seconds ?? 30);
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
