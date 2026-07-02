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
    try {
      await _snapshot;
    } catch (_) {}
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

  DiagnosticCheck? _findCheck(List<DiagnosticCheck> checks, String name) {
    for (final check in checks) {
      if (check.name == name) return check;
    }
    return null;
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
              if (snapshot.hasError) {
                return _DiagnosticsLoadError(
                  error: snapshot.error!,
                  onRefresh: _refresh,
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              final endpointResults = _endpointResults.isEmpty
                  ? data.endpointResults
                  : _endpointResults;

              final width = MediaQuery.of(context).size.width;
              final isWide = width > 1000;

              final startupCheck = _findCheck(data.checks, 'Engine startup');
              final healthCheck = _findCheck(data.checks, 'Engine /health');
              final diagCheck = _findCheck(
                data.checks,
                'Engine /v1/diagnostics',
              );
              final capabilities = data.checks
                  .where((c) => c.name.startsWith('Engine capability: '))
                  .toList();
              final setupReadiness = data.checks
                  .where((c) => c.name.startsWith('Engine setup: '))
                  .toList();
              final setupAssets = data.checks
                  .where((c) => c.name.startsWith('Engine setup asset: '))
                  .toList();
              final aiProviders = data.checks
                  .where((c) => c.name.startsWith('Engine AI provider: '))
                  .toList();

              final backendUsersCheck = _findCheck(
                data.checks,
                'Backend /api/v1/users/',
              );
              final backendLicenseCheck = _findCheck(
                data.checks,
                'User License',
              );

              final workspaceCheck = _findCheck(data.checks, 'Local workspace');
              final envTools = data.checks
                  .where((c) => c.name.startsWith('Engine tool: '))
                  .toList();

              final enginePanel = _EnginePanel(
                startupCheck: startupCheck,
                healthCheck: healthCheck,
                diagCheck: diagCheck,
                capabilities: capabilities,
                setupReadiness: setupReadiness,
                setupAssets: setupAssets,
                aiProviders: aiProviders,
                isRunningEndpoints: _isRunningEndpointChecks,
                endpointResults: endpointResults,
                onRunEndpoints: _runEndpointChecks,
              );

              final backendPanel = _BackendPanel(
                connectionCheck: backendUsersCheck,
                licenseCheck: backendLicenseCheck,
              );

              final envPanel = _EnvironmentPanel(
                workspaceCheck: workspaceCheck,
                tools: envTools,
              );

              Widget dashboardLayout;
              if (isWide) {
                dashboardLayout = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: enginePanel),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          backendPanel,
                          const SizedBox(height: 20),
                          envPanel,
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                dashboardLayout = Column(
                  children: [
                    enginePanel,
                    const SizedBox(height: 20),
                    backendPanel,
                    const SizedBox(height: 20),
                    envPanel,
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _Header(collectedAt: data.collectedAt, onRefresh: _refresh),
                  const SizedBox(height: 20),
                  dashboardLayout,
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Settings'),
                  const SizedBox(height: 12),
                  _SettingsPanel(settings: data.settings),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Recent errors'),
                  const SizedBox(height: 12),
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

class _DiagnosticsLoadError extends StatelessWidget {
  const _DiagnosticsLoadError({required this.error, required this.onRefresh});

  final Object error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Header(collectedAt: DateTime.now(), onRefresh: onRefresh),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnostics unavailable',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        error.toString(),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
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

class _EnginePanel extends StatelessWidget {
  const _EnginePanel({
    required this.startupCheck,
    required this.healthCheck,
    required this.diagCheck,
    required this.capabilities,
    required this.setupReadiness,
    required this.setupAssets,
    required this.aiProviders,
    required this.isRunningEndpoints,
    required this.endpointResults,
    required this.onRunEndpoints,
  });

  final DiagnosticCheck? startupCheck;
  final DiagnosticCheck? healthCheck;
  final DiagnosticCheck? diagCheck;
  final List<DiagnosticCheck> capabilities;
  final List<DiagnosticCheck> setupReadiness;
  final List<DiagnosticCheck> setupAssets;
  final List<DiagnosticCheck> aiProviders;
  final bool isRunningEndpoints;
  final List<EngineEndpointResult> endpointResults;
  final VoidCallback onRunEndpoints;

  @override
  Widget build(BuildContext context) {
    var overallStatus = DiagnosticCheckStatus.ready;
    if (startupCheck?.status == DiagnosticCheckStatus.unavailable ||
        healthCheck?.status == DiagnosticCheckStatus.unavailable ||
        diagCheck?.status == DiagnosticCheckStatus.unavailable) {
      overallStatus = DiagnosticCheckStatus.unavailable;
    } else if (startupCheck?.status == DiagnosticCheckStatus.degraded ||
        healthCheck?.status == DiagnosticCheckStatus.degraded ||
        diagCheck?.status == DiagnosticCheckStatus.degraded) {
      overallStatus = DiagnosticCheckStatus.degraded;
    }

    final overallColor = _statusColor(context, overallStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_input_component_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local Media Engine',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: overallColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: overallColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    overallStatus.name.toUpperCase(),
                    style: TextStyle(
                      color: overallColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (startupCheck != null)
                  Expanded(
                    child: _buildSubCheck(
                      context,
                      'Startup',
                      startupCheck!.status,
                    ),
                  ),
                if (healthCheck != null)
                  Expanded(
                    child: _buildSubCheck(
                      context,
                      'Health API',
                      healthCheck!.status,
                    ),
                  ),
                if (diagCheck != null)
                  Expanded(
                    child: _buildSubCheck(
                      context,
                      'Diagnostics',
                      diagCheck!.status,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (capabilities.isNotEmpty) ...[
              const Text(
                'Media Capabilities',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: capabilities.map((cap) {
                  final cleanName = cap.name
                      .replaceFirst('Engine capability: ', '')
                      .toUpperCase();
                  final color = _statusColor(context, cap.status);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cleanName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            if (setupReadiness.isNotEmpty) ...[
              const Text(
                'Setup Readiness',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: setupReadiness.map((check) {
                  return _StatusChip(
                    label: check.name
                        .replaceFirst('Engine setup: ', '')
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    status: check.status,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              ...setupReadiness
                  .where((check) => check.status != DiagnosticCheckStatus.ready)
                  .map(
                    (check) => _SetupDetailRow(
                      title: check.name.replaceFirst('Engine setup: ', ''),
                      detail: check.detail,
                      status: check.status,
                    ),
                  ),
              ...aiProviders.map(
                (check) => _SetupDetailRow(
                  title: check.name.replaceFirst('Engine AI provider: ', ''),
                  detail: check.detail,
                  status: check.status,
                ),
              ),
              ...setupAssets
                  .where((check) => check.detail.contains('Action:'))
                  .map(
                    (check) => _SetupDetailRow(
                      title: check.name.replaceFirst(
                        'Engine setup asset: ',
                        '',
                      ),
                      detail: check.detail,
                      status: check.status,
                    ),
                  ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Endpoint Smoke Checks',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onRunEndpoints,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                  ),
                  icon: isRunningEndpoints
                      ? const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 14),
                  label: const Text('Run', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (endpointResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Endpoint verification has not been run.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  children: endpointResults
                      .map((res) => _ConsoleEndpointRow(result: res))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCheck(
    BuildContext context,
    String label,
    DiagnosticCheckStatus status,
  ) {
    final statusColor = _statusColor(context, status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_statusIcon(status), color: statusColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ConsoleEndpointRow extends StatefulWidget {
  const _ConsoleEndpointRow({required this.result});

  final EngineEndpointResult result;

  @override
  State<_ConsoleEndpointRow> createState() => _ConsoleEndpointRowState();
}

class _ConsoleEndpointRowState extends State<_ConsoleEndpointRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final method = widget.result.method;
    final path = widget.result.path;
    final status = widget.result.status;
    final detail = widget.result.detail;

    final methodColor = method == 'POST'
        ? Colors.greenAccent.shade400
        : Colors.lightBlue.shade400;

    final statusColor = _statusColor(context, status);
    final hasPreviews =
        widget.result.requestPreview != null ||
        widget.result.responsePreview != null;

    return Column(
      children: [
        InkWell(
          onTap: hasPreviews
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: methodColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    method,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: methodColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    path,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  detail,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasPreviews)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  )
                else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),
        if (_expanded && hasPreviews)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.result.requestPreview != null) ...[
                  const Text(
                    'REQUEST',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    widget.result.requestPreview!,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                  ),
                  if (widget.result.responsePreview != null)
                    const SizedBox(height: 10),
                ],
                if (widget.result.responsePreview != null) ...[
                  const Text(
                    'RESPONSE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    widget.result.responsePreview!,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        Divider(
          height: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _BackendPanel extends StatelessWidget {
  const _BackendPanel({
    required this.connectionCheck,
    required this.licenseCheck,
  });

  final DiagnosticCheck? connectionCheck;
  final DiagnosticCheck? licenseCheck;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_queue_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Backend Services',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (connectionCheck != null) ...[
              _buildRowItem(
                context,
                title: 'API Server',
                detail: connectionCheck!.detail,
                status: connectionCheck!.status,
              ),
              const SizedBox(height: 12),
            ],
            if (licenseCheck != null) ...[
              _buildRowItem(
                context,
                title: 'User License',
                detail: licenseCheck!.detail,
                status: licenseCheck!.status,
                licenseMetadata: licenseCheck!.metadata,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(
    BuildContext context, {
    required String title,
    required String detail,
    required DiagnosticCheckStatus status,
    Map<String, Object?>? licenseMetadata,
  }) {
    Widget valueWidget;
    if (licenseMetadata != null) {
      final licenseStatus =
          licenseMetadata['license_status']?.toString().toUpperCase() ??
          'REQUIRED';
      final cloudAiAvailable = licenseMetadata['cloud_ai_available'] == true;
      final credits =
          licenseMetadata['cloud_ai_credits_remaining'] as int? ?? 0;

      valueWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.greenAccent.shade400.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  licenseStatus,
                  style: TextStyle(
                    color: Colors.greenAccent.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cloud AI ${cloudAiAvailable ? 'READY' : 'UNAVAILABLE'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCredits(credits)} credits · Credits do not expire',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 11,
            ),
          ),
        ],
      );
    } else {
      valueWidget = Text(
        detail,
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              valueWidget,
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusIndicator(context, status),
      ],
    );
  }

  String _formatCredits(int value) {
    final digits = value.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }
}

class _EnvironmentPanel extends StatelessWidget {
  const _EnvironmentPanel({required this.workspaceCheck, required this.tools});

  final DiagnosticCheck? workspaceCheck;
  final List<DiagnosticCheck> tools;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.computer_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Host Environment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (workspaceCheck != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Local Workspace',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workspaceCheck!.detail,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusIndicator(context, workspaceCheck!.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            const Text(
              'CLI Tools Status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Column(
              children: tools.map((tool) {
                final cleanName = tool.name.replaceFirst('Engine tool: ', '');
                final statusColor = _statusColor(context, tool.status);

                final versionMatch =
                    RegExp(
                      r'Available:\s*[a-zA-Z0-9_]+\s*\(([^\)]+)\)',
                    ).firstMatch(tool.detail) ??
                    RegExp(r'\(([^\)]+)\)').firstMatch(tool.detail);
                final version = versionMatch?.group(1) ?? 'Available';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        radius: 14,
                        child: Icon(
                          _toolIcon(cleanName),
                          color: statusColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cleanName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        version,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildStatusIndicator(context, tool.status, size: 8),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _toolIcon(String name) {
    return switch (name.toLowerCase()) {
      'ffmpeg' => Icons.video_file_outlined,
      'ffprobe' => Icons.youtube_searched_for_rounded,
      'yt-dlp' => Icons.downloading_rounded,
      _ => Icons.build_circle_outlined,
    };
  }
}

Widget _buildStatusIndicator(
  BuildContext context,
  DiagnosticCheckStatus status, {
  double size = 10,
}) {
  final color = _statusColor(context, status);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 4,
          spreadRadius: 1,
        ),
      ],
    ),
  );
}

IconData _statusIcon(DiagnosticCheckStatus status) {
  return switch (status) {
    DiagnosticCheckStatus.ready => Icons.check_circle_outline_rounded,
    DiagnosticCheckStatus.degraded => Icons.warning_amber_rounded,
    DiagnosticCheckStatus.unavailable => Icons.error_outline_rounded,
    DiagnosticCheckStatus.unknown => Icons.help_outline_rounded,
  };
}

Color _statusColor(BuildContext context, DiagnosticCheckStatus status) {
  return switch (status) {
    DiagnosticCheckStatus.ready => Colors.greenAccent.shade400,
    DiagnosticCheckStatus.degraded => Colors.amberAccent.shade400,
    DiagnosticCheckStatus.unavailable => Theme.of(context).colorScheme.error,
    DiagnosticCheckStatus.unknown => Theme.of(context).colorScheme.outline,
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final DiagnosticCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIndicator(context, status, size: 6),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupDetailRow extends StatelessWidget {
  const _SetupDetailRow({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final DiagnosticCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(status), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
