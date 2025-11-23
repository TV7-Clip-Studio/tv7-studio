# Architecture Plan (Flutter client)

## Goals and targets
- Platforms: desktop first (macOS/Windows/Linux), mobile parity (iOS/Android) after desktop pipeline is solid.
- Single Flutter codebase with flavors: dev/stage/prod via dart-defines/.env per platform.
- Local-heavy media pipeline; backend handles auth/metadata/feature flags/publishing hooks.

## App layers
- Presentation: Flutter UI with state management (e.g., Riverpod/Bloc) and responsive layouts for desktop/mobile.
- Domain/services: Auth/session, media pipeline orchestration, sync engine, settings, telemetry/logging.
- Data: Generated OpenAPI client + thin SDK wrapper (auth refresh, retries, logging); local cache (SQLite or Hive) for metadata and offline queue.
- Platform channels/FFI: invoke local binaries (ffmpeg, yt-dlp, whisper.cpp) and handle process streams.

## Config & flavors
- dart-defines or .env per flavor: `API_BASE_URL`, `OPENAI_MODE` (local/cloud), `FEATURE_FLAGS` (publishing, local_highlights, etc.), `APP_LOG_LEVEL`.
- Secrets: never ship backend keys; user supplies OpenAI key or receives short-lived tokens from backend.
- Settings screen to override: OpenAI key, paths to binaries, toggle local vs cloud highlights, opt into pre-release updates.

## Auth/session
- Backend JWT login/refresh; store tokens securely: Keychain/Keystore on mobile, platform key stores on desktop (fallback encrypted file with OS secrets).
- Auto-refresh before expiry; purge on logout/expiry; attach auth headers in API client wrapper.
- Handle 401/403 globally with session invalidation and re-login prompt.

## API client
- Source of truth: backend OpenAPI spec.
- Generation: `openapi-generator-cli -g dart-dio` (pinned version); keep generated code committed and linted.
- Wrapper: request logging (debug), retry with backoff, token refresh hook, error normalization for UI.

## Local tools strategy
- Required: `ffmpeg`, `yt-dlp`. Optional: `whisper.cpp` for local transcripts/highlights.
- Distribution per OS:
  - macOS: bundle binaries in app resources when licensing allows; otherwise prompt install (brew) or user-provided path.
  - Windows: ship bundled binaries; allow custom paths.
  - Linux: prefer bundled AppImage/embedded; fallback to system packages; allow custom paths.
  - iOS/Android: no external binaries; rely on native-compiled libs or defer heavy pipeline to desktop until mobile path is ready.
- Validation: check versions/paths at startup and in settings; surface missing deps with guided install.

## Media pipeline (local)
- Workspace: app data dir with subdirs: `/ingest`, `/normalize`, `/render`, `/logs`, `/cache`. Clean per-job on completion; rotate logs.
- Ingest: YouTube via `yt-dlp` or local file import; validate size/format; compute hashes and basic metadata (duration, dimensions).
- Normalize: ffmpeg scale to 9:16 target height, clamp bitrate/codec, write to `/normalize`.
- Transcript: optional `whisper.cpp` (local) or backend/OpenAI; store transcript alongside media.
- Highlights: default cloud (backend/OpenAI); optional local small model if available.
- Render: ffmpeg slice/reframe clips; optional burn-in subtitles; output to `/render`.
- Progress: stream process logs; track stages for UI; support cancel/retry.

## Sync/offline model
- Local cache (SQLite/Hive): videos, clips, statuses, transcripts, pending uploads.
- Sync engine: pull metadata from backend; push local changes and statuses; reconcile conflicts by last-updated + server authority on shared fields.
- Offline queue: queue pushes until online; exponential backoff; resumable uploads if assets are sent.

## Error handling & observability
- Structured logs per job stored under `/logs`; include process stderr/stdout tails for user-visible errors.
- User-facing errors mapped to friendly codes; allow export of logs for support.
- Optional analytics/telemetry gated by opt-in and flavor (off by default in prod unless configured).

## UX/key screens
- Auth/login, dashboard showing backend metadata, workspace/queue view, job detail with stage progress, settings (OpenAI key, binary paths, feature toggles), logs viewer.
- Desktop-first controls with keyboard shortcuts; mobile layouts adapt with bottom navigation and simplified controls.

## Build & distribution
- Desktop: dmg (macOS), msix (Windows), AppImage (Linux). Start unsigned for internal tests; add signing/notarization later.
- Mobile: TestFlight/Play Internal; consider deferring on-device rendering if perf/storage is insufficient initially.
- CI: `flutter format`/`analyze`/`test`; desktop build checks; openapi generation lint; pinned toolchain versions.

## Immediate implementation steps
- Bootstrap Flutter project `forgotten_client` with flavors and env wiring.
- Pull/export latest backend OpenAPI spec; commit generator config and generated client.
- Implement auth shell (login screen, token storage, refresh hook) and a basic dashboard calling a simple metadata endpoint.
