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
      _statusMessage = 'Downloading from YouTube...';
      _ingestedFile = null;
      _logs.clear();
    });

    try {
      await _checkDependencies();
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

  Future<void> _handleFileSelected(String path) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Importing file...';
      _ingestedFile = null;
      _logs.clear();
    });

    try {
      await _checkDependencies();
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

  Future<void> _checkDependencies() async {
    final deps = ['yt-dlp', 'ffmpeg'];
    final missing = <String>[];
    for (final dep in deps) {
      final exists = await Process.run('which', [dep]);
      if (exists.exitCode != 0) {
        missing.add(dep);
      }
    }
    if (missing.isNotEmpty) {
      throw Exception(
        'Missing required tools: ${missing.join(', ')}. '
        'Install via your package manager (e.g., brew install ffmpeg yt-dlp).',
      );
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
              const Center(child: CircularProgressIndicator())
            else if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ingestedFile != null
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _ingestedFile != null ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _ingestedFile != null
                        ? Colors.green[800]
                        : Colors.red[800],
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
