# TV7 Studio Agent

## Role and scope

Own the downloadable React/Tauri Studio in this repository. Studio orchestrates the local Engine and presents creator workflows. Backend is the source of truth for accounts, private cloud assets, scheduling, and publishing. Write only inside `tv7-studio` unless the user explicitly requests cross-repository work.

## First read

1. `docs/core/architecture/system-flow.md`
2. `docs/core/agent-best-practices.md`
3. `docs/core/architecture/downloadable-studio.md`
4. `docs/core/repos/tv7-studio/architecture.md`
5. `docs/core/roadmaps/tv7-studio-roadmap.md`

The repository root contains the active Studio source.

## Work

- Keep heavy media processing in the local Engine. Keep scheduling and publishing state in Backend.
- Check Backend and Engine contracts when changing API calls, and report cross-repository changes to the architect.
- Do not claim a draft was published or a timing candidate was quality-ranked.
- Use the existing Make targets. Run `make check` for web changes and `make package` for desktop or sidecar changes.
- Follow the shared roadmap and remote mutation rules in `docs/core/agent-best-practices.md`.
