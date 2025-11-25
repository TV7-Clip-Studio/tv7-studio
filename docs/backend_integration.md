# Backend Coordination (forgotten-app FastAPI)

Goal: align the existing FastAPI ingest/pipeline with the Flutter client so responsibilities are clear and the API contract is stable.

## Ownership split
- Client (Flutter): ingest (yt-dlp/import), normalize/render via ffmpeg, optional local transcript/highlights, workspace management, retries/logging, secure storage of user keys.
- Backend (FastAPI): auth/JWT, metadata/status source of truth, feature flags/config, optional cloud transcript/highlights via OpenAI, optional asset upload/publishing, rate limiting/validation.

## API contract (to publish)
- OpenAPI spec exported and versioned for client generation.
- Endpoints to confirm/adjust:
  - Auth: login/refresh/logout.
  - Metadata: videos/clips CRUD, status updates, transcript/highlight payloads.
- Feature flags/config fetch.
- Optional: rendered asset upload, publishing hooks.

## Publishing contract (cloud-owned)
See `docs/publishing_contract.md` for division of responsibilities. Summary:
- Backend owns platform tokens, publish job orchestration, retries.
- Client uploads assets if required (or uses signed URLs) and triggers publish; polls status.
- If no asset is uploaded, clip stays `ready_local_only` and publish is disabled.

## Next steps for FastAPI alignment
- Add `/config` endpoint for feature flags (publishing_enabled, asset_upload_required, allowed platforms, size limits, OpenAI policy).
- Add publish endpoints to OpenAPI: `POST /clips/{id}/publish`, `GET /clips/{id}/publish` (jobs/status/logs), with asset_url/checksum/size fields and status enums.
- Define asset intake contract: signed URL issuance or direct upload endpoint; document in OpenAPI.
- Export and commit OpenAPI spec for client generation; add Make target/script to regenerate.
- If spec is missing, generate a fresh OpenAPI export (include auth/login/refresh, ingest, status, publish stubs, config).
- Current gaps in exported spec (forgotten-app.json):
  - No config/feature flags endpoint.
  - No client-driven metadata push endpoints (for local pipeline results).
  - No asset upload/signed-URL negotiation beyond publish request fields (asset_url/checksum/size present only in publish payload).

## Pipeline alignment
- Define states shared between client and backend (e.g., `ingested`, `normalized`, `rendered`, `failed`, `published`).
- Client sends: job metadata, clip timings, transcripts/captions, highlight selections, statuses.
- Backend responds: authoritative state, feature flags, optional cloud highlight results, publishing results/errors.
- Reconciliation rules: server authoritative on shared fields; client retries with backoff; offline queue pushes on reconnect.

## Keys/policies
- Decide whether the client may call OpenAI directly with user-supplied keys or must use backend-provided short-lived tokens/proxy.
- Enforce policy per flavor/environment; block or allow direct keys accordingly.

## Next actions
- Publish the current FastAPI OpenAPI spec to `forgotten_client/openapi/forgotten-app.yaml`.
- Add/adjust endpoints for feature flags/config and (if needed) asset upload/publishing.
- Define shared status enum and payload shapes; document in the spec.
- Generate the Dart client and wire login/refresh; build a dashboard hitting a metadata endpoint to validate the contract.
