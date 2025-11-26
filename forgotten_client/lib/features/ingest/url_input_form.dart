import 'package:flutter/material.dart';

class UrlInputForm extends StatefulWidget {
  const UrlInputForm({required this.onSubmit, super.key, this.enabled = true});

  final ValueChanged<String> onSubmit;
  final bool enabled;

  @override
  State<UrlInputForm> createState() => _UrlInputFormState();
}

class _UrlInputFormState extends State<UrlInputForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingest from YouTube',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  enabled: widget.enabled,
                  decoration: const InputDecoration(
                    hintText: 'https://www.youtube.com/watch?v=...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a URL';
                    }
                    if (!value.contains('youtube.com') &&
                        !value.contains('youtu.be')) {
                      return 'Please enter a valid YouTube URL';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: widget.enabled ? _submit : null,
                icon: const Icon(Icons.download),
                label: const Text('Fetch'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
