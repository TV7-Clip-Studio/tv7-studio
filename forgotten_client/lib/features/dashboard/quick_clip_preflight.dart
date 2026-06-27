import 'dart:convert';
import 'dart:io';

import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';

enum QuickClipPreflightStatus {
  ready,
  canDownloadRemoteTranscript,
  canGenerateLocalTranscript,
  blocked,
}

class QuickClipPreflight {
  const QuickClipPreflight({
    required this.status,
    required this.message,
    this.remediation,
    this.actionLabel,
  });

  final QuickClipPreflightStatus status;
  final String message;
  final String? remediation;
  final String? actionLabel;

  bool get isBlocked => status == QuickClipPreflightStatus.blocked;
}

Future<QuickClipPreflight> quickClipPreflight({
  required String videoPath,
  required Future<TranscriptResult?> Function(String videoPath) getTranscript,
  String? sourceUrl,
  SetupStatus? setupStatus,
}) async {
  final transcript = await getTranscript(videoPath);
  if (transcript != null) {
    return const QuickClipPreflight(
      status: QuickClipPreflightStatus.ready,
      message: 'Transcript ready.',
    );
  }

  final remoteSource = await remoteSourceUrlFor(
    videoPath: videoPath,
    sourceUrl: sourceUrl,
  );
  if (remoteSource != null) {
    return const QuickClipPreflight(
      status: QuickClipPreflightStatus.canDownloadRemoteTranscript,
      message: 'Transcript will be downloaded before clip generation.',
    );
  }

  final transcription = setupStatus?.capability('transcription');
  if (transcription != null) {
    if (transcription.isReady) {
      return const QuickClipPreflight(
        status: QuickClipPreflightStatus.canGenerateLocalTranscript,
        message:
            'Quick Clip needs a transcript. Engine local transcription is ready '
            'and will generate one before clip suggestions.',
        remediation:
            'Studio will request Engine transcript generation and continue after '
            'the transcript job succeeds.',
      );
    }

    final missingAssets = setupStatus?.missingAssetsFor(transcription) ?? [];
    final installable =
        transcription.installable ||
        missingAssets.any((asset) => asset.isInstallable);
    return QuickClipPreflight(
      status: QuickClipPreflightStatus.blocked,
      message:
          'Quick Clip needs a transcript. Local transcription setup is not ready.',
      remediation: _transcriptionRemediation(
        transcription,
        missingAssets,
        installable: installable,
      ),
      actionLabel: installable ? 'Set up local transcription' : null,
    );
  }

  return const QuickClipPreflight(
    status: QuickClipPreflightStatus.blocked,
    message:
        'Quick Clip needs a transcript. This local import has no transcript '
        'and no original remote URL to download subtitles from.',
    remediation:
        'Add a .vtt transcript beside the video, ingest from a URL with '
        'captions, or set up local transcription after Engine reports setup '
        'readiness.',
  );
}

String _transcriptionRemediation(
  SetupCapabilityStatus transcription,
  List<SetupAssetStatus> missingAssets, {
  required bool installable,
}) {
  final parts = <String>[];
  if (transcription.missing.isNotEmpty) {
    parts.add('Missing: ${transcription.missing.join(', ')}.');
  }
  if (missingAssets.isNotEmpty) {
    final details = missingAssets
        .map((asset) {
          final source = asset.source.replaceAll('_', ' ');
          return '${asset.name} (${asset.status}, $source)';
        })
        .join('; ');
    parts.add('Assets: $details.');
  }
  if (installable) {
    parts.add(
      'Set up local transcription with explicit confirmation before Studio starts any import or download action.',
    );
  } else {
    parts.add('Import or configure a Whisper runtime and model.');
  }
  parts.add(
    'Engine local transcript generation is supported after transcription setup is complete.',
  );
  return parts.join(' ');
}

Future<String?> remoteSourceUrlFor({
  required String videoPath,
  String? sourceUrl,
}) async {
  final candidates = <String?>[sourceUrl];
  final metaFile = File('$videoPath.meta.json');
  if (await metaFile.exists()) {
    final meta =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    candidates.addAll([
      meta['webpage_url']?.toString(),
      meta['source_url']?.toString(),
      meta['sourceUrl']?.toString(),
      meta['url']?.toString(),
    ]);
  }

  for (final candidate in candidates) {
    final value = candidate?.trim();
    if (value == null || value.isEmpty) continue;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme == 'file' || uri.scheme == 'local') {
      continue;
    }
    return value;
  }
  return null;
}
