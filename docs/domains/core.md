# Domain: Core

Shared, agent-neutral content under `core/`. Adapters publish from here into each InstallRoot; they do not invent parallel skill trees.

## Layout

```text
core/
  skills/     # 38 kebab skills + _shared/ (agent SoT: skills-catalog/CATALOG.md + OPERATOR.md via help-skills)
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
| SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` |
| Orchestration | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `react-native-developer`, `angular-developer`, `vue-developer`, `blazor-developer`, `electron-developer`, `javascript-developer`, `python-developer` |
| Product / design | `blip-plugin-developer`, `impeccable` |
| Ops | `help-skills`, `code-review`, `commit`, `push`, `open-github-pr`, `test-coverage`, `repair-dotnet-build`, `ef-add-migration`, `scaffold-message-handler`, `refactor`, `api-integrate`, `performance-profile`, `containerize`, `i18n-manager`, `refine-story`, `split-story-checklist` — git flow deep dive: [git-ops.md](git-ops.md) |
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
| **Classic SDD** | `sdd-spec` → `sdd-plan` → `sdd-develop` |
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
| TRACE | `features/NNN-slug/TRACE.jsonl` | Living loop events; archive/sync |
| Selective retrieval | `SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP` | No full memory-bank/PRD dump |
| Skill lazy-load | `SKILL-REFERENCE-RETRIEVAL.md` | Section-only reference load |

**OOS:** SQLite/FTS as deliverable; second toolkit; folders `openspec/`, `.specs/`, `.specify/`.

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
