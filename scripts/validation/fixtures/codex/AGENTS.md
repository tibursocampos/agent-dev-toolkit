# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer **skill ids** (kebab-case folder names). Host prefixes differ — do **not** assume `/` is universal:

| Host family | Explicit form | Example |
|-------------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/help-skills` |
| Codex / ZCode | `$id` | `$help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "help-skills" })` |

Compat when the host accepts it: `use skill <id>` / natural language. Codex `/hooks` and Grok `/hooks-trust` are trust UI, not skill invoke. Load shared docs on demand.

**Skill map:** Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md` (operator nuances: `OPERATOR.md` beside it) or invoke skill `help-skills`. Do not invent skill names.

## Parallel specialists (default)

For **planning**, **multi-facet execution**, **analysis**, or **non-trivial questions**: prefer specialist subagents **in parallel**; keep **this session as the parent** (synthesize results / receipts). Do not require the user to restate this each chat.

- Honor `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` (`subagents` native vs fallback **in-parent**; concurrent caps).
- **Trivial / single-path** work stays in-parent — do not spawn for noise.
- User-facing chat remains pt-BR per language policy below.


## Codex dual-root paths (installed)

Codex InstallRoot `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex` uses dual roots: home/plugin skills vs InstallRoot rules. Prefer absolute paths below. Invoke toolkit skills with `$<skill-id>` (for example `$help-skills`).

| Surface | Absolute path |
|---------|---------------|
| InstallRoot (product / AGENTS / rules parent) | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex |
| Home skills (`# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer **skill ids** (kebab-case folder names). Host prefixes differ — do **not** assume `/` is universal:

| Host family | Explicit form | Example |
|-------------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/help-skills` |
| Codex / ZCode | `$id` | `$help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "help-skills" })` |

Compat when the host accepts it: `use skill <id>` / natural language. Codex `/hooks` and Grok `/hooks-trust` are trust UI, not skill invoke. Load shared docs on demand.

**Skill map:** Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md` (operator nuances: `OPERATOR.md` beside it) or invoke skill `help-skills`. Do not invent skill names.

## Parallel specialists (default)

For **planning**, **multi-facet execution**, **analysis**, or **non-trivial questions**: prefer specialist subagents **in parallel**; keep **this session as the parent** (synthesize results / receipts). Do not require the user to restate this each chat.

- Honor `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` (`subagents` native vs fallback **in-parent**; concurrent caps).
- **Trivial / single-path** work stays in-parent — do not spawn for noise.
- User-facing chat remains pt-BR per language policy below.

 discovery / InstallRoot/skills) | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills |
| Plugin skills TOOLKIT_ROOT | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin |
| Rules (Publish-Policy) | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules |
| Guardrails | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md |
| Skills catalog | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md |

Codex `# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer **skill ids** (kebab-case folder names). Host prefixes differ — do **not** assume `/` is universal:

| Host family | Explicit form | Example |
|-------------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/help-skills` |
| Codex / ZCode | `$id` | `$help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "help-skills" })` |

Compat when the host accepts it: `use skill <id>` / natural language. Codex `/hooks` and Grok `/hooks-trust` are trust UI, not skill invoke. Load shared docs on demand.

**Skill map:** Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md` (operator nuances: `OPERATOR.md` beside it) or invoke skill `help-skills`. Do not invent skill names.

## Parallel specialists (default)

For **planning**, **multi-facet execution**, **analysis**, or **non-trivial questions**: prefer specialist subagents **in parallel**; keep **this session as the parent** (synthesize results / receipts). Do not require the user to restate this each chat.

- Honor `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` (`subagents` native vs fallback **in-parent**; concurrent caps).
- **Trivial / single-path** work stays in-parent — do not spawn for noise.
- User-facing chat remains pt-BR per language policy below.

 discovery reads InstallRoot/skills (TOOLKIT_ROOT = InstallRoot). Plugin skills under InstallRoot/plugin remain for marketplace packaging (TOOLKIT_ROOT = plugin). Do not resolve skill `_shared` under InstallRoot/rules — rules and guardrails live under InstallRoot/rules only.

## Language
| Context | Rule |
|---------|------|
| SDD agent artifacts (`features/**` — FEATURE/STORY/PRD/PLAN/CONTINUITY) | Brazilian Portuguese (pt-BR) — `sdd-artifact-language-pt-br.md` |
| Source code, tests, commits, identifiers | English always |
| Project docs (repo documentation folder, README deliverables) | Ask pt-BR or English in skill before writing |
| User-facing chat replies | Brazilian Portuguese (pt-BR) — `user-language-pt-br.md` |

## Formas (workflows)

Three coexisting **Formas**. Classic / Forma C writes land under `features/NNN-slug/` (see `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: skill `help-skills` + CATALOG Formas section.

| Forma | When | Pipeline |
|-------|------|----------|
| **A** Classic SDD | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **B** Backlog prep | Informal item before SDD | `refine-story` → `split-story-checklist` → A or C |
| **C** Orchestrated | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

**Checkpoint:** one `sdd-develop` session = one PLAN step. Forma C Step 0 = Memory Bank Gate (`E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`.

**Enforcement:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`, `sdd-pipeline-guards.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/SESSION.md`.

### Shortcut - small work

| Need | Skill |
|------|--------|
| Skill map / catalog | `help-skills` |
| Stack router / ad-hoc | `developer` |
| Explicit .NET | `dotnet-developer` |
| Explicit Java | `java-developer` |
| Frontend UI design | `impeccable` → `DESIGN-BRIEF.md` → stack `*-developer` |
| Blip React plugin | `blip-plugin-developer` → `react-developer` |

### Optional flows (index)

| Flow | Entry skills |
|------|----------------|
| Repo documentation (RAG) | `document-plan` → `document-implement` |
| Build / test | `repair-dotnet-build` → optional `commit` / `push` |
| EF migration | `ef-add-migration` |
| Message consumer | `scaffold-message-handler` |

## SDD contracts (lazy)

| Topic | Path |
|-------|------|
| Pipeline / modes | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage / manifest | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/SESSION.md` |
| Memory-bank (Forma C) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |

## Agents / spawn (lazy)

Default preference: parallel specialists for multi-facet parent turns — see **Parallel specialists (default)** above. Details:

| Topic | Path |
|-------|------|
| Spawn contract (native vs fallback) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` |
| Roster / `needs_*` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/RECEIPT.md` |
| Task `model` param | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/` after sync-agent (source policy under `core/policy/` where applicable).

| Rule | Path |
|------|------|
| Guardrails (git, write, gates) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md` |
| AI stealth | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/ai-stealth.md` |
| SDD pipeline | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/sdd-pipeline-guards.md` |
| Context management | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/context-management.md` |
| SDD artifact language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/sdd-artifact-language-pt-br.md` |
| User chat language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/user-language-pt-br.md` |
| Branch / commits | `branch-validation.md`, `conventional-commits.md` |
| Caveman Mode | `caveman-mode.md` |

## Skills catalog

Agent SoT: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md` (map) + `OPERATOR.md` (operator nuances). Invoke skill `help-skills` to present those static files — do not re-analyze every skill body.

| Group | Examples |
|-------|----------|
| Catalog | `help-skills` |
| Classic SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` |
| Forma C | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack developers | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `react-native-developer`, `angular-developer`, `vue-developer`, `blazor-developer`, `electron-developer`, `javascript-developer`, `python-developer`, `blip-plugin-developer` |
| Ops / quality | `code-review`, `repair-dotnet-build`, `test-coverage`, `commit`, `push`, `open-github-pr`, `refactor`, `performance-profile`, `containerize`, `i18n-manager`, `api-integrate` |
| Design / docs / backlog | `impeccable`, `document-plan`, `document-implement`, `refine-story`, `split-story-checklist`, `ef-add-migration`, `scaffold-message-handler` |

## Post-sync validation

Neutral host sync (not Cursor-only):

```powershell
.\scripts\sync-agent.ps1 -Agent <agent-id>
.\scripts\validation\validate-all.ps1
```

Or interactive: `.\scripts\toolkit.ps1`
