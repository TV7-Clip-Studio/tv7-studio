---
name: studio-openapi-sync
description: Keep Flutter Studio's generated Dart API client aligned with the canonical FastAPI OpenAPI contract. Use when backend endpoints or schemas change, when `make gen-api` fails, when OpenAPI drift causes analyzer/test failures, or when modifying files under `forgotten_client/lib/api/generated`.
metadata:
  short-description: Sync OpenAPI and regenerate SDK
---

# Studio OpenAPI Sync

Regenerate the Flutter API SDK from the canonical OpenAPI contract and safely adopt the changes in call sites.

## Workflow

1. Verify canonical and local spec paths.
   - Canonical: `docs/core/contracts/openapi/tv7-fastapi-backend/openapi.json`
   - Local generator input: `forgotten_client/openapi/forgotten-app.json`
2. Sync spec into the local generator path.
   - Preferred: run `./.codex/skills/studio-openapi-sync/scripts/sync_spec.sh`
   - Manual fallback: `cp docs/core/contracts/openapi/tv7-fastapi-backend/openapi.json forgotten_client/openapi/forgotten-app.json`
3. Regenerate the SDK.
   - Run: `make gen-api`
   - Script used: `forgotten_client/tool/generate_api.sh`
4. Review generated deltas first.
   - Focus: `forgotten_client/lib/api/generated`
   - Never hand-edit generated endpoint/model files.
5. Update handwritten integration points.
   - Focus: `forgotten_client/lib/data/api/api_client.dart` and feature/repository consumers.
   - Keep auth headers, retries, and error mapping behavior intact.
6. Validate Studio checks.
   - Run: `make check`
   - If failures are API-shape-related, patch handwritten code, not generated code.
7. Apply cross-repo protocol for contract breaks.
   - If change is backend-driven, reference the backend change and contract artifact update.
   - If backend spec is missing required fields, stop and hand off to Backend Agent.

## Bundled Resources

### scripts/sync_spec.sh

Copies the canonical contract from `docs/core/contracts/openapi/tv7-fastapi-backend/openapi.json` to `forgotten_client/openapi/forgotten-app.json` and prints file hashes for traceability.

Usage:
- `./.codex/skills/studio-openapi-sync/scripts/sync_spec.sh`

## Done Criteria

- `make gen-api` succeeds.
- `make check` succeeds.
- No manual logic edits inside generated endpoint/model sources.
- API consumer updates are limited to handwritten app code.
