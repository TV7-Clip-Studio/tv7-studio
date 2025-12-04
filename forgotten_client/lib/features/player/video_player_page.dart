// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart' as api;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    required this.videoPath,
    required this.repository,
    this.enableEditing = false,
    super.key,
  });

  final String videoPath;
  final ClientVideoRepository repository;
  final bool enableEditing;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player player;
  late final VideoController controller;
  Duration? _start;
  Duration? _end;
  Duration _playhead = Duration.zero;
  Duration? _duration;
  int? _selectedClipIndex;
  final TextEditingController _hookController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startFieldController = TextEditingController();
  final TextEditingController _endFieldController = TextEditingController();
  bool _isProcessing = false;
  List<api.SuggestedClip> _suggestedClips = [];
  bool _isDetecting = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  final Duration _snapStep = const Duration(seconds: 1);
  final Duration _minClipLength = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    _listenToPlayerStreams();
    player.open(Media(widget.videoPath));
    _primeLocalClips();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _hookController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _startFieldController.dispose();
    _endFieldController.dispose();
    player.dispose();
    super.dispose();
  }

  Widget _buildClipListPane({bool scrollable = false}) {
    if (_suggestedClips.isEmpty) {
      return const SizedBox.shrink();
    }
    final content = _buildClipEditorPanel(scrollable: scrollable);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: content,
    );
  }

  void _listenToPlayerStreams() {
    _positionSub = player.stream.position.listen((pos) {
      if (!mounted) return;
      setState(() {
        _playhead = pos;
      });
    });
    _durationSub = player.stream.duration.listen((dur) {
      if (!mounted) return;
      if (dur.inMilliseconds <= 0) return;
      setState(() {
        _duration = dur;
      });
    });
  }

  Future<void> _primeLocalClips() async {
    final localClips = await widget.repository.loadLocalClipsForSource(
      widget.videoPath,
    );
    if (!mounted) return;
    setState(() {
      _suggestedClips = localClips;
      if (_suggestedClips.isNotEmpty) {
        _selectClip(0);
      }
    });
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

      var durationSeconds = (_duration ?? player.state.duration).inSeconds;
      if (durationSeconds == 0) {
        // Wait a bit for duration to be available if player just opened
        await Future<void>.delayed(const Duration(seconds: 1));
        durationSeconds = (_duration ?? player.state.duration).inSeconds;
      }

      final highlightResponse = await widget.repository.detectHighlights(
        transcript.text,
        durationSeconds,
        transcriptLanguage: transcriptLanguage,
      );

      if (mounted) {
        setState(() {
          _suggestedClips = highlightResponse.clips;
          if (_suggestedClips.isNotEmpty) {
            _selectClip(0);
          } else {
            _selectedClipIndex = null;
            _start = null;
            _end = null;
            _startFieldController.clear();
            _endFieldController.clear();
            _hookController.clear();
            _titleController.clear();
            _descriptionController.clear();
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
      final clip = api.ClipUpsert(
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
    final totalSeconds = d.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Duration? _parseDurationInput(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;
    final parts = input.split(':').map((p) => p.trim()).toList();
    int seconds = 0;
    if (parts.length == 1) {
      final value = int.tryParse(parts[0]);
      if (value == null) return null;
      seconds = value;
    } else if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m == null || s == null) return null;
      seconds = m * 60 + s;
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h == null || m == null || s == null) return null;
      seconds = h * 3600 + m * 60 + s;
    } else {
      return null;
    }
    if (seconds < 0) seconds = 0;
    return Duration(seconds: seconds);
  }

  void _selectClip(int index) {
    final clip = _suggestedClips[index];
    setState(() {
      _selectedClipIndex = index;
      _start = Duration(seconds: clip.startSec);
      _end = Duration(seconds: clip.endSec);
      _hookController.text = clip.hook;
      _titleController.text = clip.title;
      _descriptionController.text = clip.description;
      _startFieldController.text = _formatDuration(_start);
      _endFieldController.text = _formatDuration(_end);
    });
    player.seek(Duration(seconds: clip.startSec));
  }

  Duration _snapDuration(Duration value) {
    final step = _snapStep.inMilliseconds;
    if (step <= 0) return value;
    return Duration(milliseconds: (value.inMilliseconds / step).round() * step);
  }

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  void _applyTimeFields() {
    final idx = _selectedClipIndex;
    if (idx == null) return;
    final duration = _duration ?? player.state.duration;
    if (duration.inMilliseconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration not available yet')),
      );
      return;
    }
    if (duration <= _minClipLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video is too short for clip editing')),
      );
      return;
    }
    final start = _parseDurationInput(_startFieldController.text);
    final end = _parseDurationInput(_endFieldController.text);
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use mm:ss or seconds for start/end')),
      );
      return;
    }
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    final clampedStart = _clampDuration(
      _snapDuration(start),
      Duration.zero,
      duration - _minClipLength,
    );
    final clampedEnd = _clampDuration(
      _snapDuration(end),
      clampedStart + _minClipLength,
      duration,
    );
    _updateSelectedClipBounds(clampedStart, clampedEnd);
  }

  void _updateSelectedClipBounds(Duration start, Duration end) {
    final idx = _selectedClipIndex;
    if (idx == null) return;
    final clip = _suggestedClips[idx];
    setState(() {
      _start = start;
      _end = end;
      _suggestedClips[idx] = api.SuggestedClip(
        startSec: start.inSeconds,
        endSec: end.inSeconds,
        title: clip.title,
        description: clip.description,
        hook: clip.hook,
      );
      _startFieldController.text = _formatDuration(_start);
      _endFieldController.text = _formatDuration(_end);
    });
  }

  void _adjustSelectedClip({
    required double deltaPx,
    required double trackWidth,
    required Duration duration,
    required bool isStartHandle,
  }) {
    if (duration <= _minClipLength) return;
    final idx = _selectedClipIndex;
    if (idx == null) return;
    final clip = _suggestedClips[idx];
    var currentStart = _start ?? Duration(seconds: clip.startSec);
    var currentEnd = _end ?? Duration(seconds: clip.endSec);
    if (trackWidth <= 0 || duration.inMilliseconds <= 0) return;

    final deltaMs = (deltaPx / trackWidth * duration.inMilliseconds)
        .round()
        .toInt();
    if (isStartHandle) {
      currentStart += Duration(milliseconds: deltaMs);
      currentStart = _snapDuration(
        _clampDuration(currentStart, Duration.zero, duration - _minClipLength),
      );
      if (currentStart >= currentEnd) {
        currentEnd = currentStart + _minClipLength;
      }
    } else {
      currentEnd += Duration(milliseconds: deltaMs);
      currentEnd = _snapDuration(
        _clampDuration(currentEnd, currentStart + _minClipLength, duration),
      );
    }

    currentStart = _clampDuration(
      currentStart,
      Duration.zero,
      duration - _minClipLength,
    );
    currentEnd = _clampDuration(
      currentEnd,
      currentStart + _minClipLength,
      duration,
    );

    _updateSelectedClipBounds(currentStart, currentEnd);
  }

  void _moveSelectedClipBy({
    required double deltaPx,
    required double trackWidth,
    required Duration duration,
  }) {
    final idx = _selectedClipIndex;
    if (idx == null) return;
    if (duration <= _minClipLength) return;
    final clip = _suggestedClips[idx];
    var currentStart = _start ?? Duration(seconds: clip.startSec);
    var currentEnd = _end ?? Duration(seconds: clip.endSec);
    if (trackWidth <= 0 || duration.inMilliseconds <= 0) return;

    final deltaMs = (deltaPx / trackWidth * duration.inMilliseconds)
        .round()
        .toInt();
    final delta = Duration(milliseconds: deltaMs);

    currentStart += delta;
    currentEnd += delta;

    // Clamp to bounds
    if (currentStart < Duration.zero) {
      final diff = Duration.zero - currentStart;
      currentStart += diff;
      currentEnd += diff;
    }
    if (currentEnd > duration) {
      final diff = currentEnd - duration;
      currentStart -= diff;
      currentEnd -= diff;
    }
    currentStart = _snapDuration(
      _clampDuration(currentStart, Duration.zero, duration - _minClipLength),
    );
    currentEnd = _snapDuration(
      _clampDuration(currentEnd, currentStart + _minClipLength, duration),
    );

    _updateSelectedClipBounds(currentStart, currentEnd);
  }

  void _seekFromTrack(double dx, double width, Duration duration) {
    if (width <= 0 || duration.inMilliseconds <= 0) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    final targetMs = (ratio * duration.inMilliseconds).round();
    final target = Duration(milliseconds: targetMs);
    player.seek(target);
    setState(() {
      _playhead = target;
    });
  }

  Widget _buildTimelineCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveDuration =
        _duration ??
        (player.state.duration.inMilliseconds > 0
            ? player.state.duration
            : null);
    final hasDuration =
        effectiveDuration != null && effectiveDuration.inMilliseconds > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Timeline'),
              const Spacer(),
              if (hasDuration)
                Text(
                  '${_formatDuration(_playhead)} / ${_formatDuration(effectiveDuration)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasDuration)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading video duration...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )
          else
            SizedBox(
              height: 80,
              child: _buildTimelineTrack(context, effectiveDuration),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineTrack(BuildContext context, Duration duration) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final playheadRatio =
            (_playhead.inMilliseconds / duration.inMilliseconds).clamp(
              0.0,
              1.0,
            );
        final playheadX = playheadRatio * width;

        final clipWidgets = <Widget>[];
        for (var i = 0; i < _suggestedClips.length; i++) {
          final clip = _suggestedClips[i];
          final startMs = (clip.startSec * 1000).clamp(
            0,
            duration.inMilliseconds,
          );
          final endMs = (clip.endSec * 1000).clamp(0, duration.inMilliseconds);
          if (endMs <= startMs) continue;
          final startX = width * (startMs / duration.inMilliseconds);
          final endX = width * (endMs / duration.inMilliseconds);
          final spanWidth = (endX - startX).clamp(8.0, width).toDouble();
          final selected = i == _selectedClipIndex;

          clipWidgets.add(
            Positioned(
              left: startX,
              width: spanWidth,
              top: 20,
              height: 22,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _selectClip(i),
                  onHorizontalDragUpdate: selected
                      ? (details) => _moveSelectedClipBy(
                          deltaPx: details.delta.dx,
                          trackWidth: width,
                          duration: duration,
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: selected
                          ? colorScheme.primary.withValues(alpha: 0.35)
                          : colorScheme.secondary.withValues(alpha: 0.3),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          if (selected) {
            const handleWidth = 12.0;
            clipWidgets.add(
              Positioned(
                left: (startX - handleWidth / 2).clamp(0.0, width).toDouble(),
                top: 12,
                width: handleWidth,
                height: 38,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) => _adjustSelectedClip(
                      deltaPx: details.delta.dx,
                      trackWidth: width,
                      duration: duration,
                      isStartHandle: true,
                    ),
                  ),
                ),
              ),
            );
            clipWidgets.add(
              Positioned(
                left: (startX + spanWidth - handleWidth / 2)
                    .clamp(0.0, width)
                    .toDouble(),
                top: 12,
                width: handleWidth,
                height: 38,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) => _adjustSelectedClip(
                      deltaPx: details.delta.dx,
                      trackWidth: width,
                      duration: duration,
                      isStartHandle: false,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                _seekFromTrack(details.localPosition.dx, width, duration),
            onHorizontalDragUpdate: (details) =>
                _seekFromTrack(details.localPosition.dx, width, duration),
            child: Stack(
              children: [
                Positioned.fill(
                  top: 26,
                  bottom: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
                ...clipWidgets,
                Positioned(
                  left: playheadX.clamp(0.0, width).toDouble(),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClipEditorPanel({bool scrollable = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Clips', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: _isDetecting ? null : _detectHighlights,
              icon: const Icon(Icons.add),
              label: const Text('Create new clips'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.builder(
            shrinkWrap: true,
            controller: scrollable
                ? ScrollController()
                : PrimaryScrollController.of(context),
            physics: scrollable
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: _suggestedClips.length,
            itemBuilder: (context, index) {
              final clip = _suggestedClips[index];
              final selected = index == _selectedClipIndex;
              final start = _formatDuration(Duration(seconds: clip.startSec));
              final end = _formatDuration(Duration(seconds: clip.endSec));
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
      ],
    );
  }

  Widget _buildTimelineAndEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTimelineCard(context),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startFieldController,
                decoration: const InputDecoration(
                  labelText: 'Start (mm:ss or seconds)',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: _applyTimeFields,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _endFieldController,
                decoration: const InputDecoration(
                  labelText: 'End (mm:ss or seconds)',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: _applyTimeFields,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hookController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Hook',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed:
              (_start != null && _end != null && _selectedClipIndex != null)
              ? () {
                  final idx = _selectedClipIndex!;
                  setState(() {
                    _suggestedClips[idx] = api.SuggestedClip(
                      startSec: _start!.inSeconds,
                      endSec: _end!.inSeconds,
                      title: _titleController.text.trim().isEmpty
                          ? _suggestedClips[idx].title
                          : _titleController.text.trim(),
                      description: _descriptionController.text.trim().isEmpty
                          ? _suggestedClips[idx].description
                          : _descriptionController.text.trim(),
                      hook: _hookController.text.trim().isEmpty
                          ? _suggestedClips[idx].hook
                          : _hookController.text.trim(),
                    );
                  });
                  _createClip();
                }
              : null,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildStandardLayout() {
    return Column(
      children: [
        _buildVideoViewport(),
        Expanded(
          child: _suggestedClips.isNotEmpty
              ? _buildClipEditorPanel()
              : const SizedBox.shrink(),
        ),
        if (_isProcessing)
          const LinearProgressIndicator()
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildEditorLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1080;

        final clipPane = SizedBox(
          width: 260,
          child: _buildClipListPane(scrollable: true),
        );

        final videoPane = Expanded(child: _buildVideoViewport());
        final timelinePane = _buildTimelineAndEditor();

        if (isNarrow) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: clipPane,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildVideoViewport(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: timelinePane,
                ),
              ),
              if (_isProcessing)
                const LinearProgressIndicator()
              else
                const SizedBox.shrink(),
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [clipPane, const SizedBox(width: 12), videoPane],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: timelinePane,
              ),
            ),
            if (_isProcessing)
              const LinearProgressIndicator()
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildVideoViewport() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = (MediaQuery.of(context).size.height * 0.5).clamp(
          300.0,
          460.0,
        );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(controller: controller),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enableEditing ? 'Clip Editor' : 'Video Player'),
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
      body: widget.enableEditing
          ? _buildEditorLayout(context)
          : _buildStandardLayout(),
    );
  }
}
