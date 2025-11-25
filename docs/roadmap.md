# Desktop + Mobile Client Roadmap (Flutter, Hybrid Processing)

## Vision
- One Flutter codebase targeting macOS/Windows/Linux plus iOS/Android.
- Heavy processing runs locally (download/normalize/render/subtitles/transcripts) to minimize cloud spend.
- Cloud keeps auth, metadata/state, optional LLM highlights, and optional publishing.
- Client syncs metadata to `forgotten-app` API; uses OpenAI via user-supplied key (or backend-provided key if allowed).

## High-Level Split
### Client (Flutter app)
- UI, auth, session management.
- Local ingest: YouTube download (yt-dlp) or file import.
- Local media pipeline: ffmpeg normalize/render; optional whisper.cpp for transcripts.
- Optional local highlights if a small model is bundled; otherwise call backend/OpenAI.
- Upload final clip metadata (and optionally rendered assets) to backend.
- Optional: invoke backend publishing or do client-side posting with user tokens.

### Backend (`forgotten-app`)
- Auth/users, JWT issuance.
- Video/clip metadata store, status tracking.
- Optional highlight detection via OpenAI (cloud path).
- Optional publishing endpoints (centralized platform tokens, if used).
- API contract (OpenAPI) as the source of truth for client generation.

## Bootstrap Steps
1) Repo setup
   - Create a new repo dedicated to the Flutter client.
   - Add license/README; point to `forgotten-app` API docs and auth flow.
2) Project scaffold
   - `flutter create forgotten_client` (stable channel).
   - Establish flavors (dev/stage/prod) with `.env`/dart defines for:
     - `API_BASE_URL` (forgotten-app)
     - `OPENAI_MODE` (local/cloud)
     - `FEATURE_FLAGS` (publishing, local_highlights, etc.)
3) API client
   - Export OpenAPI from backend; generate Dart client (e.g., `openapi-generator-cli -g dart-dio`).
   - Wrap with a thin SDK for auth/token refresh, retries, logging.
4) Auth
   - Implement login to backend JWT endpoints.
   - Store/refresh tokens securely (per platform); add logout/expiry handling.
5) Local tooling
   - Bundle or prompt-install binaries:
     - `ffmpeg` (per platform)
     - `yt-dlp` for YouTube ingest
     - `whisper.cpp` (optional) for local transcripts
   - Provide settings to point to system binaries when bundled is not possible.
6) Media pipeline (client)
   - Ingest: download or load local file; validate size/format.
   - Normalize: ffmpeg scale to 9:16 target height, clamp bitrate; write to temp workspace.
   - Highlight detection:
     - Default: call backend/OpenAI with transcript.
     - Optional: local LLM if available.
   - Clip rendering: ffmpeg slice + reframe; optional subtitles via local transcript.
   - Persist workspace under app data directory; clean up on completion.
7) Sync with backend
   - Push metadata: video, clip timings, captions, statuses.
   - Optional: upload rendered assets if cloud storage is desired.
   - Keep offline cache (e.g., SQLite/hive) and reconcile on reconnect.
8) Publishing (optional)
   - If centralized: call backend publish endpoints.
   - If client-side: store user platform tokens locally and post from the client.
9) UX essentials
   - Progress indicators for download/normalize/render.
   - Error surfacing with logs; allow retry/requeue.
   - Settings: choose local vs cloud highlights, ffmpeg path, OpenAI key.
10) Testing/CI
    - `flutter format`/`analyze`/`test`.
    - Build checks for macOS/Windows/Linux; optional mobile build smoke.
    - Lint generated API client into the repo (or pin generator version).

## Deployment & Distribution
- Desktop: package per platform (dmg/msix/AppImage). Start with unsigned builds for internal testing.
- Mobile: TestFlight / Play Internal for testers; consider deferring mobile rendering if perf is inadequate.
- Update strategy: in-app update checks or link to release downloads.

## Backend Touchpoints
- Ensure backend OpenAPI is current and published for client generation.
- Add endpoints (if needed) for:
  - Uploading rendered assets (optional).
  - Fetching feature flags/config.
  - Publishing hooks (stub or real).
- Keep `MEDIA_STORAGE_DIR`/worker config cloud-side minimal since rendering moves local.

## Operational Notes
- Keep a single volume-backed worker in the cloud (or none, if rendering is 100% client-side).
- Use rate limiting and input validation on backend ingest endpoints.
- Enforce auth on all backend routes; keep secrets out of the client binary (user-provided API keys only, or short-lived tokens from backend).

## Milestones
1) Scaffold app, auth, API client; simple dashboard pulling backend metadata.
2) Local ingest + normalize + render on desktop; push metadata to backend.
3) Transcript + highlight (cloud via OpenAI); wiring to clip creation locally.
4) Optional local transcript/highlights; settings panel for OpenAI key and binary paths.
5) Publishing flow (backend-owned; client triggers/polls and uploads assets if required); packaging and release builds for desktop.

## Near-term desktop epics (pipeline-first)
- Auth + config bootstrap: generate client from OpenAPI (once published), login/refresh wiring, fetch feature flags/config.
- Ingest + workspace: YouTube URL or file import, workspace layout (/ingest,/normalize,/render,/logs), hashing/validation.
- Tooling & settings: detect `ffmpeg`/`yt-dlp`, settings UI for binary paths and OpenAI key (if direct calls allowed).
- Normalize & render: ffmpeg pipeline to 9:16 target, bitrate clamp, clip slicing, process log streaming, cancel/retry.
- Transcripts/subtitles: local-first `whisper.cpp` for transcripts (with cloud/OpenAI fallback if disabled/failing); burn-in subtitles during render.
- Sync/offline: push video/clip metadata, captions, statuses; offline cache (Hive/SQLite) and reconciliation on reconnect.
- UI shells: auth → dashboard → job detail with stage progress → settings/logs.

## OpenAPI TODO
- Publish and commit the FastAPI OpenAPI spec.
- Include publish endpoints, status enums, config/feature flags endpoint, and asset upload/signed-URL contract.

## Immediate next steps
- Create architecture doc outlining platform targets, local tool distribution strategy, app data/workspace layout, and sync model.
- Bootstrap Flutter project with flavors/env wiring and initial auth flow stub.
- Pull/export latest `forgotten-app` OpenAPI spec and lock generator version for reproducible client builds.
