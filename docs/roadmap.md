# TV7 Roadmap (Core & Pro) — aligned to `tv7_high_architecture.md`

## Phase 1 — Local Pipeline + Cloud Highlights (Core-first)
- Solidify ingest workspace (`ingest/normalize/render/logs/cache`), dependency checks (`ffmpeg`, `yt-dlp`), and UX for ingest (YouTube/file), progress, and diagnostics/log export.
- Align clip suggestion endpoint/schema (transcript + prompt → segments with titles/descriptions/hooks); use cloud/backend LLM for highlights and auto-clip creation.
- Improve clip rendering/editing: timeline/trim, subtitle burn-in, explicit export flow; keep uploads optional.
- Basic persistence: local cache/queue for videos/clips/uploads; retry on reconnect; error mapping.

### Phase 1 Plan
- **Backend/spec**
  - Ensure clip suggestion endpoint/schema is in OpenAPI (transcript + optional prompt → segments with start/end/title/description/hook) and regenerate SDK.
  - Keep login/refresh as-is for now; add only what’s needed for highlights/ingest if missing (e.g., video/clip endpoints).
- **Client pipeline**
  - Harden ingest + workspace handling; dependency detection and user guidance.
  - Wire SDK clip suggestion call into auto-clip flows; better error UX/fallback messaging.
  - Add timeline/trim/subtitle/export surfaces around the existing ffmpeg flow.
  - Add lightweight local cache/queue for metadata/uploads with retries.
- **Testing**
  - Unit/service tests for clip suggestion mapping, pipeline arg builders, error handling, and queue retry logic.
  - Smoke: ingest → transcript → highlights → auto-clip render → export.

### Phase 1 Execution Backlog (ordered)
1) Inspect OpenAPI spec for clip suggestion and video/clip fields; update spec if needed and regenerate `lib/api/generated`.
2) Replace ad-hoc highlight call with SDK endpoint; map response to auto-clip flows with error handling/fallback messaging.
3) Harden ingest workspace handling: dependency checks (`ffmpeg`, `yt-dlp`), workspace hygiene, log capture/export, UX for progress/errors.
4) Expand export/edit surfaces: timeline/trim controls, subtitle burn-in option, explicit export flow (keep uploads optional).
5) Add lightweight local cache/queue for video/clip metadata/uploads with retry on reconnect; friendly error mapping in UI.
6) Tests: unit/service for clip suggestion mapping, pipeline arg builders, queue retry; smoke path covering ingest → highlights → auto-clip → export.

## Phase 2 — Local Pipeline Completeness (Core)
- Integrate Whisper.cpp: model selection/download paths, hardware checks, fallback to backend transcription if disabled/failing.
- Expand pipeline robustness (cancellations, retries, better progress), subtitles, and richer editing polish.
- Grow local cache/queue (SQLite/Hive) for videos/clips/uploads; friendlier error mapping and recovery.

## Phase 3 — Pro Scheduler
- Upload flow to backend storage (direct or signed URL), schedule create/update, status polling; display posted/failed with logs.
- WebView to backend dashboard for OAuth/platform connections; reflect connected platforms in client config.
- Worker contract surfaced in UI (status enums, retries, errors); optional notifications/poll cadence.

## Phase 4 — Licensing, Config, & Distribution
- Add trial/activation/license issuance/refresh endpoints to backend and spec; implement secure token store + cached license token; gate features by plan/expiry; offline allowed while valid.
- Config fetch and enforcement (publishing/platform/size limits, OpenAI/local policy); surface plan/config in settings.
- Settings UX for binaries/model paths, license/account view, log export; desktop packaging (dmg/msix/AppImage); minimal mobile parity; telemetry/analytics (opt-in), updates, and release playbooks.

## Immediate Actions
- Update OpenAPI with clip suggestion schema (and any missing video/clip fields), regenerate `lib/api/generated`.
- Harden ingest and auto-clip flow using SDK highlight endpoint; improve error UX.
- Lay groundwork for local cache/queue and export flow; keep existing login/refresh unchanged for now.
