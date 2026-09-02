# Skills catalog

Canonical kebab-case skill folders under `core/skills/` (**40 skills** + `_shared`). After sync, invoke by **skill id**. Host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full matrix: [guides/02-using-skills.md](guides/02-using-skills.md).

**Agent source of truth (installed):**  
- Map: `core/skills/_shared/skills-catalog/CATALOG.md`  
- Operator nuances: `core/skills/_shared/skills-catalog/OPERATOR.md`  

Present both via skill **`help-skills`** (all adapters) — do not load every `SKILL.md` and do not re-analyze the static guide. This file (`docs/SKILLS.md`) is the human/clone mirror and must stay name-count aligned with disk (**40** kebab skills).

Shared packs live under `core/skills/_shared/` — not invoked as skills (except the catalog pack is read by `help-skills`).

**Parallel specialists (default):** after sync, the router prefers parallel specialist subagents for multi-facet planning / analysis / questions; this session stays parent. See `core/router/AGENTS.md` and [SPAWN.md](SPAWN.md). Language: user chat + artifacts match chat; spawn/receipts **en-US** (`LANGUAGE.md`). Operator norms: `needs_*` → `ROSTER.md` spawn map; Task `model` omit (inherit parent) unless `SUBAGENT-MODEL.md` gate + **sim**; `orchestrate-*` parents coordinate / receipts only — **no** application code. Orchestrator charter + `orchestrator_mode` prefs: [guides/08-orchestrator-mode.md](guides/08-orchestrator-mode.md).

**Guidelines + architecture:** `code-guidelines/principles/` (selection A + style pack B), stack `*-guidelines` overlays (C), and specialist prompts under `_shared/agents/` (including **architect**). The architect path is spawned from `orchestrate-analyze` / the agent roster — there is **no** `architect` skill. See [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

Credits for Caveman / Impeccable / Spec Kit inspiration: [CREDITS.md](CREDITS.md).

## Lazy-load (invocable skills)

Contract: `core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md` (enforced by `Assert-SkillLazyLoad.ps1`).

| Piece | Role |
|-------|------|
| `SKILL.md` | Gate + Process; must include `## Lazy-load` and `**Never by default:**` |
| `reference.md` | Optional routing index (≤50 lines when section files exist) |
| `references/*.md` | Section bodies (impeccable may use `reference/`) |

**FAIL** when `**Never by default:**` is missing, or a monolithic `reference.md` is **>150** lines without a split into `references/` (or `reference/`). Agents load only the section needed for the current Process step — never glob all references at skill start.

## Work tracks

| Track | Skills | When |
|-------|--------|------|
| **Classic SDD** | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` | One clear feature |
| **Backlog Refine** | `refine-story`, `split-story-checklist` | Rough bug/story first |
| **Orchestrated Delivery** | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` | Multi-story / brownfield |

Use these track names only (no legacy Forma aliases). Same call flow; extra gates and artifacts inside — not new skills or tracks as products.

**Invocation / provenance / `source_context`:** `direct` vs `orchestrated`, `agreed` vs `invented`, language/spawn lock, and when to call `read-sdd-artifact` — [domains/core.md](domains/core.md) § Invocation contexts / Contract provenance / Language / `read-sdd-artifact`.

**Backlog helpers (shared, not slash skills):** folder `core/skills/_shared/backlog-item-types/` — `story-sizing.md`; optional `persona-context.md` (Who/Job/Outcome for **User Stories** only); product-quality norms (`invest-and-story-quality.md`, `anti-task-shatter.md`, `gherkin-budget.md`, `feature-altitude.md`, …). FEATURE table includes a **Product intent** column. Load **one** file at a time. Detail: [Product artifact quality](domains/core.md#product-artifact-quality-backlog-item-types). Selective retrieval, REQ-ID, CHANGE, EVD/STATE, and TRACE living-loop remain gates inside the skills above.

Decision tree: [guides/README.md](guides/README.md).

## Classic SDD

| Skill | Purpose |
|-------|---------|
| `sdd-spec` | Create a PRD for a new feature or change |
| `sdd-plan` | Baby-step PLAN from an existing PRD |
| `sdd-develop` | Execute **one** PLAN step per session |
| `read-sdd-artifact` | Normalize FEATURE/STORY/PRD/PLAN under `features/` into `source_context` (reject traversal / outside features) |

Example (skill ids; prefix with your host form from [02-using-skills.md](guides/02-using-skills.md)):

```text
sdd-spec
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step N
```

## Backlog Refine

| Skill | Purpose |
|-------|---------|
| `refine-story` | Refine a bug, user story, or technical story into structured markdown with BDD acceptance |
| `split-story-checklist` | Break refined steps into a dependency-aware task checklist (backend, frontend, tests) |

**`refine-story` modes (mandatory — no silent default):**

| Mode | When | Default item types | Playbook (lazy) |
|------|------|--------------------|-----------------|
| **feature** | Product-facing outcome or defect | User Story or Bug (`USnn`) | `core/skills/refine-story/references/feature.md` |
| **tech** | Technical problem → solution | Technical Story (`TSnn`) | `…/references/tech.md` |
| **split** | Steps ready for checklist | Any type — shape deps / parallel-safe | `…/references/split.md` |

If the invoke omits a mode, the skill asks once (pt-BR) and loads **only** the chosen playbook — never all three. Mode `split` prepares input for `split-story-checklist`; it does not invent a fourth work track. Detail: [domains/core.md](domains/core.md) § Composable skills · [Product artifact quality](domains/core.md#product-artifact-quality-backlog-item-types).

Prefer story folders when present; see [guides/README.md](guides/README.md).

## Orchestrated Delivery

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
| `api-integrate` | Typed API clients / DTOs from OpenAPI |
| `api-standards` | Agnostic HTTP/API design standards (REST, versioning, errors, naming, security hygiene) — packing only; no company contracts |
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
| Orchestrated Delivery | Memory-bank Step 0; backlog **sim**; architect ARCH draft → **sim** on greenfield / `needs_domain`; O1 `needs_*` → `ROSTER.md`; Task `model` inherit unless gated + **sim**; orchestrate parents no app code; orchestrator mode [08](guides/08-orchestrator-mode.md) |
| `sdd-develop` | One PLAN step per session |
| `refine-story` | Choose mode `feature` \| `tech` \| `split` (no silent default); load one mode playbook; scorecard uses one `backlog-item-types` norm at a time |
| `split-story-checklist` | SMART tasks under parent story — never US-per-file (anti-task-shatter) |
| `api-standards` vs `api-integrate` | Standards / design review → `api-standards`; OpenAPI → typed clients → `api-integrate` |
| `document-plan` | Asks doc language before writing |
| Caveman | Default OFF; [guides/07-caveman-mode.md](guides/07-caveman-mode.md) |
| Lazy-load / phased split | `SKILL.md` + one section per step; monolith `reference.md` >150 lines must split — [SKILL-REFERENCE-RETRIEVAL.md](../core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md) |

Installed static notes: `_shared/skills-catalog/OPERATOR.md` via `help-skills`.

## After sync — sanity check

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
```

Live install should contain `skills/help-skills/SKILL.md` and peers under that agent’s root. See [INSTALL.md](INSTALL.md) and [guides/02-using-skills.md](guides/02-using-skills.md).
