import 'package:flutter/material.dart';

class ClipCreationDialog extends StatefulWidget {
  const ClipCreationDialog({required this.totalDuration, super.key});

  final Duration totalDuration;

  @override
  State<ClipCreationDialog> createState() => _ClipCreationDialogState();
}

class _ClipCreationDialogState extends State<ClipCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _startController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _startController = TextEditingController(text: '00:00');
    _durationController = TextEditingController(text: '30');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Duration? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      final seconds = int.tryParse(parts[1]);
      if (minutes != null && seconds != null) {
        return Duration(minutes: minutes, seconds: seconds);
      }
    } else if (parts.length == 1) {
      final seconds = int.tryParse(parts[0]);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }
    return null;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Clip'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Clip Title',
                hintText: 'Enter a descriptive title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time (MM:SS)',
                      hintText: '00:00',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final duration = _parseTime(value);
                      if (duration == null) {
                        return 'Invalid format';
                      }
                      if (duration > widget.totalDuration) {
                        return 'Exceeds video length';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (sec)',
                      hintText: '30',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final seconds = int.tryParse(value);
                      if (seconds == null || seconds <= 0) {
                        return 'Invalid duration';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total Video Duration: ${_formatDuration(widget.totalDuration)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final start = _parseTime(_startController.text)!;
              final duration = Duration(
                seconds: int.parse(_durationController.text),
              );

              // Validate total end time
              if (start + duration > widget.totalDuration) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clip extends beyond video duration'),
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'title': _titleController.text,
                'start': start,
                'duration': duration,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
