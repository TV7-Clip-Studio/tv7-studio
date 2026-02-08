---
name: studio-feature-vertical-slice
description: Implement a Flutter Studio feature end-to-end across UI, domain/data layers, and tests while preserving repository architecture boundaries. Use when shipping a new feature, expanding an existing feature flow in `forgotten_client/lib`, or refactoring a feature that spans multiple layers.
metadata:
  short-description: Build Studio features end-to-end
---

# Studio Feature Vertical Slice

Ship one coherent feature slice across presentation, app logic, and data integrations with test coverage.

## Workflow

1. Define the slice boundary first.
   - User interaction and screen entry point
   - Required domain behavior
   - Required API/local storage interactions
2. Map files before coding.
   - Optional helper: `./.codex/skills/studio-feature-vertical-slice/scripts/locate_feature_scope.sh <feature-name>`
   - UI: `forgotten_client/lib/features/<feature>/...`
   - Data: `forgotten_client/lib/data/...`
   - Config/domain helpers: `forgotten_client/lib/config/...` and adjacent modules
3. Check cross-repo impact early.
   - If API contract changes are needed, use `studio-openapi-sync` workflow and coordinate with backend.
4. Implement in this order.
   - Add or update data/repository layer interfaces.
   - Wire domain/use-case logic.
   - Implement UI and interaction state.
5. Protect architecture boundaries.
   - UI should not directly embed low-level API process logic.
   - Keep external IO in data/local/api layers.
6. Add tests with the same vertical intent.
   - Service/unit tests in `forgotten_client/test/data/...`
   - Widget tests in `forgotten_client/test/features/...`
7. Run quality gates.
   - `make format`
   - `make analyze`
   - `make test`
   - Or single command: `make check`

## Bundled Resources

### scripts/locate_feature_scope.sh

Finds existing files and directories related to a feature keyword across `forgotten_client/lib/features`, `forgotten_client/lib/data`, and `forgotten_client/test`.

Usage:
- `./.codex/skills/studio-feature-vertical-slice/scripts/locate_feature_scope.sh ingest`

## Done Criteria

- Feature works through one complete user flow.
- Tests cover core happy path and one failure path.
- `make check` passes.
- Cross-repo API dependencies are documented when applicable.
