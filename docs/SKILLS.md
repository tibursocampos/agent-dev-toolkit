# Skills catalog

Canonical kebab-case skill folders under `core/skills/` (**38 skills** + `_shared`). After sync, invoke by **skill id**. Host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full matrix: [guides/02-using-skills.md](guides/02-using-skills.md).

**Agent source of truth (installed):**  
- Map: `core/skills/_shared/skills-catalog/CATALOG.md`  
- Operator nuances: `core/skills/_shared/skills-catalog/OPERATOR.md`  

Present both via skill **`help-skills`** (all adapters) — do not load every `SKILL.md` and do not re-analyze the static guide. This file (`docs/SKILLS.md`) is the human/clone mirror and must stay name-count aligned with disk (**38** kebab skills).

Shared packs live under `core/skills/_shared/` — not invoked as skills (except the catalog pack is read by `help-skills`).

**Parallel specialists (default):** after sync, the router prefers parallel specialist subagents for multi-facet planning / analysis / questions; this session stays parent. See `core/router/AGENTS.md` and [SPAWN.md](SPAWN.md). Language: user chat + artifacts match chat; spawn/receipts **en-US** (`LANGUAGE.md`). Operator norms: `needs_*` → `ROSTER.md` spawn map; Task `model` omit (inherit parent) unless `SUBAGENT-MODEL.md` gate + **sim**; `orchestrate-*` parents coordinate / receipts only — **no** application code.

**Guidelines + architecture:** `code-guidelines/principles/` (selection A + style pack B), stack `*-guidelines` overlays (C), and specialist prompts under `_shared/agents/` (including **architect**). The architect path is spawned from `orchestrate-analyze` / the agent roster — there is **no** `architect` skill. See [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

Credits for Caveman / Impeccable / Spec Kit inspiration: [CREDITS.md](CREDITS.md).

## Work tracks

Canonical operator names (skill ids unchanged). Alias *(formerly Forma …)* only in **this** release; remove in the **following** release (RN07).

| Track | Alias (this release) | Skills | When |
|-------|----------------------|--------|------|
| **Classic SDD** | *(formerly Forma A)* | `sdd-spec`, `sdd-plan`, `sdd-develop` | One clear feature |
| **Backlog Refine** | *(formerly Forma B)* | `refine-story`, `split-story-checklist` | Rough bug/story first |
| **Orchestrated Delivery** | *(formerly Forma C)* | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` | Multi-story / brownfield |

**Phrase:** same SDD/orchestration call flow; extra gates and artifacts inside — not new skills or tracks as products.

Decision tree: [guides/README.md](guides/README.md).

## Classic SDD *(formerly Forma A)*

| Skill | Purpose |
|-------|---------|
| `sdd-spec` | Create a PRD for a new feature or change |
| `sdd-plan` | Baby-step PLAN from an existing PRD |
| `sdd-develop` | Execute **one** PLAN step per session |

Example (skill ids; prefix with your host form from [02-using-skills.md](guides/02-using-skills.md)):

```text
sdd-spec
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step N
```

## Backlog Refine *(formerly Forma B)*

| Skill | Purpose |
|-------|---------|
| `refine-story` | Refine a bug, user story, or technical story into structured markdown with BDD acceptance |
| `split-story-checklist` | Break refined steps into a dependency-aware task checklist (backend, frontend, tests) |

Prefer story folders when present; see [guides/README.md](guides/README.md).

## Orchestrated Delivery *(formerly Forma C)*

| Skill | Purpose |
|-------|---------|
| `memory-bank-init` | Create/refresh repo `memory-bank/` (Step 0 for Orchestrated Delivery) |
| `orchestrate-analyze` | Triage, specialists, backlog structure |
| `orchestrate-deliver` | PRD + PLAN per story via `sdd-spec` / `sdd-plan` contracts |
| `orchestrate-develop` | One PLAN step per subagent via `sdd-develop` contract |

Orchestrators **reuse** Classic SDD contracts; they do not replace them. Internal contracts (REQ, CHANGE, EVD/STATE, TRACE, validate-*) run inside the same invocations.

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
| `impeccable` | UI/UX design router; shape → `docs/DESIGN-BRIEF.md` (partial Impeccable harness — [CREDITS](CREDITS.md)) |

## Operational

| Skill | Purpose |
|-------|---------|
| `help-skills` | Present installed static `CATALOG.md` + `OPERATOR.md` (no re-analysis) |
| `code-review` | Structured review (quality / acceptance / security angles) |
| `repair-dotnet-build` | Diagnose/fix .NET build and tests |
| `test-coverage` | .NET Coverlet coverage report |
| `commit` | Conventional commit on a valid feature branch |
| `push` | Safe git push after confirmation |
| `open-github-pr` | Create GitHub PR via `gh` (feature or release mode) |
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

## Operator expectations (mirror of OPERATOR.md)

| Area | What you will be asked / options |
|------|----------------------------------|
| Git (`commit` / `push` / `open-github-pr`) | Confirm commit message; confirm push; PR feature vs release; confirm title/body; **always** ask auto-merge. Deep dive: [domains/git-ops.md](domains/git-ops.md) |
| `code-review` | Choose single vs multi-angle (no silent default) |
| Orchestrated Delivery *(formerly Forma C)* | Memory-bank Step 0; backlog **sim**; architect ARCH draft → **sim** on greenfield / `needs_domain`; O1 `needs_*` → `ROSTER.md`; Task `model` inherit unless gated + **sim**; orchestrate parents no app code |
| `sdd-develop` | One PLAN step per session |
| `document-plan` | Asks doc language before writing |
| Caveman | Default OFF; [guides/07-caveman-mode.md](guides/07-caveman-mode.md) |

Installed static notes: `_shared/skills-catalog/OPERATOR.md` via `help-skills`.

## After sync — sanity check

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
```

Live install should contain `skills/help-skills/SKILL.md` and peers under that agent’s root. See [INSTALL.md](INSTALL.md) and [guides/02-using-skills.md](guides/02-using-skills.md).
