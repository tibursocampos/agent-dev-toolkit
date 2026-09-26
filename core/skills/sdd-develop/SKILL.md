---
name: sdd-develop
description: Execute one PLAN baby step (identifiers English; comments/docs mirror or ask; PLAN in file language per LANGUAGE.md). One session = one step. Use when implementing a PLAN step or invoking /sdd-develop.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load **repo** session for `$Cwd`, then after PLAN path is known load **develop** session scoped by PLAN (or PLAN+step) - see `SESSION.md`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** that develop scope - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; repo + develop (PLAN-scoped) session loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

### Canonical scripts after sim (REQ-012 / CA4 / CT6)

After the user says **sim** for this step, **MUST** persist develop `step_confirmed` via `-File` (cwd = repo root) — **MUST NOT** paste inline PowerShell that mutates session JSON under `sessions/`:

```powershell
pwsh -NoProfile -File .\scripts\session\Invoke-DevelopSessionGate.ps1 -PlanPath <plan> -RepoPath . -SddRoot <sdd-root> [-Step N]
```

When a PLAN ledger claim is required (O3 / declared execution mode / parent handoff), **MUST** also call:

```powershell
pwsh -NoProfile -File .\scripts\ledger\Invoke-PlanLedgerClaim.ps1 -Action claim -PlanPath <plan> -Step N -Holder <holder> -RepoPath . -SddRoot <sdd-root>
```

Prefer **one** Shell approve that chains both `-File` invocations when the host allows. **CT6:** if the session helper skips rewrite because `step_confirmed` is already true, still run the claim when the claim file is absent — session skip does **not** waive claim.

---

# Skill: sdd-develop

## Trigger

Invoke when the user asks for: `/sdd-develop`, `implement step`, `execute step`.

## Outcome

One **PLAN step** done: **identifiers in English**; comments/docs **mirror** touched area or **ask** on greenfield; PLAN updated in place. Honor **Execution policy** in the PLAN (orchestrator mode, child build+tests, receipt/handoff). Do not start the next step in the same develop session scope.

**Session scoping:** After the PLAN path is resolved, load/create the develop session file per `SESSION.md` (`sessions/{repo-hash}/plan-{plan-hash}.json`). When spawned as an O3 parallel child on the same PLAN, use `plan-{plan-hash}-step-{N}.json`. Gates `step_confirmed` / `tests_run` apply only to that scoped file - never share one flat repo JSON across parallel children. Repo session still owns `storage_confirmed` / `write_confirmed`.

## Language

| Deliverable | Language |
|-------------|----------|
| Identifiers (types, members, params, files) | **English** |
| Comments / XML docs / narrative docs | **Mirror** touched area (pt-BR↔pt-BR, EN↔EN); **ask** on greenfield / no clear mirror (user override wins) — `structure-and-quality.md` §2 |
| Tests (identifiers + assertions naming) | Identifiers **English**; narrative comments mirror/ask as above |
| PLAN progress / notes | **Same as PLAN file** |
| Product `docs/` / README | Ask pt-BR vs English first |

Do not re-ask SDD storage or change artifact language mid-PLAN unless requested.

## Required input

| Input | Rule |
|-------|------|
| PLAN path | Canonical only: `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`; global under `{{SDD_ROOT}}/<repo-id>/features/...`). Root/flat `PLAN/` is **not** valid - do not read/update for execution |
| Step | `Step 1`, `PASSO 1`, etc. |

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/command.md` |
| Pipeline, missing PLAN dialog | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Invocation contexts (`direct` vs `orchestrated`, `IC-DIRECT-ORCHESTRATED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Contract provenance (`agreed` vs `invented`, `CP-AGREED-VS-INVENTED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/<section>.md` |
| plan-acquisition (REQ-008 / CA3) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/plan-acquisition.md` |
| Develop modes `continuous` \| `step_by_step` (007 REQ-009) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/develop-modes.md` |
| Execution display (before edit and at the report) | `references/execution-display.md` |
| plan-contract + delivery-baseline (REQ-010) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/plan-contract.md` |
| EVD / STATE / evidence-or-zero (`EVD-STATE-CONTRACT`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md` |
| TRACE / archive / sync current (`TRACE-ARCHIVE-CONTRACT`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md` |
| Branch / commits | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Developer-common (on trigger) | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/GUIDE.md` — then individual `step-*.md` only when that step runs |
| Structure / quality (when coding) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| .NET guidelines (on trigger) | **one** file under `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/` matching the PLAN step — never glob `*.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Language surfaces (chat vs spawn) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |

**Never by default:** do not preload `references/command.md` before Step -1 gates; do not preload all `dotnet-guidelines/*.md`, the full developer-common pack, or all `references/*.md`. Contract first (`PIPELINE` + `STORAGE`); after gates load `references/command.md` for step discovery; then fan-out on trigger — **one** `references/<section>.md` per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Command playbook (step discovery) | `references/command.md` |
| plan-acquisition (canonical PLAN) | `references/plan-acquisition.md` |
| Develop modes `continuous` \| `step_by_step` | `references/develop-modes.md` |
| plan-contract markers + delivery-baseline | `references/plan-contract.md` |
| PLAN update protocol | `references/plan-update.md` |
| Git preparation | `references/git-checklist.md` |
| Pre-implementation analysis | `references/code-analysis.md` |
| Stack pointers | `references/stack-pointers.md` |
| Session report / checkpoint | `references/session-report.md` |
| Evidence-or-zero | `references/evidence-or-zero.md` |
| Living loop + TRACE | `references/living-loop-trace.md` |
| Quality self-check | `references/quality-self-check.md` |
| Optional flows | `references/optional-flows.md` |
| Forbidden | `references/forbidden.md` |
## Process

After gates: **Read `references/command.md`** for ordered step discovery (prefer over dumping this Process into prompts). Then load `references/<section>.md` for the current step only.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full", "orchestrator_mode": "always", "artifact_language": null }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Pipeline and mode

Load `STORAGE.md` and `PIPELINE.md`. Use `STORAGE.md` schema v2 and run the dynamic storage resolution algorithm with parameter `$Workflow = classic`. Resolve `storage_mode` and `path` for the active repository. If this is the first run for the repository, execute storage mode selection and persist it in `manifest.json`.
Resolve `invocation_context` per `INVOCATION-CONTEXTS.md` (`IC-DIRECT-ORCHESTRATED`): default `direct` unless O3/parent handoff marks `orchestrated`. Apply the matching observable table (orchestrated child = one PLAN step; no parent CONTINUITY ownership).
Honor `CONTRACT-PROVENANCE.md` (`CP-AGREED-VS-INVENTED`): implement Aceite / cited REQs as `agreed`; new mid-step gaps stay `invented` until operator confirm — do not silently encode them as requirements.
**Agent mode** is required for code changes and PLAN updates. If the user asks for PRD (`sdd-spec`) or PLAN (`sdd-plan`), route using `PIPELINE.md` section Missing artifacts; do not create PRD/PLAN in this skill.

### 0. Workspace (plan-acquisition)

Load `references/execution-display.md` before any code edit and show its checkpoint. Target repo. Run **`plan-acquisition`** (`references/plan-acquisition.md`) before any code mutation:

| Situation | Action |
|-----------|--------|
| Canonical PLAN path given (`features/.../PLAN/` or global `.../features/.../PLAN/`) | `Read` at exact path; update **that** file in place |
| Root/flat `PLAN/` or other non-canonical path | **STOP** - ask user to migrate under `features/.../PLAN/` via `sdd-plan`; do not execute |
| No canonical PLAN path | Glob `features/**/PLAN/PLAN_*.md` only (workspace + global feature root); if not found, use `PIPELINE.md` section `sdd-develop` without PLAN (options 1-3) |
| Path under `features/NNN-slug/` | Optionally load `CONTINUITY.md` / story `STORY.md` and `ANALYSIS/` / `ARCH/` / `SEC/` when present for Prior context only - **do not** change multi-step rules |
| User asks "criar PRD/sdd-plan" | Redirect to `sdd-spec` / `sdd-plan`; stop |

Resolve develop pacing mode `continuous` \| `step_by_step` (`references/develop-modes.md`; default `step_by_step`). Detect stack from PLAN step.

After PLAN path is known: create `{sessions}/{repo-hash}/` if needed; load or create develop session with gates `false` (`SESSION.md` § Develop session - never copy develop gates from the flat repo JSON). If this child was given an explicit step-scoped path (O3 parallel same PLAN), use `plan-{plan-hash}-step-{N}.json`.

### 1. Validate step

Step exists; deps **Concluidos** / **Completed**; summarize objective, files, tests, and **REQ-NNN / CA** targets from step **Aceite** (markers in `references/plan-contract.md`); ask to proceed.

### 2. Git

Feature branch per `branch-validation.mdc`. Read `references/git-checklist.md`.

### 3-4. Analyze and implement

Glob/Grep/Read scope. Read `references/code-analysis.md` and `references/stack-pointers.md`.  Code/tests in English; targeted build/test. When spawned as a child, end with `{ build, tests, summary }` per PLAN **Execution policy** and `SPAWN.md`.

### 4b. Evidence-or-zero (REQ-005 / CA4)

Read `references/evidence-or-zero.md`. When the step claims AC coverage (or CONTINUITY / operator sets a level ≥ `cheap`):

1. Create/update `features/NNN-slug/EVD/` and `features/NNN-slug/STATE.md` from `templates/features/` (`EVD-STATE-CONTRACT.md`; detail: `references/evidence-or-zero.md`).
2. Fill the **AC → evidence matrix**; levels: `off` \| `cheap` \| `standard` \| `strict` (default verify = **`cheap`**).
3. Run structural gate (deterministic — never LLM-as-validator):

```powershell
.\scripts\validation\validate-evidence.ps1 -FeatureRoot <features/NNN-slug> [-Level cheap]
```

Exit ≠ 0 → **STOP**; do not mark the PLAN step Completed (TE02).

**Verifier ≠ O3:** evidence verification runs **sequentially** in this develop session via `validate-evidence`. Do **not** use O3 / Task parallelism as the verifier mechanism.

### 4c. Living loop + TRACE (REQ-006 / CA5)

Read `references/living-loop-trace.md`. When CONTINUITY / operator closes the feature wave (or the PLAN’s last implement step before P-DOC / archive):

1. Append events to `features/NNN-slug/TRACE.jsonl` (template: `templates/features/TRACE.jsonl`; contract: `TRACE-ARCHIVE-CONTRACT.md`).
2. Run **converge → sync current → archive**: selective updates to living docs (`memory-bank/` / named `docs/`); do **not** dump full bank/PRD (`SR-NO-FULL-DUMP`).
3. Ensure TRACE includes ordered living-loop events `converge`, `sync_current`, `archive`.
4. Run structural gate (deterministic — never LLM-as-validator):

```powershell
.\scripts\validation\validate-trace.ps1 -FeatureRoot <features/NNN-slug> -RequireArchiveComplete
```

Exit ≠ 0 → **STOP**; do not declare archive done. During mid-feature steps, optional trail events may be appended; missing TRACE is OK until archive-complete.

**Verifier ≠ O3:** archive/TRACE validation is sequential in this session — do not use Task/O3 parallelism as the archive gate.

### 5. Commit (optional)

Offer `/commit`; do not auto-commit. When the PLAN is **fully done** and the user leans commit, first run the **sim/pular** asks for memory-bank + project docs when those trees exist (`references/optional-flows.md`) — wait for answers; never skip the ask on silence.

### 6. Update PLAN + checkpoint
Load `references/plan-contract.md` and `references/plan-update.md`. Mark `IN_PROGRESS` and re-read before the edit. `COMPLETED` only with this step's acceptance and tests. No duration.

`references/plan-update.md` + **delivery-baseline** (`references/plan-contract.md`): mark step done, progress, next step. Check **Aceite** items only when the step's cited **REQ-NNN** / CA are verifiably met. **No** duration/effort estimates. Save before context pause (>=40%). **Navigation (`## Related` / 006 REQ-009):** do **not** strip or rename `## Related` on PLAN (or PRD if touched); when both PRD and PLAN exist, keep/refresh mutual portable-path cites; omit-if-absent for other siblings (`STORAGE.md` § Navigation block). Do **not** confuse with develop pacing **007 REQ-009** (`continuous` \| `step_by_step`).

### 7. Report
Load `references/execution-display.md` and `references/session-report.md`. Emit `STEP_COMPLETED` or `STEP_BLOCKED`. Phrases follow the user chat language.

## Must not

Also enforce `references/forbidden.md`. Before marking Completed: `references/quality-self-check.md`. Optional user flows: `references/optional-flows.md`.

- Break C# method signatures/invocations for style when ≤6 parameters and the full line is ≤160 characters (`csharp-patterns.md`) — multiline only when **more than 6** parameters **or** line **> 160**; do not let CSharpier leave a style-only wrap that still fits the inline MUST
- Portuguese application code; **multiple PLAN steps per develop session scope** (contract unchanged — including when develop mode is `continuous`)
- Skip `plan-acquisition` or mark Complete without **delivery-baseline** (`references/plan-contract.md`); add duration/effort estimates to checkpoints (REQ-010)
- Do not ignore `IC-DIRECT-ORCHESTRATED` — resolve and apply `direct` vs `orchestrated` (`INVOCATION-CONTEXTS.md`)
- Do not ignore `CP-AGREED-VS-INVENTED` — do not encode mid-step invented gaps as agreed requirements (`CONTRACT-PROVENANCE.md`)
- Create PRD/PLAN; skip PLAN save; modify `.gitignore`
- Implement in Plan/Ask without Agent
- Bypass one-step via orchestrator parent implementing code
- Use the flat `{repo-hash}.json` for `step_confirmed` / `tests_run` when a PLAN path is known - always use the PLAN-scoped file (or PLAN+step); create scoped with gates false if missing
- Inline-mutate develop session JSON (`ConvertFrom-Json` / `ConvertTo-Json` / `Set-Content` gate blobs) instead of `scripts/session/Invoke-DevelopSessionGate.ps1` via `-File` (REQ-012)
- Skip `scripts/ledger/Invoke-PlanLedgerClaim.ps1` when claim is required and absent because session helper already exited 0 (CT6)
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Mark a step Completed at evidence level ≥ `cheap` when `validate-evidence` fails or EVD/STATE are missing
- Use O3 / Task parallelism as the evidence verifier (Verifier ≠ O3)
- Declare archive done when `validate-trace -RequireArchiveComplete` fails or living-loop events are missing
- Use OpenSpec / `.specs/` / SQLite as TRACE or living-spec SoT
- Strip / rename `## Related` on PLAN (or PRD if touched), break PRD↔PLAN mutual cite when both exist, or stub absent siblings only for links (`STORAGE.md` § Navigation block / 006 REQ-009)

## Handoff

| Situation | Next |
|-----------|------|
| Next step | New session -> `/sdd-develop - <portable-plan-path> - Step N+1` |
| All steps done | Ask **code-review** vs **commit** (`references/optional-flows.md`); before commit → bank + docs **sim/pular** when present |
| Commit (after living-artifact asks) | `/commit` |
| Review | `/code-review` (pass `- single` / `- multi-angle`, or let skill ask) |

Example portable path (Classic SDD, repository):

```
/sdd-develop - features/004-export-profile/US01/PLAN/PLAN_004_export_profile.md - Step 2
```

(Global: prefix with `sdd/<repo-id>/`.)
