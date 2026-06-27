import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forgotten_client/data/local/media_service.dart';
import 'package:forgotten_client/features/ingest/file_picker_area.dart';
import 'package:forgotten_client/features/ingest/url_input_form.dart';

class IngestPage extends StatefulWidget {
  const IngestPage({required this.mediaService, super.key});

  final MediaService mediaService;

  @override
  State<IngestPage> createState() => _IngestPageState();
}

class _IngestPageState extends State<IngestPage> {
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _activeJobId;
  bool _isCancelling = false;
  String? _statusMessage;
  File? _ingestedFile;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUrlSubmit(String url) async {
    setState(() {
      _isProcessing = true;
      _isCancelling = false;
      _progress = 0.0;
      _activeJobId = null;
      _statusMessage = 'Starting download...';
      _ingestedFile = null;
      _logs.clear();
    });

    try {
      final file = await widget.mediaService.prepareIngestFromUrl(
        url,
        onLog: (line) {
          if (mounted) {
            setState(() {
              _logs.add(line);
            });
            debugPrint(line);
            _scrollToBottom();
          }
        },
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
        onJobStarted: (jobId) {
          if (mounted) {
            setState(() {
              _activeJobId = jobId;
              _progress = 0.0;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _ingestedFile = file;
          _statusMessage = 'Download complete: ${file.path}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('cancelled')) {
            _statusMessage = 'Ingestion cancelled by user';
          } else {
            _statusMessage = 'Error: $e';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _activeJobId = null;
        });
      }
    }
  }

  Future<void> _cancelIngestion() async {
    final jobId = _activeJobId;
    if (jobId == null || _isCancelling) return;

    setState(() {
      _isCancelling = true;
      _statusMessage = 'Sending cancellation request...';
    });

    try {
      await widget.mediaService.engineClient.cancelJob(jobId);
      if (mounted) {
        setState(() {
          _statusMessage = 'Cancellation requested. Stopping...';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to cancel job: $e';
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _handleFileSelected(String path) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Importing file...';
      _ingestedFile = null;
      _logs.clear();
    });

    try {
      final file = await widget.mediaService.prepareIngestFromFile(path);
      if (mounted) {
        setState(() {
          _ingestedFile = file;
          _statusMessage = 'Import complete: ${file.path}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingest Video')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UrlInputForm(onSubmit: _handleUrlSubmit, enabled: !_isProcessing),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            FilePickerArea(
              onFileSelected: _handleFileSelected,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 32),
            if (_isProcessing)
              Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                              value: _progress > 0.0 ? _progress : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage ?? 'Processing...',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                        ),
                      ),
                      if (_activeJobId != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isCancelling
                                  ? null
                                  : _cancelIngestion,
                              icon: _isCancelling
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                      ),
                                    )
                                  : const Icon(Icons.cancel_outlined, size: 18),
                              label: Text(
                                _isCancelling
                                    ? 'Cancelling...'
                                    : 'Cancel Ingestion',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ingestedFile != null
                      ? Colors.green.withValues(alpha: 0.1)
                      : (_statusMessage!.contains('cancelled')
                            ? Theme.of(context).colorScheme.secondaryContainer
                                  .withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _ingestedFile != null
                        ? Colors.green
                        : (_statusMessage!.contains('cancelled')
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.red),
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _ingestedFile != null
                        ? Colors.green[800]
                        : (_statusMessage!.contains('cancelled')
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer
                              : Colors.red[800]),
                  ),
                ),
              ),
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Console Output:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
