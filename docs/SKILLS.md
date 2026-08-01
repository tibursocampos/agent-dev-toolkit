# Skills catalog

Canonical kebab-case skill folders under `core/skills/` (**36 skills** + `_shared`). After sync, invoke them in your agent (Cursor slash form: `/<name>`). Compat phrases such as `use skill <name>` may also work depending on the agent.

Shared packs live under `core/skills/_shared/` (SDD contracts helpers, guidelines, templates) — not invoked as slash skills.

**Guidelines + architecture:** `code-guidelines/principles/` (selection A + style pack B), stack `*-guidelines` overlays (C), and specialist prompts under `_shared/agents/` (including **architect**). The architect path is spawned from `orchestrate-analyze` / the agent roster — there is **no** `/architect` slash skill. See [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

## Formas (A / B / C)

| Forma | Skills | When |
|-------|--------|------|
| **A** Classic SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` | One clear feature |
| **B** Backlog prep | `refine-story`, `split-story-checklist` | Rough bug/story first |
| **C** Orchestrated | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` | Multi-story / brownfield |

Decision tree: [guides/README.md](guides/README.md).

## Classic SDD (Forma A)

| Skill | Purpose |
|-------|---------|
| `sdd-spec` | Create a PRD for a new feature or change |
| `sdd-plan` | Baby-step PLAN from an existing PRD |
| `sdd-develop` | Execute **one** PLAN step per session |

Example after Cursor sync:

```text
/sdd-spec
/sdd-plan - <prd-path>
/sdd-develop - <plan-path> - Step N
```

## Forma B — backlog prep

| Skill | Purpose |
|-------|---------|
| `refine-story` | Refine a bug, user story, or technical story into structured markdown with BDD acceptance |
| `split-story-checklist` | Break refined steps into a dependency-aware task checklist (backend, frontend, tests) |

Prefer story folders when present; see [guides/README.md](guides/README.md).

## Forma C — orchestration

| Skill | Purpose |
|-------|---------|
| `memory-bank-init` | Create/refresh repo `memory-bank/` (Step 0 for Forma C) |
| `orchestrate-analyze` | Triage, specialists, backlog structure |
| `orchestrate-deliver` | PRD + PLAN per story via `sdd-spec` / `sdd-plan` contracts |
| `orchestrate-develop` | One PLAN step per subagent via `sdd-develop` contract |

Orchestrators **reuse** classic SDD contracts; they do not replace them.

## Developer routing and stack

| Skill | Purpose |
|-------|---------|
| `developer` | Hybrid router: detect stack and delegate, or ad-hoc scripts |
| `dotnet-developer` | Small/medium .NET without full SDD |
| `java-developer` | Small/medium Java / Spring Boot without full SDD |
| `react-developer` | Small/medium React without full SDD |
| `react-native-developer` | React Native / Expo without full SDD |
| `angular-developer` | Angular without full SDD |
| `vue-developer` | Vue 3 without full SDD |
| `blazor-developer` | Blazor (WASM/Server/Hybrid) without full SDD |
| `electron-developer` | Electron desktop without full SDD |
| `javascript-developer` | JavaScript/Node without full SDD |
| `python-developer` | Python without full SDD |

## Blip plugins and design

| Skill | Purpose |
|-------|---------|
| `blip-plugin-developer` | Scaffold Blip React extensions; hand off to `react-developer` |
| `impeccable` | UI/UX design router; shape → `docs/DESIGN-BRIEF.md` |

## Operational

| Skill | Purpose |
|-------|---------|
| `code-review` | Structured review (quality / acceptance / security angles) |
| `repair-dotnet-build` | Diagnose/fix .NET build and tests |
| `test-coverage` | .NET Coverlet coverage report |
| `commit` | Conventional commit on a valid feature branch |
| `push` | Safe git push after confirmation |
| `ef-add-migration` | EF Core migration discovery |
| `scaffold-message-handler` | Message consumer scaffold |
| `refactor` | Safe incremental refactoring |
| `api-integrate` | Typed API clients from OpenAPI |
| `performance-profile` | Profiling and optimization |
| `containerize` | Dockerfiles and compose |
| `i18n-manager` | Extract strings to localization files |

## Documentation (RAG)

| Skill | Purpose |
|-------|---------|
| `document-plan` | Baby-step documentation plan under `docs/documentation-plan/` |
| `document-implement` | Execute one documentation plan step |

## After sync — sanity check

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
```

Live Cursor home should contain `skills/sdd-spec/SKILL.md` (and peers). See [INSTALL.md](INSTALL.md) and [guides/02-using-skills.md](guides/02-using-skills.md).
