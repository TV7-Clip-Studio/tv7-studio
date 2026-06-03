import 'dart:async';
import 'dart:math' as math;

import 'package:forgotten_client/data/local/engine_client.dart';

class EngineJobPollingPolicy {
  const EngineJobPollingPolicy({
    this.initialInterval = const Duration(milliseconds: 250),
    this.maxInterval = const Duration(seconds: 5),
    this.multiplier = 2,
    this.timeout,
  });

  final Duration initialInterval;
  final Duration maxInterval;
  final double multiplier;
  final Duration? timeout;
}

class EngineJobPoller {
  EngineJobPoller({
    required this.engineClient,
    this.policy = const EngineJobPollingPolicy(),
    Future<void> Function(Duration delay)? delay,
  }) : _delay = delay ?? Future<void>.delayed;

  final EngineClient engineClient;
  final EngineJobPollingPolicy policy;
  final Future<void> Function(Duration delay) _delay;

  Future<EngineJob> waitFor(
    EngineJob started, {
    void Function(String)? onLog,
    bool fetchLogs = true,
  }) async {
    var job = started;
    var interval = policy.initialInterval;
    final deadline = policy.timeout == null
        ? null
        : DateTime.now().add(policy.timeout!);
    final seenLogs = <String>{};

    void emitLogs(Iterable<String> logs) {
      for (final line in logs) {
        if (seenLogs.add(line)) onLog?.call(line);
      }
    }

    emitLogs(job.logs);
    while (!job.isTerminal) {
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'Engine job timed out: ${job.id}',
          policy.timeout,
        );
      }

      if (interval > Duration.zero) {
        await _delay(interval);
      }

      job = await engineClient.getJob(job.id);
      emitLogs(job.logs);

      if (fetchLogs) {
        try {
          final logs = await engineClient.getJobLogs(job.id);
          emitLogs(logs.logs);
        } catch (_) {}
      }

      interval = _nextInterval(interval);
    }

    emitLogs(job.logs);
    return job;
  }

  Duration _nextInterval(Duration current) {
    final multiplied = (current.inMicroseconds * policy.multiplier).round();
    final capped = math.min(multiplied, policy.maxInterval.inMicroseconds);
    return Duration(microseconds: math.max(capped, 0));
  }
}
