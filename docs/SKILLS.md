# Skills catalog

Canonical kebab-case skill folders under `core/skills/` (**42 skills** + `_shared`). After sync, invoke by **skill id**. Host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full matrix: [guides/02-using-skills.md](guides/02-using-skills.md).

**Agent source of truth (installed):**  
- Map: `core/skills/_shared/skills-catalog/CATALOG.md`  
- Operator nuances: `core/skills/_shared/skills-catalog/OPERATOR.md`  

Present both via skill **`help-skills`** (all adapters) — do not load every `SKILL.md` and do not re-analyze the static guide. This file (`docs/SKILLS.md`) is the human/clone mirror and must stay name-count aligned with disk (**42** kebab skills).

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

The complete path is **Orchestrated Delivery**. `orchestrate-deliver` runs `sdd-spec` then `sdd-plan` per story. `orchestrate-develop` runs `sdd-develop` once per PLAN step. `orchestrate-analyze` applies the refine scorecard and story gates without invoking `/refine-story`.

| Role | Skills | When |
|------|--------|------|
| **Orchestrated Delivery** | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` | Default feature path. Detail: [sessions/01-orchestrated-delivery.md](sessions/01-orchestrated-delivery.md) |
| **Classic SDD contracts** | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` | Loaded by O2/O3. Also a direct start when one story is already clear. Detail: [sessions/02-classic-sdd.md](sessions/02-classic-sdd.md) |
| **Backlog shape** | `refine-story`, `split-story-checklist` | Inside O1 as rules and rubric. Standalone when a product person shapes one item, or when O2 hits open clarification B/I. Detail: [sessions/03-backlog-shape.md](sessions/03-backlog-shape.md) |

Every skill, with the session that expands it: [sessions/09-every-skill.md](sessions/09-every-skill.md). Catalog on disk (`CATALOG.md`) still lists the three names as recommendations so an agent may start at `/sdd-spec` for one clear story. That direct start does not replace the orchestrated path for multi-story or specialist work.

Use these track names only (no legacy Forma aliases). Same call flow; extra gates and artifacts inside — not new skills or tracks as products.

**Invocation / provenance / `source_context`:** `direct` vs `orchestrated`, `agreed` vs `invented`, language/spawn lock, and when to call `read-sdd-artifact` — [domains/core.md](domains/core.md) § Invocation contexts / Contract provenance / Language / `read-sdd-artifact`.

**Backlog helpers (shared, not slash skills):** folder `core/skills/_shared/backlog-item-types/` — `story-sizing.md`; optional `persona-context.md` (Who/Job/Outcome for **User Stories** only); product-quality norms (`invest-and-story-quality.md`, `anti-task-shatter.md`, `gherkin-budget.md`, `feature-altitude.md`, …). FEATURE table includes a **Product intent** column. Load **one** file at a time. Detail: [Product artifact quality](domains/core.md#product-artifact-quality-backlog-item-types). Selective retrieval, REQ-ID, CHANGE, EVD/STATE, and TRACE living-loop remain gates inside the skills above.

Decision tree: [guides/README.md](guides/README.md).

## Orchestrated Delivery

Default feature path. Detail: [sessions/01-orchestrated-delivery.md](sessions/01-orchestrated-delivery.md).

| Skill | Purpose |
|-------|---------|
| `memory-bank-init` | Create/refresh repo `memory-bank/` (Step 0, and refresh-light after code) |
| `orchestrate-analyze` | Classify, ask, set `needs_*`, specialists, story gates, backlog **sim** |
| `orchestrate-deliver` | PRD + PLAN per story by running `sdd-spec` then `sdd-plan` |
| `orchestrate-develop` | One PLAN step per child by running `sdd-develop` |

Internal contracts (REQ, CHANGE, EVD/STATE, TRACE, validate-*) run inside those invocations. The parent does not write application code.

## Classic SDD contracts

Loaded by deliver and develop. Also a direct start when one story is already clear. Detail: [sessions/02-classic-sdd.md](sessions/02-classic-sdd.md).

| Skill | Purpose |
|-------|---------|
| `sdd-spec` | Create a PRD for a new feature or change |
| `sdd-plan` | Baby-step PLAN from an existing PRD |
| `sdd-develop` | Execute **one** PLAN step per session |
| `read-sdd-artifact` | Normalize FEATURE/STORY/PRD/PLAN under `features/` into `source_context` (reject traversal / outside features) |

Direct example (skill ids; prefix with your host form from [02-using-skills.md](guides/02-using-skills.md)):

```text
sdd-spec
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step N
```

## Backlog shape

O1 applies the scorecard and story gates without this invoke. Standalone when a product person shapes one item, or when deliver stops on open clarification B/I. Detail: [sessions/03-backlog-shape.md](sessions/03-backlog-shape.md).

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

If the invoke omits a mode, the skill asks once and loads **only** the chosen playbook. Mode `split` prepares input for `split-story-checklist`. It does not create a separate delivery path.

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
| `run-tests` | Run detected-stack tests; .NET coverage only when the PLAN asks |
| `commit` | Conventional commit on a valid feature branch |
| `push` | Safe git push after confirmation |
| `open-github-pr` | Create GitHub PR via `gh` (feature or release mode); auto-merge ask; feature **`--squash`**, release **`--rebase`** |
| `ef-add-migration` | EF Core migration discovery |
| `scaffold-message-handler` | Message consumer scaffold |
| `refactor` | Safe incremental refactoring |
| `api-integrate` | Typed API clients / DTOs from OpenAPI |
| `api-standards` | Agnostic HTTP/API design standards (REST, versioning, errors, naming, security hygiene) — packing only; no company contracts |
| `framework-upgrade` | Generic framework upgrade orchestrator (audit\|plan\|migrate\|validate; pluggable packs — not a pinned pack); packs cite `_shared/*-guidelines` + official sources |
| `performance-profile` | Profiling and optimization |
| `containerize` | Dockerfiles and compose |
| `i18n-manager` | Extract strings to localization files |

## Documentation (RAG)

| Skill | Purpose |
|-------|---------|
| `document-plan` | Documentation plan under `docs/documentation-plan/` — Kind **new** / **update** / **refactor**; prefer fewer larger steps |
| `document-implement` | Execute one documentation plan step (update may coalesce existing paths; spawn ≤2 only for large new/refactor) |

## Operator expectations (mirror of OPERATOR.md)

| Area | What you will be asked / options |
|------|----------------------------------|
| Git (`commit` / `push` / `open-github-pr`) | Living-artifacts ask (bank / docs) before commit when present; confirm commit message; confirm push; PR feature vs release; confirm title/body; **always** ask auto-merge; merge method = feature **`--squash`** / release **`--rebase`**. Deep dive: [domains/git-ops.md](domains/git-ops.md) |
| `framework-upgrade` | Mode `audit`\|`plan`\|`migrate`\|`validate`; detect `framework_id`; migrate needs **`sim`** (silence ≠ approval); skill id must not pin a major |
| `code-review` | Choose single vs multi-angle (no silent default); after Changes required, recommended loop asks re-review / bank / docs (**sim**/**pular**) |
| Orchestrated Delivery | Memory-bank Step 0; backlog **sim**; architect ARCH draft → **sim** on greenfield / `needs_domain`; O1 `needs_*` → `ROSTER.md`; Task `model` omit (inherit parent) unless gated + **sim**; O2 clarify **READY** (no open B/I) before Write; orchestrate parents no app code; orchestrator mode [08](guides/08-orchestrator-mode.md) |
| `sdd-develop` | One PLAN step per session; MUST `-File` `Invoke-DevelopSessionGate` + ledger claim when required |
| `refine-story` | Choose mode `feature` \| `tech` \| `split` (no silent default); load one mode playbook; scorecard uses one `backlog-item-types` norm at a time; open B/I → `NEEDS_CLARIFICATION` (not ready-for-PRD) |
| `split-story-checklist` | SMART tasks under parent story — never US-per-file (anti-task-shatter) |
| `api-standards` vs `api-integrate` | Standards / design review → `api-standards`; OpenAPI → typed clients → `api-integrate` |
| `document-plan` / `document-implement` | Asks doc language before writing; Kind **new** ≈ one file/step; Kind **update** coalesces existing paths; not 5–12 tiny baby-steps by default |
| Chat language and optional compression | [guides/session-behavior.md](guides/session-behavior.md) |
| Lazy-load / phased split | `SKILL.md` + one section per step; monolith `reference.md` >150 lines must split — [SKILL-REFERENCE-RETRIEVAL.md](../core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md) |

Installed static notes: `_shared/skills-catalog/OPERATOR.md` via `help-skills`.

## After sync — sanity check

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
```

Live install should contain `skills/help-skills/SKILL.md` and peers under that agent’s root. See [INSTALL.md](INSTALL.md) and [guides/02-using-skills.md](guides/02-using-skills.md).
