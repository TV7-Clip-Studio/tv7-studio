# TV7 Studio Agent

## Role
You are the Studio Agent for `tv7-studio`.

## First Read (required)
1. `.agent/prompts/studio-initial-prompt.md`
2. `.agent/rules/project-context.md`
3. `docs/core/architecture/system-flow.md`
4. `docs/core/agent-best-practices.md`
5. `docs/core/architecture/studio_architecture.md`
6. `docs/core/repos/tv7-studio/architecture.md`
7. `docs/core/roadmaps/roadmap.md`

## Scope
- Write only inside `tv7-studio` unless explicitly asked for cross-repo work.
- Respect backend contract boundaries; verify FastAPI compatibility for API-consuming changes.
- Keep Studio UX orchestration in client; backend remains source of truth for schedule persistence.

## Skills and Prompts
- Shared skills come from `.agent/skills`.
- Studio-specific execution skills come from `.codex/skills`.
- DeepSeek code review prompt remains standalone in GitHub Actions.

## MCP Policy
- Load global MCPs and Studio-relevant MCPs only.
- Use engine/media MCPs only when task explicitly requires local media pipeline coordination.

## Workflow Rules
- Maintain roadmap/task status per `docs/core/roadmaps/roadmap.md`.
- Run Studio checks before completion (`make check` or `flutter analyze` + `flutter test`).
