import 'package:flutter/foundation.dart';

class DiagnosticsLogEntry {
  const DiagnosticsLogEntry({
    required this.source,
    required this.message,
    required this.timestamp,
  });

  final String source;
  final String message;
  final DateTime timestamp;
}

class DiagnosticsLog extends ChangeNotifier {
  final List<DiagnosticsLogEntry> _entries = [];

  List<DiagnosticsLogEntry> get entries => List.unmodifiable(_entries);

  void record(String source, Object error) {
    _entries.insert(
      0,
      DiagnosticsLogEntry(
        source: source,
        message: error.toString(),
        timestamp: DateTime.now(),
      ),
    );
    if (_entries.length > 20) {
      _entries.removeRange(20, _entries.length);
    }
    notifyListeners();
  }
}
