# Domain: Core

Shared, agent-neutral content under `core/`. Adapters publish from here into each InstallRoot; they do not invent parallel skill trees.

## Layout

```text
core/
  skills/     # 40 kebab skills + _shared/ (agent SoT: skills-catalog/CATALOG.md + OPERATOR.md via help-skills)
  policy/     # Rule / guideline markdown bodies
  router/     # Neutral router (AGENTS.md source)
  sdd/        # Portable SDD contracts
```

## Skills (`core/skills/`)

Each invocable skill is a folder with `SKILL.md` plus optional lazy-load references. Contract: [`SKILL-REFERENCE-RETRIEVAL.md`](../../core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md) (`Assert-SkillLazyLoad.ps1`).

| Layout | Role |
|--------|------|
| `SKILL.md` | Gate + Process; **must** have `## Lazy-load` and `**Never by default:**` |
| `reference.md` | Optional index (≤50 lines when section files exist) |
| `references/*.md` | Section bodies (`reference/` for impeccable) |

**FAIL** if `**Never by default:**` is missing or monolithic `reference.md` **>150** lines without split. Load one section per Process step — do not preload all references.

Top-level folders:

| Group | Folders |
|-------|---------|
| SDD | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` |
| Orchestration | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `react-native-developer`, `angular-developer`, `vue-developer`, `blazor-developer`, `electron-developer`, `javascript-developer`, `python-developer` |
| Product / design | `blip-plugin-developer`, `impeccable` |
| Ops | `help-skills`, `code-review`, `commit`, `push`, `open-github-pr`, `test-coverage`, `repair-dotnet-build`, `ef-add-migration`, `scaffold-message-handler`, `refactor`, `api-integrate`, `api-standards`, `performance-profile`, `containerize`, `i18n-manager`, `refine-story`, `split-story-checklist` — git flow deep dive: [git-ops.md](git-ops.md) |
| Docs | `document-plan`, `document-implement` |
| Shared | `_shared/` (not a slash skill; includes `skills-catalog/CATALOG.md` + `OPERATOR.md`) |

Public catalog: [SKILLS.md](../SKILLS.md). Agents: `help-skills` → installed CATALOG + OPERATOR (do not load every `SKILL.md`).

### Placeholders

Skill and policy text may contain:

| Placeholder | Meaning at publish |
|-------------|--------------------|
| `{{TOOLKIT_ROOT}}` | Agent toolkit install root (destination-aware; Codex: plugin skills vs InstallRoot `rules/`) |
| `{{SDD_ROOT}}` | SDD state root (sessions, prefs, manifest; optional global Classic tree). Runtime: `effective_SDD_ROOT` |
| `{{GUARDRAILS_PATH}}` | Guardrails policy path for the target agent |

`core/` on disk keeps placeholders; adapters resolve them in the destination. Needles that ban IDE home hardcodes live under `scripts/validation/contracts/`.

## Policy (`core/policy/`)

Markdown bodies for rules/guidelines (guardrails, pipeline guards, language prefs, commits, Caveman, etc.). Adapters normalize extensions as needed:

| Agent | Typical publish form |
|-------|----------------------|
| Cursor | `rules/*.mdc` |
| Claude / Grok | `rules/*.md` or `.grok/rules/*.md` |
| Copilot | `instructions/*.instructions.md` |

## Router (`core/router/`)

Source router document (typically `AGENTS.md`). Published as:

| Agent | Destination name |
|-------|------------------|
| Cursor / Codex / OpenCode / ZCode / Grok | `AGENTS.md` |
| Claude | `CLAUDE.md` |
| Copilot | Folded into `copilot-instructions.md` (router publish may be a no-op) |

## SDD contracts (`core/sdd/`)

Portable contracts such as `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`. Source of truth for pipeline text. Runtime state (`<InstallRoot>/sdd/sessions/`, `manifest.json`) is prepared on every sync via `Get-SddRoot -Prepare`.

Public state file name: **`manifest.json`** (no version suffix in the filename). Schema **v2** stores per-cwd Classic settings under `repositories[<cwd>].classic` (`storage_mode`, `path`).

Copies also ship inside `core/skills/_shared/sdd-artifacts/` for skill lazy-load. Full rules: [STORAGE.md](../../core/sdd/STORAGE.md).

### Artifact storage (repository vs global)

Where Classic SDD / Orchestrated Delivery writes land is chosen once per project (first SDD write). Modes share the same co-location rule: `features/` and `memory-bank/` always sit under one storage root — **never** place `memory-bank/` under `features/NNN-slug/`.

| Mode | Feature root | Memory-bank root |
|------|--------------|------------------|
| **repository** | `$Cwd/features/NNN-slug/` | `$Cwd/memory-bank/` |
| **global** | `<classic.path>/features/NNN-slug/` | `<classic.path>/memory-bank/` |

- **repository:** artifacts under the consumer workspace (`features/` + `memory-bank/` at `$Cwd`).
- **global:** `<classic.path>` is under the host SDD root (typically `{{SDD_ROOT}}/<repo-id>/`, or the path stored in the manifest). Outside the consumer git tree; skills do not edit project `.gitignore`.

Manifest keys: `classic.storage_mode` (`repository` \| `global`) and `classic.path`. Runtime resolves the host-aware root as `effective_SDD_ROOT` (`<InstallRoot>/sdd`); docs and publish may still show `{{SDD_ROOT}}`. Sync prepares that root via `Get-SddRoot -Prepare` (seed `manifest.json` only when absent).

No flat `PRD/` / `PLAN/` at repo root or under a global flat tree — only `features/NNN-slug/...`.

### Work tracks and internal contracts

| Track | Call flow |
|-------|-----------|
| **Classic SDD** | `sdd-spec` → `sdd-plan` → `sdd-develop` (+ optional `read-sdd-artifact`) |
| **Backlog Refine** | `refine-story` → `split-story-checklist` |
| **Orchestrated Delivery** | Step 0 → O1 → O2 → O3 \| `sdd-develop` |

Track names only — no Forma aliases. Skill ids stay the same. Shared backlog contracts (not slash skills): `story-sizing.md`; optional `persona-context.md` for User Stories only; FEATURE **Product intent** column (`templates/features/FEATURE.md`). Orchestrator session: `core/policy/orchestrator-session.md` + prefs `orchestrator_mode` — [guides/08-orchestrator-mode.md](../guides/08-orchestrator-mode.md).

Inside those skills, contracts add gates/artifacts:

| Contract | Path / script | Role |
|----------|---------------|------|
| REQ + AC | PRD/PLAN templates | Stable IDs; PLAN covers REQ |
| Structural validate | `validate-prd` / `validate-plan` (+ CHANGE/EVD/TRACE validators) | Deterministic exit codes; not LLM-as-validator |
| CHANGE | `features/NNN-slug/CHANGE.md` | Brownfield delta vs current |
| EVD + STATE | `features/NNN-slug/EVD/`, `STATE.md` | Evidence-or-zero (`off`\|`cheap`\|`standard`\|`strict`) |
| TRACE | `features/NNN-slug/TRACE.jsonl` | Living loop events; archive/sync (see below) |
| PLAN-LEDGER | `PLAN-LEDGER-CONTRACT.md` | Atomic O3 step claim (see below) |
| Selective retrieval | `SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP` | No full memory-bank/PRD dump |
| Skill lazy-load | `SKILL-REFERENCE-RETRIEVAL.md` | Section-only reference load |
| Invocation contexts | `INVOCATION-CONTEXTS.md` | `direct` vs `orchestrated` (see below) |
| Contract provenance | `CONTRACT-PROVENANCE.md` | `agreed` vs `invented` (see below) |

**OOS:** SQLite/FTS as deliverable; second toolkit; folders `openspec/`, `.specs/`, `.specify/`.

### Invocation contexts (`direct` vs `orchestrated`)

Contract: [`INVOCATION-CONTEXTS.md`](../../core/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md) — rule id `IC-DIRECT-ORCHESTRATED`.

| Context | Meaning |
|---------|---------|
| `direct` | Operator invokes the skill in their session (Classic SDD or standalone slash/skill name). |
| `orchestrated` | Skill runs under `orchestrate-*` or as a Task/spawn child with a scoped handoff. |

Do **not** invent a third context. Host IDE mode (Agent/Plan/Ask) is **not** an invocation context.

**Defaults when slash-invoked:** `orchestrate-*` → `orchestrated`; `sdd-spec` / `sdd-plan` / `sdd-develop` / `refine-story` / `memory-bank-init` → `direct` unless a parent handoff marks `orchestrated`.

**Detection (prefer explicit):** handoff/`invocation_context` field → spawn child of orchestrate → any `orchestrate-*` body → else `direct`. Record `invocation_context` on receipts when produced.

| Shared (both) | `direct` | `orchestrated` |
|---------------|----------|----------------|
| Selective retrieval; portable paths; SESSION gates; omit Task `model` by default | Skill owns its confirm-before-write / step gates; no sibling orchestrate stages | Parent owns CONTINUITY / Step 0 bank / multi-step queue; child = one step/story/bank mode; skip opaque re-read when `source_context` is present |

### Contract provenance (`agreed` vs `invented`)

Contract: [`CONTRACT-PROVENANCE.md`](../../core/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md) — rule id `CP-AGREED-VS-INVENTED`.

| Provenance | Meaning |
|------------|---------|
| `agreed` | Operator-confirmed, cited Prior context (FEATURE/STORY/REFINE/bank/sibling notes), or an already accepted artifact. |
| `invented` | Agent fill-in (gap, default, inference) **not** yet accepted. |

Label **per claim** (REQ, CA, assumption, OOS). Ambiguous → `invented`. Never promote `invented` → `agreed` without operator **sim** or an explicit Prior-context cite. Primary author: `sdd-spec`; consumers `sdd-plan` / `sdd-develop` must not re-label invented as agreed Aceite.

### Language surfaces and spawn lock

Contract: [`LANGUAGE.md`](../../core/skills/_shared/agents/LANGUAGE.md) (`CL-CONTENT-LANGUAGE`) with spawn rules in [`SPAWN.md`](../../core/skills/_shared/agents/SPAWN.md).

| Surface | Language |
|---------|----------|
| Operator chat | Session user-chat language (no hard-coded locale) |
| SDD / story artifact prose | **Content-language** — resolve: invocation override → `preferences.json` `artifact_language` → manifest `artifact_language` → else match chat. `null` ≠ “default pt-BR” |
| Spawn / Task prompts, specialist contexts, agent receipts | **Always en-US** — scoped portable paths + short excerpt; never dump full PLAN/PRD/`memory-bank/` |
| Source, tests, commits, identifiers | Always English |

**Spawn lock (model):** omit Task `model` by default (inherit parent). Alternate/premium slug only with [`SUBAGENT-MODEL.md`](../../core/skills/_shared/agents/SUBAGENT-MODEL.md) gate + operator **sim**. Human matrix: [SPAWN.md](../SPAWN.md).

### Skill `read-sdd-artifact` (`source_context`)

Folder: `core/skills/read-sdd-artifact/` — rule id `RSA-SOURCE-CONTEXT`. Catalog row: Classic SDD ([SKILLS.md](../SKILLS.md); CATALOG total **40**).

| Concern | Behavior |
|---------|----------|
| Purpose | Resolve a portable FEATURE/STORY/PRD/PLAN path under `features/` into one `source_context` envelope (kind, path, feature slug, story id when applicable, file name) |
| When to call | Normalize artifact identity for child handoffs / consumers that need a typed read — **not** a substitute for `sdd-spec` / `sdd-plan` / `sdd-develop` |
| Happy path | Full envelope; consumers that already hold `source_context` for that path **skip** opaque re-read (REQ-005 / orchestrated handoff) |
| Fail path | **No** partial envelope — reject reasons include `path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path` |
| Out of scope kinds | CONTINUITY, ANALYSIS, ARCH, SEC, CHANGE, memory-bank (and similar) — unsupported |
| Gates | Read-only; does **not** require `write_confirmed` / new-artifact **sim** |
| Caveman | **NEVER** compress reject reasons or envelope fields |

Do **not** invent product or company names in docs or envelopes — only paths and kinds evidenced under `features/`.

### Composable skills (lazy refs, mode playbooks)

Same skill ids and work tracks — maturity adds **composition inside** skills (section files + optional modes), not new tracks or a second toolkit. Contract: [`SKILL-REFERENCE-RETRIEVAL.md`](../../core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md) (`SR-LAZY-REFERENCE`; `Assert-SkillLazyLoad.ps1`).

#### Phased monolith split

When procedural detail outgrows a thin skill body:

| Layout | Rule |
|--------|------|
| `SKILL.md` | Gates + Process + `## Lazy-load` + `**Never by default:**` |
| `reference.md` | Routing index only (≤50 lines when a split folder exists) |
| `references/*.md` (or `reference/`) | One concern per file — load **one** section per Process step |

**FAIL** if invocable skill lacks Lazy-load / Never-by-default, or if `reference.md` is **>150** lines without a `references/` or `reference/` split. Agents must not glob all section files at skill start. Thin skills may keep a short unsplit `reference.md` (≤150 lines).

#### `refine-story` modes (`feature` / `tech` / `split`)

Folder: `core/skills/refine-story/`. Still the **Backlog Refine** track skill — modes are mandatory playbooks, not slash aliases.

| Mode | Scope | Load only |
|------|-------|-----------|
| `feature` | User Story or Bug | `references/feature.md` + one of `user-story.md` / `bug.md` |
| `tech` | Technical Story (`TSnn`) | `references/tech.md` + `technical-story.md` |
| `split` | Any type — steps ready for checklist | `references/split.md` + one type file; hand off to `split-story-checklist` |

No silent default: if the invoke omits a mode, ask once (pt-BR) before loading any playbook. Do **not** preload the other two mode files. Persistence stays file-based (`features/.../STORY.md` or `docs/backlog/`) — no remote tracker. Human mirror: [SKILLS.md](../SKILLS.md) § Backlog Refine · [guides/02-using-skills.md](../guides/02-using-skills.md).

#### `api-standards` vs `api-integrate`

| Skill | Use when | Out of scope |
|-------|----------|--------------|
| `api-standards` | Agnostic HTTP/API design review (REST shape, versioning, errors/pagination, naming, security hygiene) | Typed clients/DTOs; company/vendor contracts; stack implementation |
| `api-integrate` | OpenAPI (or schema) → typed clients / DTOs | Replacing design-standards review |

`api-standards` optional focus args: `rest` \| `versioning` \| `errors` \| `naming` \| `security` — load only that playbook under `core/skills/api-standards/references/`. After standards agree, hand off to `api-integrate` or a stack `*-developer`. Catalog: [SKILLS.md](../SKILLS.md) § Operational · CATALOG / OPERATOR rows.

### Product artifact quality (`backlog-item-types`)

Shared norms under [`core/skills/_shared/backlog-item-types/`](../../core/skills/_shared/backlog-item-types/README.md) — **not** slash skills. Index: `README.md`. Feature **006** US03 intent: thin FEATURE / US / PRD get challenged before human backlog or PRD Write; same skill call flow. Paraphrase-only PM ideas (no vendor dump) — curated links in [CREDITS.md](../CREDITS.md).

**Selective load:** open **one** type/norm file per need (`SR-NO-FULL-DUMP`). Do **not** glob the whole folder at skill start.

#### Quality bar (core norms)

| Norm file | Bar |
|-----------|-----|
| `invest-and-story-quality.md` | INVEST + Valuable (beneficiary + observable progress for US; verifiable technical outcome for TS/Bug) |
| `anti-task-shatter.md` | No US/TS for verb+file/class/script or layer-only titles; maturity cap ≤**4** US/TS unless FEATURE rationale (RN03) |
| `gherkin-budget.md` | AC ≥ **happy + rule/edge + failure**, each with observable Then |
| `feature-altitude.md` | FEATURE vs US/TS vs refine/PLAN step height |
| `product-evidence-lite.md` | Evidence: **omit > fabricate** (`omitted — none yet` OK) |
| `clarify-depth.md` / `splitting.md` / `ost-lite.md` / `story-sizing.md` | Open-question depth; split/merge; outcome→story→task; sizing |

Item templates (one at a time): `user-story.md`, `technical-story.md`, `bug.md`; optional `persona-context.md` for User Story Who/Job/Outcome only.

#### Skill wiring (when challenged)

| Skill | When norms load | Gate / behavior |
|-------|-----------------|-----------------|
| `orchestrate-analyze` | Synthesis (`references/story-synthesis.md`) | Gates A–C: FEATURE depth (Problem/Goals/Non-goals), promotion anti-task-shatter, cap ≤4; fail → keep `draft`, no human **sim** |
| `refine-story` | Scorecard Step 4 (+ mode playbook) | Product depth band + AC budget; outcome-shaped titles |
| `split-story-checklist` | Before Write when titles task-shaped | Emit **SMART tasks** only — never US-per-file (`anti-task-shatter` RN01) |
| `sdd-spec` | Step 5.5 `references/challenge-vagueness.md` | Product depth on FEATURE/STORY siblings + PRD metrics/MoSCoW/Severity; lazy norms; no how/code |
| `sdd-plan` | Steps 2–4 when titles task-shaped | Anti file-named PLAN steps (`story-sizing` / `anti-task-shatter`) |

#### Field templates (paths only)

| Artifact | Template |
|----------|----------|
| FEATURE | `core/skills/_shared/templates/features/FEATURE.md` |
| STORY | `core/skills/_shared/templates/features/story/STORY.md` |
| PRD / PLAN | `core/skills/_shared/templates/sdd/PRD.md`, `…/PLAN.md` |

#### Maintainer Assert

`scripts/validation/Assert-ProductArtifactQuality.ps1` (check `product-artifact-quality` in `validate-core`) — fixture CTs under `scripts/validation/fixtures/product-artifact-quality/` (CT1 incomplete FEATURE, CT2 task-shaped title, CT3 AC budget OK, CT4 cap without rationale, CT6 honest Evidence omit). Complements O1 gate docs in `story-synthesis.md`; does not invent product names.

Human mirror: [guides/02-using-skills.md](../guides/02-using-skills.md) · [SKILLS.md](../SKILLS.md) § Backlog Refine · [VALIDATION.md](../VALIDATION.md).

### TRACE archive (living loop)

Contract: [`TRACE-ARCHIVE-CONTRACT.md`](../../core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md) — REQ-005 / CA5.

**SoT trail:** append-only JSON Lines at `features/NNN-slug/TRACE.jsonl`. Do **not** invent `.agent-trace/`, a second JSONL, OpenSpec / `.specs/` / `.specify/`, SQLite/FTS, or git-notes as TRACE SoT.

| Phase | Event | Meaning |
|-------|-------|---------|
| converge | `converge` | Decide which CHANGE / PRD deltas become current |
| sync current | `sync_current` | Apply accepted deltas into `memory-bank/` and/or named `docs/` (`targets` required) |
| archive | `archive` | Close the wave (`status` = `archived` or `closed`) |

Archive-complete order is strict: at least one of each living-loop event, non-decreasing timestamps. Optional trail events (`retrieval`, `gate`, `spawn`, `specialist_complete`, informal `step_done`, …) never replace that triad. Optional run metrics (`tokens`, `duration`, nested `spawn`) are normative **when present**. Never log secrets, auth tokens, or PII.

| Script | Role |
|--------|------|
| `scripts/validation/validate-trace.ps1` | Default: missing TRACE → exit 0; present → JSON + required fields. `-RequireArchiveComplete` enforces the triad |
| `scripts/validation/Assert-TraceArchiveContract.ps1` | Structural smoke for the contract |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Feature-scoped harvest summary (operator ops — [cli-scripts](cli-scripts.md)) |

Host emitters (fail-open append) are adapter-owned — honesty matrix in [adapters.md](adapters.md#trace-emitter-honesty) / [`trace-emitter-honesty.md`](../../adapters/_shared/trace-emitter-honesty.md). Do **not** claim emitters the host does not wire.

### PLAN-LEDGER (atomic step claim)

Contract: [`PLAN-LEDGER-CONTRACT.md`](../../core/skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md) — REQ-002 / CA2.

**Purpose:** at most one active holder per PLAN step for O3 / parallel `sdd-develop` children. Does **not** replace SESSION gates (`step_confirmed` / `tests_run`).

Ledger files under the SDD sessions root (same hash rules as `SESSION.md`):

```text
{sessionsRoot}/{repo-hash}/ledger/plan-{plan-hash}-step-{N}.claim.json
{sessionsRoot}/{repo-hash}/ledger/plan-{plan-hash}-step-{N}.audit.jsonl
```

| Action | Behavior |
|--------|----------|
| `claim` | Atomic create-new; second claim fails with auditable reason + audit line |
| `status` | Free / held + holder (exit 0 even when held) |
| `release` | Current holder only |

```powershell
.\scripts\ledger\Invoke-PlanLedgerClaim.ps1 -Action claim -PlanPath <portable-or-abs> -Step N -Holder <id> -RepoPath <cwd> -SessionsRoot <sessions>
.\scripts\validation\Assert-PlanLedgerContract.ps1
```

Wire cites: `sdd-plan` → `references/plan-ledger.md`; O3 children may claim before implement when the parent requires a ledger hold. PLAN bodies stay thin — cite the contract path; do not embed claim JSON.

## Code guidelines and architecture selection

Shared implementation standards live under `core/skills/_shared/code-guidelines/` (not a slash skill). Stack HOW packs (`dotnet-guidelines/`, `javascript-guidelines/`, …) and `frontend-guidelines/` sit beside them under `_shared/`.

### Layers A / B / C

| Layer | Path (under `_shared/`) | Role |
|-------|-------------------------|------|
| **A** Selection | `code-guidelines/principles/architecture-selection.md` | **WHEN** — which style fits; greenfield confirm gate |
| **B** Style | `code-guidelines/principles/architecture/<one-style>.md` | **WHAT** — stack-agnostic rules for one style |
| **C** Overlay | `*-guidelines/…` (+ `frontend-guidelines/frontend-architecture.md` for UI) | **HOW** — thin stack wiring; pointers back to B |

Styles under B (load **one** primary file): `concentric-dependency`, `vertical-slice`, `ddd-tactical` (with concentric), `event-driven` (overlay). See `principles/architecture/README.md`.

### Architect confirm gate

- **Greenfield** / `needs_domain` with no established ARCH style: specialist `architect` (`_shared/agents/prompts/architect.md`, roster in `_shared/agents/ROSTER.md`) proposes a draft → operator answers **sim** → final ARCH is written. Silence is not approval (`needs-confirm` until sim). Spawned from Orchestrated Delivery `orchestrate-analyze` (§7b), not as a slash skill.
- **Brownfield:** discover existing layout / ARCH first and **mirror**; do not re-pick a style unless the operator asks.

### Token discipline

After A resolves a style, load **exactly one** B file (plus optional DDD tactical or EDA only when selected). **Never** glob `architecture/**` or preload the whole principles tree. Implementers (`sdd-develop`, `*-developer`) then load the matching C overlay for the active stack.

Details: [ARCHITECTURE.md](../ARCHITECTURE.md) § Application architecture selection.

## Conscious exceptions

- Brand names (Cursor, Antigravity, …) may appear in stealth / co-author policy text — not as filesystem home paths.
- Project-relative paths documenting third-party tool output (e.g. `.cursor/hooks.json` for CLI tooling) are not user-profile install roots.

## Related

- [overview.md](../overview.md)
- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [domains/adapters.md](adapters.md)
