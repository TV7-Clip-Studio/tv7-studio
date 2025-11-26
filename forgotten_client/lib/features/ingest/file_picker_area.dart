import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FilePickerArea extends StatelessWidget {
  const FilePickerArea({
    required this.onFileSelected,
    super.key,
    this.enabled = true,
  });

  final ValueChanged<String> onFileSelected;
  final bool enabled;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      onFileSelected(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingest from File',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? _pickFile : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  size: 48,
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Click to select a video file',
                  style: TextStyle(
                    color: enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
