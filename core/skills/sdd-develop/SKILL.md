---
name: sdd-develop
description: Execute one PLAN baby step (identifiers English; comments/docs mirror or ask; PLAN in file language per LANGUAGE.md). One session = one step. Use when implementing a PLAN step or invoking /sdd-develop.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

### Canonical scripts after sim (REQ-012 / CA4 / CT6)

Before any session or ledger write, read `references/canonical-scripts.md` and run the exact commands listed there.

---

# Skill: sdd-develop

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user asks for: `/sdd-develop`, `implement step`, `execute step`.

## Outcome

One **PLAN step** done: **identifiers in English**; comments/docs **mirror** touched area or **ask** on greenfield; PLAN updated in place. Honor **Execution policy** in the PLAN (orchestrator mode, conditional tests/build, receipt/handoff). Do not start the next step in the same develop session scope.

### Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`:

- `done`: acceptance and required targeted validation passed; save and re-read the PLAN checkpoint, then report the exact next eligible step.
- `blocked`: a dependency, gate, or unanswered decision is missing; record the cause, keep dependents pending, and state what input or change resolves it.
- `failed`: implementation or validation failed; record evidence and bounded recovery, without retrying the same transition automatically.
- `open_question`: ask the user once and wait; silence leaves the step blocked. Re-entry requires new input or changed evidence and fresh gate validation.

**Session scoping:** After the PLAN path is resolved, load/create the develop session file per `SESSION.md` (`sessions/{repo-hash}/plan-{plan-hash}.json`). When spawned as an O3 parallel child on the same PLAN, use `plan-{plan-hash}-step-{N}.json`. Gates `step_confirmed` / `tests_run` apply only to that scoped file - never share one flat repo JSON across parallel children. Repo session still owns `storage_confirmed` / `write_confirmed`.

## Flow contract: reads, writes, where, when

- **Reads:** one PLAN step from `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md`.
- **Writes:** the code and tests for that step, and the step status in the PLAN.
- **Where:** the repository source and tests, plus the PLAN file. One PLAN step per session; then stop.
- **When to use:** implement one PLAN step. Gates: `sim` / `ajustar` / `cancelar`. Flow choice: [flow selection guide](../../../docs/guides/flow-selection.md).

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
| Step | `Step 1`, `PASSO 1`, etc. An explicit PLAN + step invokes that step in the current session after gates pass; do not demand a new session. |

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/command.md` |
| Pipeline, missing PLAN dialog | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Dynamic manifest / repository-global root resolution (only when resolving storage) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE-RESOLUTION.md` |
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
| Language surfaces (chat vs spawn) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |

**Never by default:** do not preload `references/command.md` before Step -1 gates; do not preload all `dotnet-guidelines/*.md`, the full developer-common pack, or all `references/*.md`. Contract first (`PIPELINE` + `STORAGE`); after gates load `references/command.md` for step discovery; then fan-out on trigger — **one** `references/<section>.md` per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

Routing table for the `references/` sections: `reference.md`.

## Process

After gates: **Read `references/command.md`** for ordered step discovery (prefer over dumping this Process into prompts). Then load `references/<section>.md` for the current step only.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full", "orchestrator_mode": "adaptive", "artifact_language": null }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Pipeline and mode

Load `STORAGE.md` and `PIPELINE.md`; when resolving repository/global storage, also load `STORAGE-RESOLUTION.md`. Use its schema v2 and dynamic storage resolution algorithm with parameter `$Workflow = classic`. Resolve `storage_mode` and `path` for the active repository. If this is the first run for the repository, execute storage mode selection and persist it in `manifest.json`.
Resolve `invocation_context` once per `INVOCATION-CONTEXTS.md` (`IC-DIRECT-ORCHESTRATED`): default `direct`; use `orchestrated` only when the current invocation explicitly selects it or the active skill/parent handoff identifies an `orchestrate-*` stage. Generic parent coordination, `orchestrator_mode=always`, or an O3-targeted PLAN does not change a Classic/direct invocation. If explicit invocation/handoff context declarations conflict, stop with `invocation_context_conflict`. In Classic/direct, do not require or create `CONTINUITY.md`; use it only as optional prior context when present. In orchestrated execution, preserve the parent's CONTINUITY ownership and the child's one-PLAN-step scope; do not take on parent ownership.
Honor `CONTRACT-PROVENANCE.md` (`CP-AGREED-VS-INVENTED`): implement Aceite / cited REQs as `agreed`; new mid-step gaps stay `invented` until operator confirm — do not silently encode them as requirements.
An **edit mode** is required for code changes and PLAN updates. If the host is in a read-only mode (plan or ask) and this step requires an edit, pause and explicitly ask the operator to switch to an edit mode; do not attempt the edit or silently change mode. If the user asks for PRD (`sdd-spec`) or PLAN (`sdd-plan`), route using `PIPELINE.md` section Missing artifacts; do not create PRD/PLAN in this skill.

### 0. Workspace (plan-acquisition)

Load `references/execution-display.md` before any code edit and show its checkpoint. Target repo. Run **`plan-acquisition`** (`references/plan-acquisition.md`) before any code mutation:

| Situation | Action |
|-----------|--------|
| Canonical PLAN path given (`features/.../PLAN/` or global `.../features/.../PLAN/`) | Read the active step block only. In `direct`, the approved PLAN step, its REQ/CA acceptance, dependencies, and declared validation are the execution unit; do not read, require, or create `REFINE/tasks.md`. Use task rows only when the direct invocation explicitly adopts a checklist and its relationship to the PLAN is explicit. In `orchestrated`, use only the checklist path and scoped rows provided by the O3 parent; missing or inconsistent required task rows block/return to O2. Do not load the rest of the PRD. Update the PLAN and only applicable checklist rows in place |
| Root/flat `PLAN/` or other non-canonical path | **STOP** - ask user to migrate under `features/.../PLAN/` via `sdd-plan`; do not execute |
| No canonical PLAN path | Glob `features/**/PLAN/PLAN_*.md` only (workspace + global feature root); if not found, use `PIPELINE.md` section `sdd-develop` without PLAN (options 1-3) |
| Path under `features/NNN-slug/` | Optionally load `CONTINUITY.md` / story `STORY.md` and `ANALYSIS/` / `ARCH/` / `SEC/` when present for Prior context only - **do not** change multi-step rules |
| User asks "criar PRD/sdd-plan" | Redirect to `sdd-spec` / `sdd-plan`; stop |

Resolve `invocation_context` once from the explicit current invocation/handoff; `orchestrator_mode` and sibling artifacts do not select or change it. In `direct`, a canonical approved PLAN plus explicit step proceeds after its direct gates; absence of a checklist is not a blocker and the direct path must not fall through to O3 requirements. In `orchestrated`, preserve the parent's scoped inputs, O3 preflight, parent-held claim, and checklist requirements. Verify the claim using `Invoke-PlanLedgerClaim.ps1 -Action status`; proceed only when its holder matches the opaque `claim_holder` passed by the parent. The child must not reacquire or release the reservation. A direct invocation without an O3-held reservation retains its own claim lifecycle. If context or route is genuinely absent, ask manual-per-invocation vs O3 per `plan-acquisition.md`. Then resolve pacing `continuous` \| `step_by_step` (`references/develop-modes.md`; default `step_by_step`). Neither route nor pacing bypasses gates, dependencies, scoped session, or a required claim. Execute one step only and stop after its report.

After PLAN path is known: create `{sessions}/{repo-hash}/` if needed; load or create develop session with gates `false` (`SESSION.md` § Develop session - never copy develop gates from the flat repo JSON). If this child was given an explicit step-scoped path (O3 parallel same PLAN), use `plan-{plan-hash}-step-{N}.json`.

**Orchestrated child preflight (before any session or claim-status effect):** when `invocation_context: orchestrated`, run `{{TOOLKIT_ROOT}}/scripts/validation/Invoke-O3ArtifactPreflight.ps1` with the resolved feature root, canonical PLAN path, repo root, and SDD root before creating/loading the develop session or checking the parent's claim. Re-run immediately before any later effect if artifacts may have changed. Nonzero means stop with `plan_stale`; do not ensure session, inspect claim, or implement. The parent runs this same read-only check before queue construction and before each spawn. `Status=approved` is required; `draft`, missing, or any other value blocks.

For an orchestrated invocation, the parent is the only claim lifecycle owner. After the session gate, verify the parent's claim via `Invoke-PlanLedgerClaim.ps1 -Action status`; the returned status must be `claimed` and holder must equal the handoff's `claim_holder`. A missing, released, malformed, or mismatched claim blocks before implementation. Do not call `claim` or `release`; report the blocker to the parent. The parent retains the reservation until it has reconciled the return receipt with SESSION and the durable PLAN checkpoint, then releases using the same holder. Direct invocations without an O3 parent claim continue to acquire/release their own claim when required.

For a step with Classic external access, apply [`CLASSIC-EXTERNAL-ACCESS.md`](../_shared/sdd-artifacts/CLASSIC-EXTERNAL-ACCESS.md). Keep the step's portable target and `read`/`write` scope distinct from O3 receipt `files[]`. Receive any `alias → physical root` map and operation grant separately in trusted invocation context; never copy that map into PRD, PLAN, or receipt. Do not widen the destination or operation set. Proceed only when the effective I/O boundary can enforce the approved scope; otherwise block before the external access.

### 1. Validate step

Step exists; deps **Concluidos** / **Completed**; summarize objective, files, tests, and **REQ-NNN / CA** targets from the step **Aceite** or **Acceptance** line (markers in `references/plan-contract.md`); ask to proceed unless the operator already explicitly confirmed this same step in the current invocation. That confirm has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use a host interactive question only when its answer is observable to the agent; otherwise ask in text. Accept a semantically affirmative answer in the conversation language, not only the literal token `sim`; ambiguity remains blocking. Send no further message until the operator answers every pending question. Silence, timeout, and end of turn are not answers. After the answer, or after an intermediate skill the operator already authorized, resume this skill until the step finishes or this skill declares a blocker with the cause. The confirmation and `step_confirmed` gate remain in force.
For `invocation_context=direct`, an explicit operator authorization in the current invocation may cover a finite, named sequence of eligible steps. Use it only for those steps and actions; do not repeat the step prompt inside its bounds, but persist each step's `step_confirmed` through the canonical helper. Prefer a persisted authorization record in the PLAN execution policy when work must resume in a new session. Missing bounds, unknown source, conflicting scope, or authorization for another action remains blocked. In `orchestrated`, retain O3's separate per-spawn authorization policy.

### 2. Git

Feature branch per `branch-validation.mdc`. Read `references/git-checklist.md`.

### 3-4. Analyze and implement

Glob/Grep/Read scope. Read `references/code-analysis.md` and `references/stack-pointers.md`. Code/tests in English. When this PLAN step is the O3 producer, return only the canonical relay receipt from `RECEIPT.md` (`{ planPath, step, status, files[], deletedFiles[]?, testsSummary, nextStep?, blockedReason? }`); emit `step` as a positive JSON integer. Use `deletedFiles[]` only for explicitly removed paths and follow the shared path-containment rules. Include build only in the US-close receipt when a build is applicable. When delegating nested stack `*-developer` work, require that role's reduced `{ files[], testsSummary }` receipt and validate it locally; do not require `planPath` or `step` from `developer-child`.

### 4b. Evidence-or-zero (REQ-005 / CA4)

Read `references/evidence-or-zero.md` when the step claims AC coverage (or CONTINUITY / operator sets a level ≥ `cheap`) and follow it: EVD/STATE, AC matrix, `validate-evidence` gate.

### 4c. Living loop + TRACE (REQ-006 / CA5)

Read `references/living-loop-trace.md` when CONTINUITY / operator closes the feature wave (or the PLAN’s last implement step before P-DOC / archive) and follow its procedure.

### 5. Commit (optional)

Offer `/commit`; do not auto-commit. When the PLAN is **fully done** and the user leans commit, first run the **sim/pular** asks for memory-bank + project docs when those trees exist (`references/optional-flows.md`). Those asks have no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers every pending question. Silence, timeout, and end of turn are not answers. After the answer, or after an intermediate skill the operator already authorized, resume this skill until the requested function finishes or this skill declares a blocker with the cause. Keep the memory-bank and docs asks. The required **sim** before writes stays.

### 6. Update PLAN + checkpoint
Read `references/plan-contract.md` and `references/plan-update.md` at this step, before the PLAN edit; they hold the PLAN update protocol, navigation rules, companion PRD close, and terminal gate order (`tests-run` then `reset`).

### 7. Report
Load `references/execution-display.md` and `references/session-report.md`. Show the full PLAN-step table, then emit the short result (step, status `done` | `blocked` | `failed`, tests). Do not emit the stage-weight table or the `Develop:` heartbeat. Phrases follow the user chat language.

For a direct Classic step delegated by a parent, the parent owns the operator-facing relay after the child returns: re-read the persisted PLAN, reconcile the step checkpoint with the child report, then show the complete PLAN-step table and next eligible step as defined in `references/execution-display.md`. A child receipt, partial summary, or child-rendered table does not satisfy the parent's relay. If the saved checkpoint cannot be reconciled, stop with `ledger_partial`; do not start the next direct step.

For a direct Classic step delegated by a parent, the parent owns the operator-facing relay after the child returns: re-read the persisted PLAN, reconcile the step checkpoint with the child report, then show the complete PLAN step ledger and next eligible step as defined in `references/execution-display.md`. A child receipt, partial summary, or child-rendered table does not satisfy the parent's relay. If the saved checkpoint cannot be reconciled, stop with `ledger_partial`; do not start the next direct step.

## Must not

Also enforce `references/forbidden.md` (§ Must not (develop scope) holds the full list). Before marking Completed: `references/quality-self-check.md`. Optional user flows: `references/optional-flows.md`.

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
