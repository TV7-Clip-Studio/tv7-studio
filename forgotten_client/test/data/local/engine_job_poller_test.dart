import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_job_poller.dart';

class _FakeEngineTransport implements EngineJsonTransport {
  _FakeEngineTransport(this.jobs, {this.logs = const [], this.jobFailures = 0});

  final List<Map<String, dynamic>> jobs;
  final List<String> logs;
  int jobFailures;
  var jobRequests = 0;

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    if (uri.path.endsWith('/logs')) {
      return EngineHttpResponse(
        statusCode: 200,
        elapsed: Duration.zero,
        json: {'job_id': 'job_1', 'logs': logs},
        rawBody: logs.toString(),
      );
    }
    if (uri.path == '/v1/jobs/job_1') {
      if (jobFailures > 0) {
        jobFailures--;
        throw const SocketException('temporary Engine connection failure');
      }
      final index = jobRequests >= jobs.length ? jobs.length - 1 : jobRequests;
      jobRequests++;
      final json = jobs[index];
      return EngineHttpResponse(
        statusCode: 200,
        elapsed: Duration.zero,
        json: json,
        rawBody: json.toString(),
      );
    }
    throw StateError('unexpected path ${uri.path}');
  }
}

EngineJob _job(String status, {List<String> logs = const []}) {
  return EngineJob(
    id: 'job_1',
    kind: 'test',
    status: status,
    progress: status == 'succeeded' ? 1 : 0,
    logs: logs,
    result: null,
    error: null,
    cancelRequested: false,
  );
}

Map<String, dynamic> _jobJson(String status, {List<String> logs = const []}) {
  return {
    'id': 'job_1',
    'kind': 'test',
    'status': status,
    'progress': status == 'succeeded' ? 1.0 : 0.5,
    'logs': logs,
    'result': null,
    'error': null,
    'cancel_requested': false,
  };
}

void main() {
  test('polls with bounded backoff and deduplicates logs', () async {
    final transport = _FakeEngineTransport(
      [
        _jobJson('running', logs: ['queued', 'running']),
        _jobJson('succeeded', logs: ['running', 'done']),
      ],
      logs: ['queued', 'running', 'done'],
    );
    final delays = <Duration>[];
    final poller = EngineJobPoller(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: transport,
      ),
      policy: const EngineJobPollingPolicy(
        initialInterval: Duration(milliseconds: 250),
        maxInterval: Duration(milliseconds: 500),
      ),
      delay: (delay) async => delays.add(delay),
    );
    final logs = <String>[];

    final completed = await poller.waitFor(
      _job('queued', logs: ['queued']),
      onLog: logs.add,
    );

    expect(completed.status, 'succeeded');
    expect(delays, [
      const Duration(milliseconds: 250),
      const Duration(milliseconds: 500),
    ]);
    expect(logs, ['queued', 'running', 'done']);
  });

  test('retries transient getJob failures with the same backoff', () async {
    final transport = _FakeEngineTransport([
      _jobJson('running', logs: ['running']),
      _jobJson('succeeded', logs: ['done']),
    ], jobFailures: 1);
    final delays = <Duration>[];
    final poller = EngineJobPoller(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: transport,
      ),
      policy: const EngineJobPollingPolicy(
        initialInterval: Duration(milliseconds: 250),
        maxInterval: Duration(seconds: 1),
      ),
      delay: (delay) async => delays.add(delay),
    );

    final completed = await poller.waitFor(_job('queued'));

    expect(completed.status, 'succeeded');
    expect(delays, [
      const Duration(milliseconds: 250),
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
    ]);
  });

  test('stops retrying transient failures when explicit timeout expires', () {
    final transport = _FakeEngineTransport([_jobJson('running')]);
    final poller = EngineJobPoller(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: transport,
      ),
      policy: const EngineJobPollingPolicy(
        initialInterval: Duration(milliseconds: 1),
        maxInterval: Duration(milliseconds: 1),
        timeout: Duration(milliseconds: 1),
      ),
      delay: (delay) async {
        await Future<void>.delayed(delay);
      },
    );
    transport.jobFailures = 100;

    expect(
      () => poller.waitFor(_job('queued')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('does not retry non-transient polling failures', () async {
    final transport = _FakeEngineTransport([]);
    final poller = EngineJobPoller(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: transport,
      ),
      policy: const EngineJobPollingPolicy(
        initialInterval: Duration.zero,
        maxInterval: Duration.zero,
      ),
    );

    expect(() => poller.waitFor(_job('queued')), throwsA(isA<RangeError>()));
  });

  test(
    'honors explicit timeout without imposing a production default',
    () async {
      final transport = _FakeEngineTransport([
        _jobJson('running'),
        _jobJson('running'),
      ]);
      final poller = EngineJobPoller(
        engineClient: EngineClient(
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          transport: transport,
        ),
        policy: const EngineJobPollingPolicy(
          initialInterval: Duration(milliseconds: 1),
          maxInterval: Duration(milliseconds: 1),
          timeout: Duration(milliseconds: 1),
        ),
        delay: (delay) async {
          await Future<void>.delayed(delay);
        },
      );

      expect(
        () => poller.waitFor(_job('running')),
        throwsA(isA<TimeoutException>()),
      );
    },
  );

  test('invokes onProgress with correct progress values', () async {
    final transport = _FakeEngineTransport([
      _jobJson('running', logs: ['running']),
      _jobJson('succeeded', logs: ['done']),
    ]);
    final poller = EngineJobPoller(
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: transport,
      ),
      policy: const EngineJobPollingPolicy(
        initialInterval: Duration.zero,
        maxInterval: Duration.zero,
      ),
    );
    final progressValues = <double>[];

    final completed = await poller.waitFor(
      _job('queued'),
      onProgress: progressValues.add,
    );

    expect(completed.status, 'succeeded');
    expect(progressValues, containsAllInOrder([0.0, 0.5, 1.0]));
  });
}
