# forgotten_client (Flutter desktop + mobile)

Unofficial Flutter client for the `forgotten-app` backend, focused on local-first media processing (download/normalize/render/transcribe) while syncing metadata to the cloud. Targets desktop (macOS/Windows/Linux) first, with mobile (iOS/Android) as parity follows.

## Status
- Flutter project scaffolded in `forgotten_client/` with flavor entrypoints (dev/stage/prod) and config wiring via dart-defines.
- Docs added for roadmap, architecture, and scaffolding. OpenAPI generator config/script stubbed; spec not yet pulled.

## Quick objectives
- Single Flutter codebase for desktop/mobile.
- Local-heavy media pipeline to keep cloud costs low; backend handles auth/metadata/optional publishing.
- Pluggable local tools (`ffmpeg`, `yt-dlp`, optional `whisper.cpp`) with user-provided paths or bundled binaries per platform.
- Configurable highlight path: backend/OpenAI vs optional local small model.

## Docs
- `docs/roadmap.md` — delivery milestones and implementation notes (client/backend touchpoints).
- `docs/architecture.md` — platform targets, media pipeline, binaries, config/auth/data layers, sync model.
- `docs/scaffolding.md` — Flutter project layout, flavors/env, dependencies, OpenAPI integration steps.

## Code layout (early scaffold)
- `lib/config/app_config.dart` — flavor/env loader via dart-defines.
- `lib/app.dart` + `lib/bootstrap.dart` — root widget and bootstrap entry.
- `lib/main_*.dart` — dev/stage/prod entrypoints (default `main.dart` points to dev).
- `lib/data/api/api_client.dart` — Dio client with auth interceptor scaffold.
- `lib/data/auth/*` — token models/store and auth repository placeholders.

## Running (flavors)
From `forgotten_client/`:
- Copy env template: `cp .env.dev.example .env.dev` (and stage/prod as needed). These `.env.*` files are JSON maps for `--dart-define-from-file`.
- Dev: `flutter run --flavor dev --dart-define-from-file=.env.dev`
- Stage: `flutter run --flavor stage --dart-define-from-file=.env.stage`
- Prod: `flutter run --flavor prod --dart-define-from-file=.env.prod`

### Make targets (from repo root)
- `make help` — list targets.
- `make format` — `flutter format lib test`.
- `make analyze` — `flutter analyze`.
- `make test` — `flutter test`.
- `make check` — format + analyze + test.
- `make run FLAVOR=dev` — run with `.env.dev` (override `ENV_FILE` as needed).
- `make run-desktop DEVICE=macos ENV_FILE=.env.dev` — desktop run without flavor flag (useful until macOS/Windows/Linux schemes are flavored).
- `make gen-api` — regenerate OpenAPI client (spec must exist at `openapi/forgotten-app.yaml`).

## OpenAPI client
- Place the backend spec at `forgotten_client/openapi/forgotten-app.json` (config points there).
- Regenerate client: `./tool/generate_api.sh` (requires `openapi-generator-cli` on PATH). Generated code lands in `lib/api/generated/`.

## Next up
- Wire auth shell (login/refresh storage) and a basic dashboard pulling backend metadata.
- Integrate OpenAPI client wrapper with auth/retry/logging.
- Start pipeline scaffolding for local ingest + progress reporting (desktop first).
