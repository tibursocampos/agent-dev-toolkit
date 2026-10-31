# Spawn digest (session start)

Short map loaded at the start of every session. Full contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`.

## Rule

Heavy work (multi-file analysis, multi-file edits, builds/tests, deep investigation, non-trivial planning) goes to subagents when `subagents=native`. Thin trivial single-path work stays in the parent. Any doubt about spreading: spawn. Children cannot spawn children.

## Specialists by role

| Role | Agent type | Use for |
|------|------------|---------|
| Impact and brownfield analysis | `repo-analyst` | Map affected code, APIs, integration surface |
| Solution design | `architect` | Architecture, domain design, ARCH notes |
| Threat review | `security` | Auth, secrets, PII, supply-chain |
| Persistence | `database` | Schema, migrations, data contracts |
| Implementation | `developer-child` | Scoped code changes for a stack developer flow |
| Commands | `shell-runner` | One authorized script, build, or test command |

## Before the first non-trivial spawn decision

Read the full `SPAWN.md` (caps, fallback when Agent is unavailable, handoff payload, model param). Omit the Agent `model` by default.
