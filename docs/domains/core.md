# Domain: Core

Shared, agent-neutral content under `core/`. Adapters publish from here into each InstallRoot; they do not invent parallel skill trees.

## Layout

```text
core/
  skills/     # 38 kebab skills + _shared/ (agent SoT: skills-catalog/CATALOG.md via /help-skills)
  policy/     # Rule / guideline markdown bodies
  router/     # Neutral router (AGENTS.md source)
  sdd/        # Portable SDD contracts
```

## Skills (`core/skills/`)

Each skill is a folder with `SKILL.md` (and optional `reference.md`, assets). Top-level folders:

| Group | Folders |
|-------|---------|
| SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` |
| Orchestration | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `react-native-developer`, `angular-developer`, `vue-developer`, `blazor-developer`, `electron-developer`, `javascript-developer`, `python-developer` |
| Product / design | `blip-plugin-developer`, `impeccable` |
| Ops | `help-skills`, `code-review`, `commit`, `push`, `open-github-pr`, `test-coverage`, `repair-dotnet-build`, `ef-add-migration`, `scaffold-message-handler`, `refactor`, `api-integrate`, `performance-profile`, `containerize`, `i18n-manager`, `refine-story`, `split-story-checklist` — git flow deep dive: [git-ops.md](git-ops.md) |
| Docs | `document-plan`, `document-implement` |
| Shared | `_shared/` (not a slash skill; includes `skills-catalog/CATALOG.md`) |

Public catalog: [SKILLS.md](../SKILLS.md). Agents: `/help-skills` → installed CATALOG (do not load every `SKILL.md`).

### Placeholders

Skill and policy text may contain:

| Placeholder | Meaning at publish |
|-------------|--------------------|
| `{{TOOLKIT_ROOT}}` | Agent toolkit install root (destination-aware; Codex: plugin skills vs InstallRoot `rules/`) |
| `{{SDD_ROOT}}` | SDD state root (sessions, manifest) |
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

Public state file name: **`manifest.json`** (no version suffix in the filename).

Copies also ship inside `core/skills/_shared/sdd-artifacts/` for skill lazy-load.

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

- **Greenfield** / `needs_domain` with no established ARCH style: specialist `architect` (`_shared/agents/prompts/architect.md`, roster in `_shared/agents/ROSTER.md`) proposes a draft → operator answers **sim** → final ARCH is written. Silence is not approval (`needs-confirm` until sim). Spawned from Forma C `orchestrate-analyze` (§7b), not as a slash skill.
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
