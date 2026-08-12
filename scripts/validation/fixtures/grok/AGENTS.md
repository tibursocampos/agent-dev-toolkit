# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer **skill ids** (kebab-case folder names). Host prefixes differ — do **not** assume `/` is universal:

| Host family | Explicit form | Example |
|-------------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/help-skills` |
| Codex / ZCode | `$id` | `$help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "help-skills" })` |

Compat when the host accepts it: `use skill <id>` / natural language. Codex `/hooks` and Grok `/hooks-trust` are trust UI, not skill invoke. Load shared docs on demand.

**Skill map:** Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/skills-catalog/CATALOG.md` (operator nuances: `OPERATOR.md` beside it) or invoke skill `help-skills`. Do not invent skill names.

## Parallel specialists (default)

**This session = parent / orchestrator.** Keep parent lean (goals, gates, paths, receipts, synthesis). Parent does **not** write code, does **not** do heavy analysis, does **not** execute scripts/batches/builds — specialists do that. Prefer specialist subagents **in parallel** when independent for analysis, multi-file edits, script/batch runs, long builds/tests, deep investigation, and non-trivial planning. Do not require the user to restate this each chat.

Always-on policy source: `core/policy/orchestrator-session.md`. After publish, honor the host-native surface (do not assume every host has a Cursor rule file): Cursor `rules/orchestrator-session.md`; Claude/Grok/Codex `rules/orchestrator-session.md`; Copilot `instructions/orchestrator-session.instructions.md`; Antigravity inside GUARDRAILS; OpenCode/ZCode: **this Parallel specialists section IS the always-on** (no rules file — do not open a `rules/` path).

- **Read** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/SPAWN.md` before `CreatePlan` / any plan that cites Task, subagents, or orchestration; before the first spawn vs in-parent decision when work is **not** thin-trivial; and before multi-file analysis / non-trivial planning (spawn specialists; this chat stays parent/orchestrator). Citing Task/orchestration in a plan without that Read = failed checklist. Then honor SPAWN (`subagents` native → spawn; `none` / Task unavailable → fallback **in-parent**, never hard-fail; concurrent caps).
- Child prompts/returns: Caveman-scoped; omit Task `model` by default (`SUBAGENT-MODEL.md`).
- **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay in-parent. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn.
- User-facing chat remains pt-BR per language policy below.

## Language

| Context | Rule |
|---------|------|
| SDD agent artifacts (`features/**` — FEATURE/STORY/PRD/PLAN/CONTINUITY) | Brazilian Portuguese (pt-BR) — `sdd-artifact-language-pt-br.md` |
| Source code, tests, commits, identifiers | English always |
| Project docs (repo documentation folder, README deliverables) | Ask pt-BR or English in skill before writing |
| User-facing chat replies | Brazilian Portuguese (pt-BR) — `user-language-pt-br.md` |

## Formas (workflows)

Three coexisting **Formas**. Classic / Forma C writes land under `features/NNN-slug/` (see `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: skill `help-skills` + CATALOG Formas section.

| Forma | When | Pipeline |
|-------|------|----------|
| **A** Classic SDD | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **B** Backlog prep | Informal item before SDD | `refine-story` → `split-story-checklist` → A or C |
| **C** Orchestrated | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

**Checkpoint:** one `sdd-develop` session = one PLAN step. Forma C Step 0 = Memory Bank Gate (`E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`.

**Enforcement:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/guardrails.md`, `sdd-pipeline-guards.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/SESSION.md`.

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
| Pipeline / modes | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage / manifest | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/SESSION.md` |
| Memory-bank (Forma C) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |

## Agents / spawn (lazy)

Default preference: this session stays parent/orchestrator; specialists for heavy work — see **Parallel specialists (default)** above. Details:

| Topic | Path |
|-------|------|
| Orchestrator session (always-on) | Cursor `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/orchestrator-session.md` (other hosts: rewrite extension, or this Parallel specialists section when `rules=false`) |
| Spawn contract (native vs fallback) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/SPAWN.md` |
| Roster / `needs_*` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/RECEIPT.md` |
| Task `model` param | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/` after sync-agent (source policy under `core/policy/` where applicable). Cursor-oriented `.md` names below; other hosts rewrite the extension or skip this table when `rules=false` (OpenCode/ZCode: honor Parallel specialists — no rules file).

| Rule | Path |
|------|------|
| Guardrails (git, write, gates) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/guardrails.md` |
| Orchestrator session | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/orchestrator-session.md` |
| AI stealth | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/ai-stealth.md` |
| SDD pipeline | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/sdd-pipeline-guards.md` |
| Context management | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/context-management.md` |
| SDD artifact language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/sdd-artifact-language-pt-br.md` |
| User chat language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/rules/user-language-pt-br.md` |
| Branch / commits | `branch-validation.md`, `conventional-commits.md` |
| Caveman Mode | `caveman-mode.md` |

## Skills catalog

Agent SoT: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/skills-catalog/CATALOG.md` (map) + `OPERATOR.md` (operator nuances). Invoke skill `help-skills` to present those static files — do not re-analyze every skill body.

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
