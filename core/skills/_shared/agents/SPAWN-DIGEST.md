# Spawn digest (session start)

Short map loaded at session start only after effective `subagents=native` is confirmed and the orchestration preference has been read. If capability is `none`, unknown, or unavailable, skip this file and all spawn/model-choice contracts. Full contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md`.

## Rule

Heavy work (multi-file analysis, multi-file edits, builds/tests, deep investigation, non-trivial planning) goes to subagents when `subagents=native`. Any doubt about spreading: spawn. Children cannot spawn children.

## Specialists by role

| Role | Agent type | Use for |
|------|------------|---------|
| Impact and brownfield analysis | `repo-analyst` | Map affected code, APIs, integration surface |
| Solution design | `architect` | Architecture, domain design, ARCH notes |
| Threat review | `security` | Auth, secrets, PII, supply-chain |
| Persistence | `database` | Schema, migrations, data contracts |
| Implementation | `developer-child` | Scoped code changes for a stack developer flow |
| Commands | `shell-runner` | One authorized script, build, or test command |

## Session-start model choice

Read the full `SPAWN.md` (caps, fallback when Agent is unavailable, handoff payload, model param). Omit the Agent `model` by default. At session start, read `SUBAGENT-MODEL.md`, discover the current host's available complete pairs, then ask the one-time session model/effort choice before skill/task work that can delegate. This question does not decide whether to delegate. Never offer a generic `pair` choice when no complete pairs were discovered; offer only `inherit` and explain the limitation.

## Checklist and log

Stay in the parent only in `adaptive`, and only when edited <= 3, read <= 6, lines <= 150 and no exclusion (security, shared contract, full build/suite/batch script, scope not countable in 2 searches). Otherwise delegate. `always` delegates everything except `qa_checklist`. Log one line per decision: `[Spawn] <verb> mode=<m> edited=<n> read=<n> lines=<n> criterion=<code>`. Caps: `*-developer` 2, `orchestrate-*` 4. Continuations: max 2, read-only, same topic and scope. Rules and codes: `SPAWN.md`; roles: `ROSTER.md`.
