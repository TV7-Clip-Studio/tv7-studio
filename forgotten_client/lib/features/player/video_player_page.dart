// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    required this.videoPath,
    required this.repository,
    super.key,
  });

  final String videoPath;
  final ClientVideoRepository repository;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player player;
  late final VideoController controller;
  Duration? _start;
  Duration? _end;
  int? _selectedClipIndex;
  final TextEditingController _hookController = TextEditingController();
  bool _isProcessing = false;
  List<SuggestedClip> _suggestedClips = [];
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    player.open(Media(widget.videoPath));
  }

  @override
  void dispose() {
    _hookController.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> _detectHighlights() async {
    setState(() => _isDetecting = true);
    try {
      var transcript = await widget.repository.getTranscript(widget.videoPath);
      var transcriptLanguage = transcript?.languageCode;

      if (transcript == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transcript not found. Attempting to download...'),
            ),
          );
        }

        try {
          await widget.repository.downloadTranscript(widget.videoPath);
          transcript = await widget.repository.getTranscript(widget.videoPath);
          transcriptLanguage = transcript?.languageCode;
        } catch (e) {
          debugPrint('Failed to download transcript: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not download transcript: $e')),
            );
          }
          return;
        }
      }

      if (transcript == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No transcript available even after download attempt.',
              ),
            ),
          );
        }
        return;
      }

      final duration = player.state.duration.inSeconds;
      if (duration == 0) {
        // Wait a bit for duration to be available if player just opened
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      final clips = await widget.repository.detectHighlights(
        transcript.text,
        player.state.duration.inSeconds,
        transcriptLanguage: transcriptLanguage,
      );

      if (mounted) {
        setState(() {
          _suggestedClips = clips;
          if (clips.isNotEmpty) {
            _selectClip(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Detection failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  Future<void> _createClip() async {
    if (_start == null || _end == null) return;
    if (_end! <= _start!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Ensure parent video is synced
      final metaFile = File('${widget.videoPath}.meta.json');
      if (!await metaFile.exists()) {
        // Should not happen if ingested correctly
        throw Exception('Video metadata missing. Please re-ingest.');
      }

      // Let's reconstruct a minimal VideoItem
      final item = VideoItem(file: File(widget.videoPath));
      final video = await widget.repository.syncVideo(item);
      final videoId = video.id;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputName =
          '${p.basenameWithoutExtension(widget.videoPath)}_clip_$timestamp.mp4';
      final outputPath = p.join(p.dirname(widget.videoPath), outputName);
      final thumbPath = '$outputPath.jpg';

      // 2. Render Clip
      await widget.repository.runner.renderClip(
        widget.videoPath,
        _start!.inMilliseconds / 1000.0,
        _end!.inMilliseconds / 1000.0,
        outputPath,
      );

      // 3. Generate Thumbnail (from middle of clip)
      await widget.repository.runner.generateThumbnail(outputPath, thumbPath);

      // 4. Upload Assets
      final assetUrl = await widget.repository.uploadAsset(File(outputPath));
      final thumbUrl = await widget.repository.uploadAsset(File(thumbPath));

      // 5. Create Clip Entity
      final clip = ClipUpsert(
        startSec: _start!.inSeconds,
        endSec: _end!.inSeconds,
        assetUrl: assetUrl,
        thumbnailPath:
            thumbUrl, // We use thumbnailPath field for the URL in this context
        captionText: _selectedClipIndex != null
            ? _suggestedClips[_selectedClipIndex!].hook
            : null,
      );

      await widget.repository.createClipForVideo(videoId, clip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clip created and linked to video successfully!'),
          ),
        );
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message} ${data ?? ''}')),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _selectClip(int index) {
    final clip = _suggestedClips[index];
    setState(() {
      _selectedClipIndex = index;
      _start = Duration(seconds: clip.startSec);
      _end = Duration(seconds: clip.endSec);
      _hookController.text = clip.hook;
    });
    player.seek(Duration(seconds: clip.startSec));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
        actions: [
          if (_isDetecting)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Auto-Detect Clips',
              onPressed: _detectHighlights,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 2, child: Video(controller: controller)),
          if (_suggestedClips.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _suggestedClips.length,
                      itemBuilder: (context, index) {
                        final clip = _suggestedClips[index];
                        final selected = index == _selectedClipIndex;
                        final start = _formatDuration(
                          Duration(seconds: clip.startSec),
                        );
                        final end = _formatDuration(
                          Duration(seconds: clip.endSec),
                        );
                        return ListTile(
                          leading: const Icon(Icons.movie_creation_outlined),
                          title: Text(
                            clip.hook,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('$start - $end'),
                          selected: selected,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.08),
                          onTap: () => _selectClip(index),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _hookController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Edit hook text',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FilledButton.tonal(
                              onPressed: _start != null
                                  ? () => setState(
                                      () => _start = player.state.position,
                                    )
                                  : null,
                              child: Text(
                                'Set Start: ${_formatDuration(_start)}',
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: _end != null
                                  ? () => setState(
                                      () => _end = player.state.position,
                                    )
                                  : null,
                              child: Text('Set End: ${_formatDuration(_end)}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed:
                              (_start != null &&
                                  _end != null &&
                                  _selectedClipIndex != null)
                              ? () {
                                  // Update selected clip hook before upload
                                  final idx = _selectedClipIndex!;
                                  _suggestedClips[idx] = SuggestedClip(
                                    startSec: _start!.inSeconds,
                                    endSec: _end!.inSeconds,
                                    hook: _hookController.text.trim().isEmpty
                                        ? _suggestedClips[idx].hook
                                        : _hookController.text.trim(),
                                  );
                                  _createClip();
                                }
                              : null,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Send Clip'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_isProcessing)
            const LinearProgressIndicator()
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
