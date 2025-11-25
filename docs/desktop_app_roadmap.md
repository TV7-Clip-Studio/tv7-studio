# Desktop App Roadmap (Flutter) — Notes

- Publishing: see `docs/publishing_contract.md`. Backend owns platform tokens and publish jobs; client triggers/polls and uploads assets if required. Clips without `asset_url` stay `ready_local_only` (non-publishable).
- API contract: depends on FastAPI OpenAPI spec (auth, ingest, status, publish, config/flags, asset upload/signed URL).
- Config: fetch backend config to decide asset upload requirement and allowed platforms; fall back to cloud when local models are unavailable.
