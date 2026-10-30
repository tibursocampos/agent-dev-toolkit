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

Full text, in-session commands, and the preference check: `{{TOOLKIT_ROOT}}/rules/orchestrator-session.mdc` + `{{SDD_ROOT}}/preferences.json` (`orchestrator_mode`).

## Parallel specialists (default)

Parent keeps lean context (goals, gates, scoped paths, receipts, synthesis). Specialists take the heavy passes (analysis, multi-file edits, script and build runs, deep investigation, non-trivial planning), in parallel when independent. This section is the always-on copy for hosts without a rules tree; `orchestrator-session` is the source.

- **Read** `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` before drafting any plan that cites Agent, subagents, or orchestration, and before the first spawn-or-in-parent decision on non-trivial work.
- **Invocation axes (A ≠ B ≠ C):** Axis **A** = spawn vs in-parent (`SPAWN.md`; thin-trivial in-parent intact). Axis **B** = omit/inherit Agent `model` (`SUBAGENT-MODEL.md`). Axis **C** = no alternate slug without gate + explicit approval (`SUBAGENT-MODEL.md`). Do not conflate A with B/C.
- **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay in-parent. If analysis spans multiple files, a one-file change might extend to others, or there is any doubt → spawn.
- **Child lifecycle:** batch related bounded work into one child assignment. A returned child is idle; continue it only for the same topic and scope. Children cannot spawn subagents. Do not claim process or context termination without host support. Full rules: `orchestrator-session` § Child invocation lifecycle.
- **Child prompts and returns:** Caveman-scoped; omit Agent `model` by default (`SUBAGENT-MODEL.md`). Honor SPAWN (`subagents` native → spawn; `none` or Agent unavailable → fallback in-parent, never hard-fail; concurrent caps).

## Language

Language surfaces (chat, persisted artifacts, spawn prompts and receipts) are defined once in `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`. Identifiers, test names, and commit messages are English.

## Tracks (workflows)

Three coexisting **tracks**. Classic SDD / Orchestrated Delivery writes land under `features/NNN-slug/` (see `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: skill `help-skills` + CATALOG Tracks section.

| Track | When | Pipeline |
|-------|------|----------|
| **Classic SDD** | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **Backlog Refine** | Informal item before SDD | `refine-story` → `split-story-checklist` → Classic SDD or Orchestrated Delivery |
| **Orchestrated Delivery** | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

### Operator track choice

Tracks are **recommendations**, never prerequisites between each other. Classic SDD may start from chat, the host's planning mode, a host plan file, or manual analysis, without `orchestrate-analyze` first. Do **not** tell the user they must run Orchestrated Delivery before Classic SDD. Suggest `orchestrate-analyze` only when multi-story, brownfield complexity, or specialist folders warrant it. Detail: `sdd-pipeline-guards`.

**Checkpoint:** one `sdd-develop` session = one PLAN step. An unanswered question, including **MINOR**, blocks the next artifact (`open_question`). O1 creates story folders only after the feature is closed. O2 contests the PRD before `sdd-plan`. Scope close is `run-tests`, then `code-review`, then `run-tests` after changes (or record it was unnecessary), then the `security` agent, then `commit`/`push`. Step 0 = Memory Bank Gate (`{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`. Skill ids unchanged. Detail stays in `PIPELINE.md`.

**Enforcement:** `{{GUARDRAILS_PATH}}`, `sdd-pipeline-guards.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`.

### Shortcut - small work

| Need | Skill |
|------|--------|
| Skill map / catalog | `help-skills` |
| Stack router / ad-hoc | `developer` |
| Explicit .NET | `dotnet-developer` |
| Explicit Java | `java-developer` |
| Frontend UI design | Create or update `docs/DESIGN-BRIEF.md` → stack `*-developer` |
| Blip React plugin | `blip-plugin-developer` → `react-developer` |

### Optional flows (index)

| Flow | Entry skills |
|------|----------------|
| Repo documentation (RAG) | `document-plan` → `document-implement` |
| Build / test | `run-tests`; .NET repair `repair-dotnet-build`; coverage `test-coverage` when the PLAN asks |
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

| Topic | Path |
|-------|------|
| Spawn contract (native vs fallback) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Roster / `needs_*` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md` |
| Agent `model` param | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published per host from the policy source by sync-agent. Read the rule that matches the topic; do not restate it here. Hosts without a rules tree (OpenCode, ZCode) use the Parallel specialists section above as their always-on copy. Hosts that fold policy into `AGENTS.md` (OpenHands, Hermes) carry it there.

## Skills catalog

Groups and ids: `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` (see Skill map above).
