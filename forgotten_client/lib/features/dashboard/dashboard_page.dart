import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../data/config/config_repository.dart';
import '../../data/local/local_video_repository.dart';
import '../../data/local/media_service.dart';
import '../../data/local/tool_runner.dart';
import '../ingest/ingest_page.dart';
import '../player/video_player_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.configRepository,
    required this.localVideoRepository,
  });

  final ConfigRepository configRepository;
  final LocalVideoRepository localVideoRepository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<VideoItem> _videos = [];
  bool _loading = true;

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

    if (confirm == true) {
      await widget.localVideoRepository.deleteVideo(path);
      await _loadVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Videos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVideos,
              child: _videos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No videos found.\nTap + to ingest a video.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final item = _videos[index];
                        final stat = item.file.statSync();
                        final name = p.basename(item.file.path);
                        final sizeMb = (stat.size / (1024 * 1024)).toStringAsFixed(1);
                        final date = stat.modified.toString().split('.')[0];
                        
                        final details = [
                          '$sizeMb MB',
                          date,
                          if (item.duration != null) item.duration,
                          if (item.resolution != null) item.resolution,
                        ].join(' • ');

                        return ListTile(
                          leading: item.thumbnailPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(item.thumbnailPath!),
                                    width: 80,
                                    height: 45,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.video_file, size: 40),
                          title: Text(name),
                          subtitle: Text(details),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.cloud_upload_outlined),
                                tooltip: 'Sync to Backend',
                                onPressed: () async {
                                  try {
                                    await widget.localVideoRepository.syncVideo(item);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Video synced successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Sync failed: $e')),
                                      );
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  videoPath: item.file.path,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => IngestPage(
                mediaService: MediaService(toolRunner: ToolRunner()),
              ),
            ),
          );
          // Refresh list when returning
          _loadVideos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ingest Video'),
      ),
    );
  }
}
