# Skills catalog

Canonical kebab-case skill folders under `core/skills/` (**52 skills** + `_shared`). After sync, invoke by **skill id**. Host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full matrix: [guides/02-using-skills.md](guides/02-using-skills.md).

**Agent source of truth (installed):**  
- Map: `core/skills/_shared/skills-catalog/CATALOG.md`  
- Operator nuances: `core/skills/_shared/skills-catalog/OPERATOR.md`  

Present both via skill **`adt-help-skills`** (all adapters) — do not load every `SKILL.md` and do not re-analyze the static guide. This file (`docs/SKILLS.md`) is the human/clone mirror and must stay name-count aligned with disk (**52** kebab skills).

Shared packs live under `core/skills/_shared/` — not invoked as skills (except the catalog pack is read by `adt-help-skills`).

**Parallel specialists (default):** after sync, the router prefers parallel specialist subagents for multi-facet planning / analysis / questions; this session stays parent. See `core/router/AGENTS.md` and [SPAWN.md](SPAWN.md). Language: user chat + artifacts match chat; spawn/receipts **en-US** (`LANGUAGE.md`). Operator norms: `needs_*` → `ROSTER.md` spawn map; Task `model` omit (inherit parent) unless `SUBAGENT-MODEL.md` gate + `confirm` answer; `adt-orchestrate-*` parents coordinate / receipts only — **no** application code. Orchestrator charter + `orchestrator_mode` prefs (default `adaptive` for every adapter; existing preferences files keep their value): [guides/08-orchestrator-mode.md](guides/08-orchestrator-mode.md).

**Guidelines + architecture:** `code-guidelines/principles/` (selection A + style pack B), stack `*-guidelines` overlays (C), and specialist prompts under `_shared/agents/` (including **architect**). The architect path is spawned from `adt-orchestrate-analyze` / the agent roster — there is **no** `architect` skill. See [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

Credits for Caveman / Spec Kit inspiration: [CREDITS.md](CREDITS.md).

## Lazy-load (invocable skills)

Contract: `core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md` (enforced by `Assert-CoreContracts.ps1`).

| Piece | Role |
|-------|------|
| `SKILL.md` | Gate + Process; must include `## Lazy-load` and `**Never by default:**` |
| `reference.md` | Optional routing index (≤50 lines when section files exist) |
| `references/*.md` | Section bodies |

**FAIL** when `**Never by default:**` is missing, or a monolithic `reference.md` is **>150** lines without a split into `references/` (or `reference/`). Agents load only the section needed for the current Process step — never glob all references at skill start.

## Work tracks

Classic SDD and Orchestrated Delivery are coexisting tracks. O1/O2/O3 coordinate multi-story work; Classic SDD can start directly for one clear feature. Both use one explicit PLAN approval before implementation, and O3 implementation is serial.

| Role | Skills | When |
|------|--------|------|
| **Orchestrated Delivery** | `adt-epic-planner` (optional), `adt-memory-bank`, `adt-orchestrate-analyze`, `adt-orchestrate-prepare`, `adt-orchestrate-implement` | Optional initiative planning; default feature path. Detail: [sessions/01-orchestrated-delivery.md](sessions/01-orchestrated-delivery.md) |
| **Classic SDD contracts** | `adt-sdd-spec`, `adt-sdd-plan`, `adt-sdd-develop`, `adt-read-sdd-artifact` | Loaded by O2/O3. Also a direct start when one story is already clear. Detail: [sessions/02-classic-sdd.md](sessions/02-classic-sdd.md) |
| **Backlog shape** | `adt-refine-story`, `adt-requirement-review`, `adt-split-story-checklist` | Inside O1 as rules and rubric. Standalone when a product person shapes one item, or when O2 hits open clarification B/I. Detail: [sessions/03-backlog-shape.md](sessions/03-backlog-shape.md) |

Every skill, with the session that expands it: [sessions/09-every-skill.md](sessions/09-every-skill.md). Catalog on disk (`CATALOG.md`) still lists the three names as recommendations so an agent may start at `/adt-sdd-spec` for one clear story. That direct start does not replace the orchestrated path for multi-story or specialist work.

Use these track names only (no legacy Forma aliases). Each flow keeps its own skill boundaries while sharing the simplified approval and progress contracts.

**Invocation / provenance / `source_context`:** `direct` vs `orchestrated`, `agreed` vs `invented`, language/spawn lock, and when to call `adt-read-sdd-artifact` — [domains/core.md](domains/core.md) § Invocation contexts / Contract provenance / Language / `adt-read-sdd-artifact`.

**Backlog helpers (shared, not slash skills):** folder `core/skills/_shared/backlog-item-types/` — `story-sizing.md`; optional `persona-context.md` (Who/Job/Outcome for **User Stories** only); product-quality norms (`invest-and-story-quality.md`, `anti-task-shatter.md`, `gherkin-budget.md`, `feature-altitude.md`, …). Load only what helps the current demand. These references support useful analysis; they do not add approval, file, identifier, or progress gates to Classic/O1/O2/O3. See [PIPELINE.md](../core/skills/_shared/sdd-artifacts/PIPELINE.md).

Decision tree: [guides/README.md](guides/README.md).

## Orchestrated Delivery

For an initiative likely to span multiple features, optionally start with `adt-epic-planner` to create a navigable `EPIC.md`. Then start O1 for one selected feature, for example `/adt-orchestrate-analyze - EPIC.md feature001`. O1 reads only that selected brief and relevant shared context/dependencies; the EPIC is optional and does not replace O1 gates.

Default feature path. Detail: [sessions/01-orchestrated-delivery.md](sessions/01-orchestrated-delivery.md).

| Skill | Purpose |
|-------|---------|
| `adt-epic-planner` | Optional discovery for a multi-feature initiative; creates a navigable `EPIC.md` |
| `adt-memory-bank` | Create/refresh repo `memory-bank/` (Step 0, and refresh-light after code) |
| `adt-orchestrate-analyze` | Proportional triage and targeted specialists; no backlog approval or mandatory sidecars |
| `adt-orchestrate-prepare` | Prepare PRD + PLAN per selected story; one approval for the explicitly listed complete PLAN set |
| `adt-orchestrate-implement` | Serial PLAN-step queue via `adt-sdd-develop`, reconciling each result before next dispatch |

Requirements and evidence stay with the canonical artifacts. CHANGE, CONTINUITY, TASKS and Memory Bank are optional context in Classic/O1/O2/O3; validators are diagnostics unless a concrete consumer requires them. The parent does not write application code.

## ADT Delivery

A feature-to-code flow uses one evolving `features/NNN-slug/PLAN.md` for refinement, planning and progress. The completed plan requires approval before implementation. Final validation and the existing `adt-code-review` skill close the work; cold review is not used. Classic SDD and Orchestrated Delivery remain separate.

| Skill | Purpose |
|-------|---------|
| `adt-delivery-flow` | Coordinate refinement, planning and implementation |
| `adt-delivery-refine` | Refine the demand in the feature plan |
| `adt-delivery-plan` | Complete the same plan for approval |
| `adt-delivery-implement` | Execute the approved plan, validate and run code review |

## Classic SDD contracts

Loaded by deliver and develop. Also a direct start when one story is already clear. Detail: [sessions/02-classic-sdd.md](sessions/02-classic-sdd.md).

| Skill | Purpose |
|-------|---------|
| `adt-sdd-spec` | Create a PRD for a new feature or change |
| `adt-sdd-plan` | Executable PLAN from an existing PRD or sufficiently specified demand |
| `adt-sdd-develop` | Execute an approved PLAN step-by-step or continuously; PLAN owns progress |
| `adt-read-sdd-artifact` | Normalize FEATURE/STORY/PRD/PLAN under `features/` into `source_context` (reject traversal / outside features) |

Direct example (skill ids; prefix with your host form from [02-using-skills.md](guides/02-using-skills.md)):

```text
adt-sdd-spec
adt-sdd-plan - <prd-path>
adt-sdd-develop - <plan-path> - Step N
```

## Backlog shape

O1 may use backlog guidance when useful, without requiring a scorecard or separate refinement gates. Standalone skills are optional preparation. Detail: [sessions/03-backlog-shape.md](sessions/03-backlog-shape.md).

| Skill | Purpose |
|-------|---------|
| `adt-refine-story` | Refine a bug, user story, or technical story into structured markdown with BDD acceptance |
| `adt-split-story-checklist` | Break refined steps into a dependency-aware task checklist (backend, frontend, tests) |
| `adt-requirement-review` | Challenge a feature or story before SDD: `--feature` for functional gaps and criteria, `--tech` for repository-grounded contracts and flows |

**`adt-refine-story` modes (mandatory — no silent default):**

| Mode | When | Default item types | Playbook (lazy) |
|------|------|--------------------|-----------------|
| **feature** | Product-facing outcome or defect | User Story or Bug (`USnn`) | `core/skills/adt-refine-story/references/feature.md` |
| **tech** | Technical problem → solution | Technical Story (`TSnn`) | `…/references/tech.md` |
| **split** | Steps ready for checklist | Any type — shape deps / parallel-safe | `…/references/split.md` |

If the invoke omits a mode, the skill asks once and loads **only** the chosen playbook. Mode `split` prepares input for `adt-split-story-checklist`. It does not create a separate delivery path.

**`adt-requirement-review` modes (mandatory - exactly one per run):**

| Mode | Scope | Playbook (lazy) |
|------|-------|-----------------|
| **--feature** | Functional review: actor, flow, rules, criteria split into atoms | `core/skills/adt-requirement-review/references/feature.md` |
| **--tech** | Repository-grounded review: contracts, surfaces, data flows; follow-ups for `adt-sdd-spec` | `core/skills/adt-requirement-review/references/tech.md` |

Without a mode, the skill asks once. `adt-refine-story` runs it at step 4a before handoff to `adt-sdd-spec`: `--feature`, then `--tech` when the story touches a repository. Output: a review report with `Status: READY` or `Status: NEEDS_CLARIFICATION`, plus Q&A entries under `REFINE/`.

## Developer routing and stack

| Skill | Purpose |
|-------|---------|
| `adt-developer` | Hybrid router: detect stack and delegate, or ad-hoc scripts |
| `adt-dotnet-developer` | Small/medium .NET without full SDD |
| `adt-java-developer` | Small/medium Java / Spring Boot without full SDD |
| `adt-react-developer` | Small/medium React without full SDD |
| `adt-react-native-developer` | React Native / Expo without full SDD |
| `adt-angular-developer` | Angular without full SDD |
| `adt-arduino-developer` | Arduino sketches, libraries, and Arduino Core projects |
| `adt-vue-developer` | Vue 3 without full SDD |
| `adt-blazor-developer` | Blazor (WASM/Server/Hybrid) without full SDD |
| `adt-electron-developer` | Electron desktop without full SDD |
| `adt-esp-idf-developer` | Native ESP-IDF C/C++ firmware without full SDD |
| `adt-javascript-developer` | JavaScript/Node without full SDD |
| `adt-micropython-developer` | MicroPython device firmware for identified ESP32/ESP8266 targets without full SDD |
| `adt-python-developer` | Python without full SDD |

## Blip plugins and design

| Skill | Purpose |
|-------|---------|
| `adt-blip-plugin-developer` | Scaffold Blip React extensions; hand off to `adt-react-developer` |

## Operational

| Skill | Purpose |
|-------|---------|
| `adt-help-skills` | Present installed static `CATALOG.md` + `OPERATOR.md` (no re-analysis) |
| `adt-settings` | Show or save the general model and effort for subagents, or return to inheriting |
| `adt-code-review` | Structured review (quality / acceptance / security angles) |
| `adt-code-explain` | Compare changes or explain existing code without a diff; distinguish observations from inferences; no review verdict |
| `adt-repair-dotnet-build` | Diagnose/fix .NET build and tests |
| `adt-test-coverage` | .NET Coverlet coverage report |
| `adt-run-tests` | Run detected-stack tests; .NET coverage only when the PLAN asks |
| `adt-commit` | Conventional commit on a valid feature branch |
| `adt-push` | Safe git push after confirmation |
| `adt-open-github-pr` | Create GitHub PR via `gh` (feature or release mode); auto-merge ask; feature **`--squash`**, release **`--rebase`** |
| `adt-ef-add-migration` | EF Core migration discovery |
| `adt-scaffold-message-handler` | Message consumer scaffold |
| `adt-refactor` | Safe incremental refactoring |
| `adt-api-integrate` | Typed API clients / DTOs from OpenAPI |
| `adt-api-standards` | Agnostic HTTP/API design standards (REST, versioning, errors, naming, security hygiene) — packing only; no company contracts |
| `adt-framework-upgrade` | Generic framework upgrade orchestrator (audit\|plan\|migrate\|validate; pluggable packs — not a pinned pack); packs cite `_shared/*-guidelines` + official sources |
| `adt-performance-profile` | Profiling and optimization |
| `adt-containerize` | Dockerfiles and compose |
| `adt-i18n-manager` | Extract strings to localization files |

## Documentation (RAG)

| Skill | Purpose |
|-------|---------|
| `adt-document-plan` | Documentation plan under `docs/documentation-plan/` — Kind **new** / **update** / **refactor**; prefer fewer larger steps |
| `adt-document-implement` | Execute one documentation plan step (update may coalesce existing paths; spawn ≤2 only for large new/refactor) |

## Operator expectations (mirror of OPERATOR.md)

| Area | What you will be asked / options |
|------|----------------------------------|
| Git (`adt-commit` / `adt-push` / `adt-open-github-pr`) | `/adt-commit` confirms the message and does not ask about memory bank or project docs. Confirm push. PR feature vs release; confirm title/body; **always** ask auto-merge; merge method = feature **`--squash`** / release **`--rebase`**. Deep dive: [domains/git-ops.md](domains/git-ops.md) |
| `adt-framework-upgrade` | Mode `audit`\|`plan`\|`migrate`\|`validate`; detect `framework_id`; migrate needs a `confirm` answer (silence ≠ approval); skill id must not pin a major |
| `adt-code-review` | Choose single vs multi-angle (no silent default); after Changes required, ask whether to fix and whether to re-run `/adt-code-review` (`confirm`/`skip`). Do not ask about memory bank or project docs. |
| `adt-code-explain` | With both comparison endpoints, compare selected changes; ask for one missing endpoint. Without endpoints, a resolvable topic/symbol or file/folder path explains current code without a diff. Cite opened code and distinguish observations from inferences; no review verdict. |
| Orchestrated Delivery | Optional `adt-epic-planner` and Memory Bank context; O1 investigates proportionally; O2 prepares the complete PLAN set and obtains one approval before implementation; O3 dispatches serially; parents do not write app code; orchestrator mode [08](guides/08-orchestrator-mode.md) |
| `adt-sdd-develop` | Follow the approved PLAN cadence; no SESSION flag or ledger claim is a prerequisite; update the single PLAN progress table |
| `adt-refine-story` | Choose mode `feature` \| `tech` \| `split` (no silent default); load one mode playbook; scorecard uses one `backlog-item-types` norm at a time; open B/I → `NEEDS_CLARIFICATION` (not ready-for-PRD) |
| `adt-split-story-checklist` | SMART tasks under parent story — never US-per-file (anti-task-shatter) |
| `adt-requirement-review` | Exactly one mode (`--feature` or `--tech`), asked once when missing; writes only after a `confirm` answer; `--tech` does not guess repository facts |
| `adt-api-standards` vs `adt-api-integrate` | Standards / design review → `adt-api-standards`; OpenAPI → typed clients → `adt-api-integrate` |
| `adt-document-plan` / `adt-document-implement` | Asks doc language before writing; Kind **new** ≈ one file/step; Kind **update** coalesces existing paths; not 5–12 tiny baby-steps by default |
| Chat language and optional compression | [guides/session-behavior.md](guides/session-behavior.md) |
| Lazy-load / phased split | `SKILL.md` + one section per step; monolith `reference.md` >150 lines must split — [SKILL-REFERENCE-RETRIEVAL.md](../core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md) |

Installed static notes: `_shared/skills-catalog/OPERATOR.md` via `adt-help-skills`.

## After sync — sanity check

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
```

Live install should contain `skills/adt-help-skills/SKILL.md` and peers under that agent’s root. See [INSTALL.md](INSTALL.md) and [guides/02-using-skills.md](guides/02-using-skills.md).
