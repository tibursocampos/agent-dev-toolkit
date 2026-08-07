# Skills catalog (agent SoT)

Lean skill map for agents after install. **Do not invent skills** — only names listed here exist as skill ids. Invoke by **skill id**; host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full host matrix: sibling `OPERATOR.md`.

**Load via skill `help-skills`** (or Read this path). Operator nuances: sibling `OPERATOR.md` in this folder. Shared packs under `_shared/` are not invocable skills. There is **no** `architect` skill — architect is spawned from `orchestrate-analyze` / the agent roster.

Installed path (after sync): `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md`

Total: **38** kebab skills.

## Formas (A / B / C)

| Forma | Skills | When |
|-------|--------|------|
| **A** Classic SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` | One clear feature |
| **B** Backlog prep | `refine-story`, `split-story-checklist` | Rough bug/story first |
| **C** Orchestrated | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` | Multi-story / brownfield |

## Classic SDD (Forma A)

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `sdd-spec` | `sdd-spec` | Create a PRD for a new feature or change |
| `sdd-plan` | `sdd-plan` | Baby-step PLAN from an existing PRD |
| `sdd-develop` | `sdd-develop` | Execute **one** PLAN step per session |

## Forma B — backlog prep

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `refine-story` | `refine-story` | Refine bug/story into structured markdown + BDD |
| `split-story-checklist` | `split-story-checklist` | Dependency-aware task checklist (BE/FE/tests) |

## Forma C — orchestration

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `memory-bank-init` | `memory-bank-init` | Create/refresh `memory-bank/` at repo or global root (Step 0; never under `features/NNN-slug/`) |
| `orchestrate-analyze` | `orchestrate-analyze` | Triage, specialists, backlog structure |
| `orchestrate-deliver` | `orchestrate-deliver` | PRD + PLAN per story via SDD contracts |
| `orchestrate-develop` | `orchestrate-develop` | One PLAN step per subagent via `sdd-develop` |

## Developer routing and stack

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `developer` | `developer` | Hybrid router: detect stack or ad-hoc scripts |
| `dotnet-developer` | `dotnet-developer` | Small/medium .NET without full SDD |
| `java-developer` | `java-developer` | Small/medium Java / Spring Boot |
| `react-developer` | `react-developer` | Small/medium React |
| `react-native-developer` | `react-native-developer` | React Native / Expo |
| `angular-developer` | `angular-developer` | Angular |
| `vue-developer` | `vue-developer` | Vue 3 |
| `blazor-developer` | `blazor-developer` | Blazor (WASM/Server/Hybrid) |
| `electron-developer` | `electron-developer` | Electron desktop |
| `javascript-developer` | `javascript-developer` | JavaScript/Node |
| `python-developer` | `python-developer` | Python |

## Blip plugins and design

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `blip-plugin-developer` | `blip-plugin-developer` | Scaffold Blip React extensions → `react-developer` |
| `impeccable` | `impeccable` | UI/UX design router → `DESIGN-BRIEF.md` |

## Operational

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `help-skills` | `help-skills`, `list skills`, `skill catalog` | Present this catalog + `OPERATOR.md` (static) |
| `code-review` | `code-review` | Structured review (quality / acceptance / security) |
| `repair-dotnet-build` | `repair-dotnet-build` | Diagnose/fix .NET build and tests |
| `test-coverage` | `test-coverage` | .NET Coverlet coverage report |
| `commit` | `commit`, `commit changes` | Conventional commit on a valid feature branch |
| `push` | `push`, `push changes` | Safe git push after confirmation |
| `open-github-pr` | `open-github-pr` | Create GitHub PR via `gh` |
| `ef-add-migration` | `ef-add-migration` | EF Core migration discovery |
| `scaffold-message-handler` | `scaffold-message-handler` | Message consumer scaffold |
| `refactor` | `refactor` | Safe incremental refactoring |
| `api-integrate` | `api-integrate` | Typed API clients from OpenAPI |
| `performance-profile` | `performance-profile` | Profiling and optimization |
| `containerize` | `containerize` | Dockerfiles and compose |
| `i18n-manager` | `i18n-manager` | Extract strings to localization files |

## Documentation (RAG)

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `document-plan` | `document-plan`, `doc plan` | Baby-step documentation plan |
| `document-implement` | `document-implement` | Execute one documentation plan step |
