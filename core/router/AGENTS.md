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

1. **Parent orchestrator-only:** this chat does **not** write application code, run builds, execute scripts/batches, or perform heavy multi-file analysis — specialists do that, except a task that "Modes" lets `adaptive` keep in the parent; the parent never implements an O3 step.
2. **Delegate in parallel:** when work is independent, spawn specialist subagents in parallel; pass **minimal handoff** (scoped paths + receipt requirement + role).
3. **Post-change validation:** after file changes, the **child** runs build + tests and reports results; the **parent** synthesizes for the user (a focused post-edit test of a trivial task may run in the parent in `adaptive`).

Full text, in-session commands, and the preference check: `{{TOOLKIT_ROOT}}/rules/orchestrator-session.mdc` + `{{SDD_ROOT}}/preferences.json` (`orchestrator_mode`).

## Parallel specialists (default)

Parent keeps lean context (goals, gates, scoped paths, receipts, synthesis). Specialists take the heavy passes (analysis, multi-file edits, script and build runs, deep investigation, non-trivial planning), in parallel when independent.

- **Startup is capability-first:** resolve effective `subagents` capability and read `{{SDD_ROOT}}/preferences.json` before any spawn-contract reads. If capability is `none`/unknown, skip spawn/model-choice contracts and questions. If `native`, read `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN-DIGEST.md` and the full `SPAWN.md` before any skill/task work that can delegate; see `orchestrator-session`.
- **Invocation axes (A ≠ B ≠ C):** Axis **A** = spawn vs in-parent; Axis **B** = model/effort inheritance by default; Axis **C** = optional user-chosen pair (rules in `SUBAGENT-MODEL.md`). Normative table: `SPAWN.md` "Invocation axes".
- **Modes (minimal line for hosts without rules):** `always` delegates every task except `qa_checklist` (no Agent); `adaptive` keeps in the parent only a task within 3 edited files / 6 read files / 150 lines with no exclusion (security, shared contract, long command, scope not countable in 2 searches). Full table: `orchestrator-session` "Modes"; checklist: `SPAWN.md`.
- **Child lifecycle:** batch related work; a returned child is idle; continue it only for the same topic and scope (max 2, read-only); children cannot spawn subagents; never claim process or context termination. Full rules: `SPAWN.md`.
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
| Question / gate contract | `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md` |

## Rules (always-on)

Read the rule that matches the topic; do not restate it here. Hosts without a rules tree (OpenCode, ZCode) use the Parallel specialists section above as their always-on copy. Hosts that fold policy into `AGENTS.md` (OpenHands, Hermes) carry it there.

## Skills catalog

Groups and ids: `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` (see Skill map above).
