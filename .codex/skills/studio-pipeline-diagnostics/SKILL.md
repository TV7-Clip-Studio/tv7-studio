---
name: studio-pipeline-diagnostics
description: Diagnose and fix Flutter Studio local media pipeline failures across ingest, local tools, process execution, and persistence. Use when clips fail to generate, local processing errors appear, ffmpeg/yt-dlp behavior is inconsistent, or desktop runs fail in media stages.
metadata:
  short-description: Triage local pipeline failures
---

# Studio Pipeline Diagnostics

Debug local-first media pipeline failures quickly and turn them into deterministic fixes with tests.

## Workflow

1. Reproduce the failure with the same run mode the user used.
   - Desktop default: `make run-desktop DEVICE=macos ENV_FILE=.env.dev`
2. Verify tool availability and versions.
   - Preferred: `./.codex/skills/studio-pipeline-diagnostics/scripts/check_local_tools.sh`
   - Manual fallback:
     - `which ffmpeg && ffmpeg -version`
     - `which yt-dlp && yt-dlp --version`
3. Inspect likely pipeline files before editing.
   - `forgotten_client/lib/data/local/tool_runner.dart`
   - `forgotten_client/lib/data/local/media_service.dart`
   - `forgotten_client/lib/data/local/local_video_repository.dart`
4. Classify the fault domain.
   - Tool discovery/path issue
   - Process execution/exit-code handling
   - File system/workspace persistence
   - Parsing/state transition bug
5. Implement minimal, observable fix.
   - Improve error messages with actionable context (command, exit code, key stderr snippet).
   - Add guardrails for missing binaries and invalid paths.
6. Add or update deterministic tests.
   - Prefer unit/service tests under `forgotten_client/test/data/local`.
   - Avoid real external binaries in tests.
7. Validate end-to-end repo checks.
   - Run: `make check`

## Bundled Resources

### scripts/check_local_tools.sh

Checks required local tools (`ffmpeg`, `yt-dlp`), prints discovery path and version, and exits non-zero when a required tool is missing.

Usage:
- `./.codex/skills/studio-pipeline-diagnostics/scripts/check_local_tools.sh`

## Done Criteria

- Root cause is identified and documented in the PR/summary.
- New or updated tests cover the fixed behavior.
- `make check` passes without relying on real network/binary execution in tests.
