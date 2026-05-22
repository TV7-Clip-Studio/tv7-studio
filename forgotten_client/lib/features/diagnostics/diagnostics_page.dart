import 'package:flutter/material.dart';
import 'package:forgotten_client/data/local/diagnostics_log.dart';
import 'package:forgotten_client/data/local/studio_diagnostics_service.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({
    required this.service,
    required this.diagnosticsLog,
    super.key,
  });

  final StudioDiagnosticsService service;
  final DiagnosticsLog diagnosticsLog;

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  late Future<StudioDiagnosticsSnapshot> _snapshot;
  List<EngineEndpointResult> _endpointResults = [];
  bool _isRunningEndpointChecks = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.service.collect();
    widget.diagnosticsLog.addListener(_refresh);
  }

  @override
  void didUpdateWidget(DiagnosticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagnosticsLog != widget.diagnosticsLog) {
      oldWidget.diagnosticsLog.removeListener(_refresh);
      widget.diagnosticsLog.addListener(_refresh);
    }
    if (oldWidget.service != widget.service) {
      _refresh();
    }
  }

  @override
  void dispose() {
    widget.diagnosticsLog.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _snapshot = widget.service.collect();
    });
  }

  Future<void> _refreshAsync() async {
    _refresh();
    await _snapshot;
  }

  Future<void> _runEndpointChecks() async {
    setState(() {
      _isRunningEndpointChecks = true;
    });
    try {
      final results = await widget.service.runEngineEndpointSmokeChecks();
      if (!mounted) return;
      setState(() {
        _endpointResults = results;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningEndpointChecks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAsync,
          child: FutureBuilder<StudioDiagnosticsSnapshot>(
            future: _snapshot,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              final endpointResults = _endpointResults.isEmpty
                  ? data.endpointResults
                  : _endpointResults;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _Header(collectedAt: data.collectedAt, onRefresh: _refresh),
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'Runtime checks'),
                  const SizedBox(height: 8),
                  ...data.checks.map(_CheckTile.new),
                  const SizedBox(height: 24),
                  _EndpointChecksPanel(
                    isRunning: _isRunningEndpointChecks,
                    results: endpointResults,
                    onRun: _runEndpointChecks,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Settings'),
                  const SizedBox(height: 8),
                  _SettingsPanel(settings: data.settings),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Recent errors'),
                  const SizedBox(height: 8),
                  _RecentErrors(entries: data.recentErrors),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EndpointChecksPanel extends StatelessWidget {
  const _EndpointChecksPanel({
    required this.isRunning,
    required this.results,
    required this.onRun,
  });

  final bool isRunning;
  final List<EngineEndpointResult> results;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle(title: 'Engine endpoints')),
            FilledButton.icon(
              onPressed: isRunning ? null : onRun,
              icon: isRunning
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: const Text('Run endpoint checks'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Manual checks are available for Engine endpoints. '
                'Media checks write only to the diagnostics workspace.',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          )
        else
          ...results.map(_EndpointTile.new),
      ],
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile(this.result);

  final EngineEndpointResult result;

  @override
  Widget build(BuildContext context) {
    final color = _color(context, result.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(_icon(result.status), color: color),
        title: Text('${result.method} ${result.path}'),
        subtitle: Text(result.detail),
        trailing: Text(
          result.status.name.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (result.requestPreview != null)
            _PreviewBlock(label: 'Request', value: result.requestPreview!),
          if (result.responsePreview != null)
            _PreviewBlock(label: 'Response', value: result.responsePreview!),
        ],
      ),
    );
  }

  IconData _icon(DiagnosticCheckStatus status) {
    return switch (status) {
      DiagnosticCheckStatus.ready => Icons.check_circle_outline,
      DiagnosticCheckStatus.degraded => Icons.warning_amber_rounded,
      DiagnosticCheckStatus.unavailable => Icons.error_outline,
      DiagnosticCheckStatus.unknown => Icons.help_outline,
    };
  }

  Color _color(BuildContext context, DiagnosticCheckStatus status) {
    return switch (status) {
      DiagnosticCheckStatus.ready => Colors.greenAccent.shade400,
      DiagnosticCheckStatus.degraded => Colors.amberAccent.shade400,
      DiagnosticCheckStatus.unavailable => Theme.of(context).colorScheme.error,
      DiagnosticCheckStatus.unknown => Theme.of(context).colorScheme.outline,
    };
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  value,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.collectedAt, required this.onRefresh});

  final DateTime collectedAt;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.monitor_heart_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diagnostics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Updated ${_formatTime(collectedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh diagnostics',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile(this.check);

  final DiagnosticCheck check;

  @override
  Widget build(BuildContext context) {
    final color = _color(context, check.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_icon(check.status), color: color),
        title: Text(check.name),
        subtitle: Text(check.detail),
        trailing: Text(
          check.status.name.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  IconData _icon(DiagnosticCheckStatus status) {
    return switch (status) {
      DiagnosticCheckStatus.ready => Icons.check_circle_outline,
      DiagnosticCheckStatus.degraded => Icons.warning_amber_rounded,
      DiagnosticCheckStatus.unavailable => Icons.error_outline,
      DiagnosticCheckStatus.unknown => Icons.help_outline,
    };
  }

  Color _color(BuildContext context, DiagnosticCheckStatus status) {
    return switch (status) {
      DiagnosticCheckStatus.ready => Colors.greenAccent.shade400,
      DiagnosticCheckStatus.degraded => Colors.amberAccent.shade400,
      DiagnosticCheckStatus.unavailable => Theme.of(context).colorScheme.error,
      DiagnosticCheckStatus.unknown => Theme.of(context).colorScheme.outline,
    };
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.settings});

  final Map<String, String> settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: settings.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(entry.value, overflow: TextOverflow.visible),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecentErrors extends StatelessWidget {
  const _RecentErrors({required this.entries});

  final List<DiagnosticsLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No recent app errors recorded.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.report_gmailerrorred_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(entry.source),
            subtitle: Text(
              entry.message,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }
}
