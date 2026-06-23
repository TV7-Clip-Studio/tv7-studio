import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/features/dashboard/quick_clip_preflight.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late File videoFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quick_clip_preflight');
    videoFile = File(p.join(tempDir.path, 'source.mp4'))
      ..writeAsStringSync('video');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('passes when a transcript already exists', () async {
    final result = await quickClipPreflight(
      videoPath: videoFile.path,
      getTranscript: (_) async => TranscriptResult(text: 'hello'),
    );

    expect(result.status, QuickClipPreflightStatus.ready);
    expect(result.isBlocked, isFalse);
  });

  test(
    'allows remote transcript download when remote metadata exists',
    () async {
      File(
        '${videoFile.path}.meta.json',
      ).writeAsStringSync('{"source_url":"https://example.com/watch?v=123"}');

      final result = await quickClipPreflight(
        videoPath: videoFile.path,
        getTranscript: (_) async => null,
      );

      expect(
        result.status,
        QuickClipPreflightStatus.canDownloadRemoteTranscript,
      );
      expect(result.isBlocked, isFalse);
    },
  );

  test('blocks local imports without transcript or remote source', () async {
    File(
      '${videoFile.path}.meta.json',
    ).writeAsStringSync('{"source_url":"file://${videoFile.path}"}');

    final result = await quickClipPreflight(
      videoPath: videoFile.path,
      sourceUrl: 'file://${videoFile.path}',
      getTranscript: (_) async => null,
    );

    expect(result.status, QuickClipPreflightStatus.blocked);
    expect(result.message, contains('local import has no transcript'));
    expect(result.remediation, contains('setup readiness'));
  });

  test(
    'blocks with setup action when transcription assets are installable',
    () async {
      final result = await quickClipPreflight(
        videoPath: videoFile.path,
        sourceUrl: 'file://${videoFile.path}',
        getTranscript: (_) async => null,
        setupStatus: _setupStatus(
          transcriptionReady: false,
          transcriptionInstallable: true,
        ),
      );

      expect(result.status, QuickClipPreflightStatus.blocked);
      expect(
        result.message,
        contains('Local transcription setup is not ready'),
      );
      expect(result.remediation, contains('transcription_model'));
      expect(result.remediation, contains('explicit confirmation'));
      expect(result.actionLabel, 'Set up local transcription');
    },
  );

  test(
    'blocks with missing details when transcription is not installable',
    () async {
      final result = await quickClipPreflight(
        videoPath: videoFile.path,
        sourceUrl: 'file://${videoFile.path}',
        getTranscript: (_) async => null,
        setupStatus: _setupStatus(
          transcriptionReady: false,
          transcriptionInstallable: false,
        ),
      );

      expect(result.status, QuickClipPreflightStatus.blocked);
      expect(result.remediation, contains('Import or configure'));
      expect(result.actionLabel, isNull);
    },
  );

  test(
    'allows local transcript generation when transcription is ready',
    () async {
      final result = await quickClipPreflight(
        videoPath: videoFile.path,
        getTranscript: (_) async => null,
        setupStatus: _setupStatus(
          transcriptionReady: true,
          transcriptionInstallable: false,
        ),
      );

      expect(
        result.status,
        QuickClipPreflightStatus.canGenerateLocalTranscript,
      );
      expect(result.isBlocked, isFalse);
      expect(result.message, contains('Engine local transcription is ready'));
      expect(result.remediation, contains('transcript job succeeds'));
      expect(result.actionLabel, isNull);
    },
  );

  test('returns first remote source from metadata aliases', () async {
    File(
      '${videoFile.path}.meta.json',
    ).writeAsStringSync('{"sourceUrl":"https://example.com/source"}');

    final result = await remoteSourceUrlFor(videoPath: videoFile.path);

    expect(result, 'https://example.com/source');
  });
}

SetupStatus _setupStatus({
  required bool transcriptionReady,
  required bool transcriptionInstallable,
}) {
  return SetupStatus.fromJson({
    'schema_version': 1,
    'setup_complete': transcriptionReady,
    'active_ai_provider': 'tv7_cloud',
    'assets': [
      {
        'id': 'whisper-runtime.user-path',
        'kind': 'transcription_runtime',
        'name': 'User-installed Whisper runtime',
        'status': transcriptionReady ? 'available' : 'missing',
        'source': 'user_path',
        'path': transcriptionReady ? '/opt/homebrew/bin/whisper-cli' : null,
        'version': transcriptionReady ? 'whisper.cpp' : null,
        'error': transcriptionReady ? null : 'not configured',
      },
      {
        'id': 'whisper-model.tv7-managed.macos-arm64',
        'kind': 'transcription_model',
        'name': 'TV7-managed Whisper model',
        'status': transcriptionReady
            ? 'available'
            : transcriptionInstallable
            ? 'installable'
            : 'missing',
        'source': transcriptionReady ? 'user_path' : 'tv7_managed',
        'path': '/tmp/models/whisper',
        'version': transcriptionReady ? 'small' : null,
        'error': transcriptionInstallable
            ? 'download requires explicit user confirmation'
            : null,
      },
    ],
    'providers': <Map<String, dynamic>>[],
    'capabilities': [
      {
        'name': 'transcription',
        'status': transcriptionReady ? 'ready' : 'not_ready',
        'provider': transcriptionReady ? 'user_path' : null,
        'missing': transcriptionReady
            ? <String>[]
            : ['transcription_runtime', 'transcription_model'],
        'installable': transcriptionInstallable,
        'user_action_required': !transcriptionReady,
      },
      {
        'name': 'ai',
        'status': 'ready',
        'provider': 'tv7_cloud',
        'missing': <String>[],
        'installable': true,
        'user_action_required': false,
      },
    ],
  });
}
