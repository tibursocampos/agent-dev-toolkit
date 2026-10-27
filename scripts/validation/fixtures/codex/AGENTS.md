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

## ORCHESTRATOR CHARTER

1. **Parent orchestrator-only:** this chat does **not** write application code, run builds, execute scripts/batches, or perform heavy multi-file analysis — specialists do that.
2. **Delegate in parallel:** when work is independent, spawn specialist subagents in parallel; pass **minimal handoff** (scoped paths + receipt requirement + role).
3. **Post-change validation:** after file changes, the **child** runs build + tests and reports results; the **parent** synthesizes for the user.

Mode and in-session commands: `core/policy/orchestrator-session.md` + `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (`orchestrator_mode`: `always` default | `adaptive`).

## Parallel specialists (default)

**This session = parent / orchestrator.** Keep parent lean (goals, gates, paths, receipts, synthesis). Parent does **not** write code, does **not** do heavy analysis, does **not** execute scripts/batches/builds — specialists do that. Prefer specialist subagents **in parallel** when independent for analysis, multi-file edits, script/batch runs, long builds/tests, deep investigation, and non-trivial planning. Do not require the user to restate this each chat.

Always-on policy source: `core/policy/orchestrator-session.md`. After publish, honor the host-native surface (do not assume every host has a Cursor rule file): Cursor `rules/orchestrator-session.md`; Claude/Grok/Codex `rules/orchestrator-session.md`; Copilot `instructions/orchestrator-session.instructions.md`; Antigravity inside GUARDRAILS; OpenCode/ZCode: **this Parallel specialists section IS the always-on** (no rules file — do not open a `rules/` path).

**Invocation axes (A ≠ B ≠ C):** Axis **A** = spawn vs in-parent (`SPAWN.md`; thin-trivial in-parent intact). Axis **B** = omit/inherit Task `model` (`SUBAGENT-MODEL.md`). Axis **C** = no alternate slug without gate + explicit approval (`SUBAGENT-MODEL.md`). Do not conflate A with B/C.

- **Read** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` before `CreatePlan` / any plan that cites Task, subagents, or orchestration; before the first spawn vs in-parent decision when work is **not** thin-trivial; and before multi-file analysis / non-trivial planning (spawn specialists; this chat stays parent/orchestrator). Citing Task/orchestration in a plan without that Read = failed checklist. Then honor SPAWN (`subagents` native → spawn; `none` / Task unavailable → fallback **in-parent**, never hard-fail; concurrent caps).
- Child prompts/returns: Caveman-scoped; omit Task `model` by default (`SUBAGENT-MODEL.md`).
- Batch related bounded work in the initial child assignment. A running child may receive same-scope clarification only; after it returns, never follow up, reopen, resume, or reuse it, including for a correction or continuation. Send remaining work to a fresh child with a concise receipt/excerpt and scoped handoff. Host UI retention does not change this parent rule; do not claim process/context termination without host support.
- **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay in-parent. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn.
- User-facing chat and persisted artifacts match the **user chat language**; spawn / child prompts / agent receipts stay **en-US** (`LANGUAGE.md`).


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

## ORCHESTRATOR CHARTER

1. **Parent orchestrator-only:** this chat does **not** write application code, run builds, execute scripts/batches, or perform heavy multi-file analysis — specialists do that.
2. **Delegate in parallel:** when work is independent, spawn specialist subagents in parallel; pass **minimal handoff** (scoped paths + receipt requirement + role).
3. **Post-change validation:** after file changes, the **child** runs build + tests and reports results; the **parent** synthesizes for the user.

Mode and in-session commands: `core/policy/orchestrator-session.md` + `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (`orchestrator_mode`: `always` default | `adaptive`).

## Parallel specialists (default)

**This session = parent / orchestrator.** Keep parent lean (goals, gates, paths, receipts, synthesis). Parent does **not** write code, does **not** do heavy analysis, does **not** execute scripts/batches/builds — specialists do that. Prefer specialist subagents **in parallel** when independent for analysis, multi-file edits, script/batch runs, long builds/tests, deep investigation, and non-trivial planning. Do not require the user to restate this each chat.

Always-on policy source: `core/policy/orchestrator-session.md`. After publish, honor the host-native surface (do not assume every host has a Cursor rule file): Cursor `rules/orchestrator-session.md`; Claude/Grok/Codex `rules/orchestrator-session.md`; Copilot `instructions/orchestrator-session.instructions.md`; Antigravity inside GUARDRAILS; OpenCode/ZCode: **this Parallel specialists section IS the always-on** (no rules file — do not open a `rules/` path).

**Invocation axes (A ≠ B ≠ C):** Axis **A** = spawn vs in-parent (`SPAWN.md`; thin-trivial in-parent intact). Axis **B** = omit/inherit Task `model` (`SUBAGENT-MODEL.md`). Axis **C** = no alternate slug without gate + explicit approval (`SUBAGENT-MODEL.md`). Do not conflate A with B/C.

- **Read** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` before `CreatePlan` / any plan that cites Task, subagents, or orchestration; before the first spawn vs in-parent decision when work is **not** thin-trivial; and before multi-file analysis / non-trivial planning (spawn specialists; this chat stays parent/orchestrator). Citing Task/orchestration in a plan without that Read = failed checklist. Then honor SPAWN (`subagents` native → spawn; `none` / Task unavailable → fallback **in-parent**, never hard-fail; concurrent caps).
- Child prompts/returns: Caveman-scoped; omit Task `model` by default (`SUBAGENT-MODEL.md`).
- Batch related bounded work in the initial child assignment. A running child may receive same-scope clarification only; after it returns, never follow up, reopen, resume, or reuse it, including for a correction or continuation. Send remaining work to a fresh child with a concise receipt/excerpt and scoped handoff. Host UI retention does not change this parent rule; do not claim process/context termination without host support.
- **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay in-parent. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn.
- User-facing chat and persisted artifacts match the **user chat language**; spawn / child prompts / agent receipts stay **en-US** (`LANGUAGE.md`).

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

## ORCHESTRATOR CHARTER

1. **Parent orchestrator-only:** this chat does **not** write application code, run builds, execute scripts/batches, or perform heavy multi-file analysis — specialists do that.
2. **Delegate in parallel:** when work is independent, spawn specialist subagents in parallel; pass **minimal handoff** (scoped paths + receipt requirement + role).
3. **Post-change validation:** after file changes, the **child** runs build + tests and reports results; the **parent** synthesizes for the user.

Mode and in-session commands: `core/policy/orchestrator-session.md` + `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (`orchestrator_mode`: `always` default | `adaptive`).

## Parallel specialists (default)

**This session = parent / orchestrator.** Keep parent lean (goals, gates, paths, receipts, synthesis). Parent does **not** write code, does **not** do heavy analysis, does **not** execute scripts/batches/builds — specialists do that. Prefer specialist subagents **in parallel** when independent for analysis, multi-file edits, script/batch runs, long builds/tests, deep investigation, and non-trivial planning. Do not require the user to restate this each chat.

Always-on policy source: `core/policy/orchestrator-session.md`. After publish, honor the host-native surface (do not assume every host has a Cursor rule file): Cursor `rules/orchestrator-session.md`; Claude/Grok/Codex `rules/orchestrator-session.md`; Copilot `instructions/orchestrator-session.instructions.md`; Antigravity inside GUARDRAILS; OpenCode/ZCode: **this Parallel specialists section IS the always-on** (no rules file — do not open a `rules/` path).

**Invocation axes (A ≠ B ≠ C):** Axis **A** = spawn vs in-parent (`SPAWN.md`; thin-trivial in-parent intact). Axis **B** = omit/inherit Task `model` (`SUBAGENT-MODEL.md`). Axis **C** = no alternate slug without gate + explicit approval (`SUBAGENT-MODEL.md`). Do not conflate A with B/C.

- **Read** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` before `CreatePlan` / any plan that cites Task, subagents, or orchestration; before the first spawn vs in-parent decision when work is **not** thin-trivial; and before multi-file analysis / non-trivial planning (spawn specialists; this chat stays parent/orchestrator). Citing Task/orchestration in a plan without that Read = failed checklist. Then honor SPAWN (`subagents` native → spawn; `none` / Task unavailable → fallback **in-parent**, never hard-fail; concurrent caps).
- Child prompts/returns: Caveman-scoped; omit Task `model` by default (`SUBAGENT-MODEL.md`).
- Batch related bounded work in the initial child assignment. A running child may receive same-scope clarification only; after it returns, never follow up, reopen, resume, or reuse it, including for a correction or continuation. Send remaining work to a fresh child with a concise receipt/excerpt and scoped handoff. Host UI retention does not change this parent rule; do not claim process/context termination without host support.
- **Thin trivial exception:** single-path Q&A or a one-file edit **with no risk of spreading** may stay in-parent. If analysis spans multiple files, OR a one-file change might extend to others, OR any doubt → spawn.
- User-facing chat and persisted artifacts match the **user chat language**; spawn / child prompts / agent receipts stay **en-US** (`LANGUAGE.md`).

 discovery reads InstallRoot/skills (TOOLKIT_ROOT = InstallRoot). Plugin skills under InstallRoot/plugin remain for marketplace packaging (TOOLKIT_ROOT = plugin). Do not resolve skill `_shared` under InstallRoot/rules — rules and guardrails live under InstallRoot/rules only.

## Language
Two surfaces (host-agnostic — `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/LANGUAGE.md`):

| Context | Rule |
|---------|------|
| User chat + persisted artifacts (FEATURE/STORY/PRD/PLAN/ANALYSIS/ARCH/SEC, product `docs/` / README) | **Same as user chat** in this session |
| Internal thinking, spawn / Task child prompts, specialist contexts, receipts for agents | **Always en-US** |
| Identifiers, tests naming, commits | English always |
| Comments / XML docs / narrative docs in source | Mirror touched area or ask on greenfield (`structure-and-quality.md` §2) |

Do not dump a full user-language PLAN/PRD into a child prompt — **paths + excerpt**. Published `sdd-artifact-language-pt-br*` / `user-language-pt-br*` files are install defaults. Honor `LANGUAGE.md` when the chat is not that locale.

## Tracks (workflows)

Three coexisting **tracks**. Classic SDD / Orchestrated Delivery writes land under `features/NNN-slug/` (see `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: skill `help-skills` + CATALOG Tracks section.

| Track | When | Pipeline |
|-------|------|----------|
| **Classic SDD** | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **Backlog Refine** | Informal item before SDD | `refine-story` → `split-story-checklist` → Classic SDD or Orchestrated Delivery |
| **Orchestrated Delivery** | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

### Operator track choice

Tracks are **recommendations**, never prerequisites between each other. The operator may start **Classic SDD** directly from chat, the host plan mode, a host plan scratch file, or manual analysis — **without** running `orchestrate-analyze` first. Do **not** tell the user they must run Orchestrated Delivery before Classic SDD. Suggest `orchestrate-analyze` only when multi-story, brownfield complexity, or specialist folders warrant it.

**Checkpoint:** one `sdd-develop` session = one PLAN step. An unanswered question, including **MINOR**, blocks the next artifact (`open_question`). O1 creates story folders only after the feature is closed. O2 contests the PRD before `sdd-plan`. Scope close is `run-tests`, then `code-review`, then `run-tests` after changes (or record it was unnecessary), then the `security` agent, then `commit`/`push`. Step 0 = Memory Bank Gate (`E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`. Skill ids unchanged. Detail stays in `PIPELINE.md`.

**Enforcement:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`, `sdd-pipeline-guards.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/SESSION.md`.

### Shortcut - small work

| Need | Skill |
|------|--------|
| Skill map / catalog | `help-skills` |
| Stack router / ad-hoc | `developer` |
| Explicit .NET | `dotnet-developer` |
| Explicit Java | `java-developer` |
| Frontend UI design | Create or update `(repo docs — not installed)` → stack `*-developer` |
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
| Pipeline / modes | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage / manifest | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/SESSION.md` |
| Memory-bank (Orchestrated Delivery) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |

## Agents / spawn (lazy)

Default preference: this session stays parent/orchestrator; specialists for heavy work — see **Parallel specialists (default)** above. Details:

| Topic | Path |
|-------|------|
| Orchestrator session (always-on) | Cursor `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/orchestrator-session.md` (other hosts: rewrite extension, or this Parallel specialists section when `rules=false`) |
| Spawn contract (native vs fallback) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` |
| Language surfaces (chat vs spawn) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/LANGUAGE.md` |
| Roster / `needs_*` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/RECEIPT.md` |
| Task `model` param | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/` after sync-agent (source policy under `core/policy/` where applicable). Cursor-oriented `.md` names below; other hosts rewrite the extension or skip this table when `rules=false` (OpenCode/ZCode: honor Parallel specialists — no rules file).

| Rule | Path |
|------|------|
| Guardrails (git, write, gates) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md` |
| Orchestrator session | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/orchestrator-session.md` |
| AI stealth | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/ai-stealth.md` |
| SDD pipeline | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/sdd-pipeline-guards.md` |
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
| Orchestrated Delivery | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack developers | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `react-native-developer`, `angular-developer`, `vue-developer`, `blazor-developer`, `electron-developer`, `javascript-developer`, `python-developer`, `blip-plugin-developer` |
| Ops / quality | `code-review`, `run-tests`, `repair-dotnet-build`, `test-coverage`, `commit`, `push`, `open-github-pr`, `refactor`, `performance-profile`, `containerize`, `i18n-manager`, `api-integrate`, `api-standards` |
| Design / docs / backlog | `document-plan`, `document-implement`, `refine-story`, `split-story-checklist`, `ef-add-migration`, `scaffold-message-handler` |

## Post-sync validation

Neutral host sync (not Cursor-only):

```powershell
.\scripts\sync-agent.ps1 -Agent <agent-id>
.\scripts\validation\validate-all.ps1
```

Or interactive: `.\scripts\toolkit.ps1`
