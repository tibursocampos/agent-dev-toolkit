# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `{{TOOLKIT_ROOT}}/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer **skill ids** (kebab-case folder names). Host prefixes differ — do **not** assume `/` is universal:

| Host family | Explicit form | Example |
|-------------|---------------|---------|
| Cursor / Claude / Copilot / Grok | `/id` | `/help-skills` |
| Codex / ZCode | `$id` | `$help-skills` |
| Antigravity | `use skill id` or `/id` | `use skill sdd-plan` |
| OpenCode | `skill` tool | `skill({ name: "help-skills" })` |

Compat when the host accepts it: `use skill <id>` / natural language. Codex `/hooks` and Grok `/hooks-trust` are trust UI, not skill invoke. Load shared docs on demand.

**Skill map:** Read `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` (operator nuances: `OPERATOR.md` beside it) or invoke skill `help-skills`. Do not invent skill names.

## ORCHESTRATOR CHARTER

1. **Parent orchestrator-only:** this chat does **not** write application code, run builds, execute scripts/batches, or perform heavy multi-file analysis — specialists do that.
2. **Delegate in parallel:** when work is independent, spawn specialist subagents in parallel; pass **minimal handoff** (scoped paths + receipt requirement + role).
3. **Post-change validation:** after file changes, the **child** runs build + tests and reports results; the **parent** synthesizes for the user.

Mode and in-session commands: `core/policy/orchestrator-session.md` + `{{SDD_ROOT}}/preferences.json` (`orchestrator_mode`: `always` default | `adaptive`).

## Parallel specialists (default)

**This session = parent / orchestrator.** Keep parent lean (goals, gates, paths, receipts, synthesis). Parent does **not** write code, does **not** do heavy analysis, does **not** execute scripts/batches/builds — specialists do that. Prefer specialist subagents **in parallel** when independent for analysis, multi-file edits, script/batch runs, long builds/tests, deep investigation, and non-trivial planning. Do not require the user to restate this each chat.

Always-on policy source: `core/policy/orchestrator-session.md`. After publish, honor the host-native surface (do not assume every host has a Cursor rule file): Cursor `rules/orchestrator-session.mdc`; Claude/Grok/Codex `rules/orchestrator-session.md`; Copilot `instructions/orchestrator-session.instructions.md`; Antigravity inside GUARDRAILS; OpenCode/ZCode: **this Parallel specialists section IS the always-on** (no rules file — do not open a `rules/` path).

- **Read** `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` before `CreatePlan` / any plan that cites Task, subagents, or orchestration; before the first spawn vs in-parent decision when work is **not** thin-trivial; and before multi-file analysis / non-trivial planning (spawn specialists; this chat stays parent/orchestrator). Citing Task/orchestration in a plan without that Read = failed checklist. Then honor SPAWN (`subagents` native → spawn; `none` / Task unavailable → fallback **in-parent**, never hard-fail; concurrent caps).
- Child prompts/returns: Caveman-scoped; omit Task `model` by default (`SUBAGENT-MODEL.md`).
- **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay in-parent. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn.
- User-facing chat and persisted artifacts match the **user chat language**; spawn / child prompts / agent receipts stay **en-US** (`LANGUAGE.md`).

## Language

Two surfaces (host-agnostic — `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`):

| Context | Rule |
|---------|------|
| User chat + persisted artifacts (FEATURE/STORY/PRD/PLAN/ANALYSIS/ARCH/SEC, product `docs/` / README) | **Same as user chat** in this session |
| Internal thinking, spawn / Task child prompts, specialist contexts, receipts for agents | **Always en-US** |
| Source code, tests, commits, identifiers | English always |

Do not dump a full user-language PLAN/PRD into a child prompt — **paths + excerpt**. Published rules `sdd-artifact-language-pt-br.mdc` / `user-language-pt-br.mdc` are Cursor defaults; honor `LANGUAGE.md` when chat is not pt-BR.

## Tracks (workflows)

Three coexisting **tracks**. Classic SDD / Orchestrated Delivery writes land under `features/NNN-slug/` (see `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: skill `help-skills` + CATALOG Tracks section.

| Track | When | Pipeline |
|-------|------|----------|
| **Classic SDD** | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **Backlog Refine** | Informal item before SDD | `refine-story` → `split-story-checklist` → Classic SDD or Orchestrated Delivery |
| **Orchestrated Delivery** | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

**Checkpoint:** one `sdd-develop` session = one PLAN step. Orchestrated Delivery Step 0 = Memory Bank Gate (`{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`. Skill ids unchanged.

**Enforcement:** `{{GUARDRAILS_PATH}}`, `sdd-pipeline-guards.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`.

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
| Pipeline / modes | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage / manifest | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md` |
| Memory-bank (Orchestrated Delivery) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |

## Agents / spawn (lazy)

Default preference: this session stays parent/orchestrator; specialists for heavy work — see **Parallel specialists (default)** above. Details:

| Topic | Path |
|-------|------|
| Orchestrator session (always-on) | Cursor `{{TOOLKIT_ROOT}}/rules/orchestrator-session.mdc` (other hosts: rewrite extension, or this Parallel specialists section when `rules=false`) |
| Spawn contract (native vs fallback) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Language surfaces (chat vs spawn) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Roster / `needs_*` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md` |
| Task `model` param | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published under `{{TOOLKIT_ROOT}}/rules/` after sync-agent (source policy under `core/policy/` where applicable). Cursor-oriented `.mdc` names below; other hosts rewrite the extension or skip this table when `rules=false` (OpenCode/ZCode: honor Parallel specialists — no rules file).

| Rule | Path |
|------|------|
| Guardrails (git, write, gates) | `{{GUARDRAILS_PATH}}` |
| Orchestrator session | `{{TOOLKIT_ROOT}}/rules/orchestrator-session.mdc` |
| AI stealth | `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc` |
| SDD pipeline | `{{TOOLKIT_ROOT}}/rules/sdd-pipeline-guards.mdc` |
| Context management | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| SDD artifact language | `{{TOOLKIT_ROOT}}/rules/sdd-artifact-language-pt-br.mdc` |
| User chat language | `{{TOOLKIT_ROOT}}/rules/user-language-pt-br.mdc` |
| Branch / commits | `branch-validation.mdc`, `conventional-commits.mdc` |
| Caveman Mode | `caveman-mode.mdc` |

## Skills catalog

Agent SoT: `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` (map) + `OPERATOR.md` (operator nuances). Invoke skill `help-skills` to present those static files — do not re-analyze every skill body.

| Group | Examples |
|-------|----------|
| Catalog | `help-skills` |
| Classic SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` |
| Orchestrated Delivery | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
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
