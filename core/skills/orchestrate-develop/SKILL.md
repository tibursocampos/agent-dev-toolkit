---
name: orchestrate-develop
description: >-
  Orchestrated Delivery O3: one Task subagent per PLAN step (sdd-develop contract); parent never writes app code. Updates CONTINUITY. Scope close starts run-tests and review only when the operator asked to close the wave. Use when invoking /orchestrate-develop.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: orchestrate-develop

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user asks for: `/orchestrate-develop`, `orchestrate develop`, `/orchestrate-develop`, or Orchestrated Delivery O3 after O2 handoff.

Required: full feature path **or** a specific `PLAN/PLAN_NNN_*.md` path under a story.

## Outcome

1. Pending PLAN step(s) executed via Task children when `subagents=native` (`SPAWN.md`), each following the **`sdd-develop` contract** (one PLAN step per child / invocation); when `subagents=none` or Task unavailable → **fallback** handoff to manual `/sdd-develop` (parent never writes app code; never hard-fail)
2. Feature `CONTINUITY.md` updated (phase `develop`, progress, typed next invoke, **Memory-bank** path + status)
3. When the operator asked to close the wave, handoff to `code-review` (`- single` or `- multi-angle`; skill asks if omitted). When the operator did not ask, do not start that validation or specialist loop; hand off only the next step / next story

**Step 0 (required):** Memory Bank Gate (`MEMORY-BANK.md`, policy `auto`) **before** building the step queue / spawning children. Resolve `bank_root` via `STORAGE.md` + `STORAGE-RESOLUTION.md`. CONTINUITY stays the feature phase/handoff source.

**Step N (after code changes):** when at least one develop child succeeded with app file changes, run `memory-bank-init` mode **`refresh-light`** at `bank_root` before final handoff (`MEMORY-BANK.md` Step N). Confirm in the user chat language first.

**Parent orchestrator never** writes application code, never marks multiple PLAN steps done in one child, and never bypasses `sdd-develop` gates (`step_confirmed`, tests before complete).

**Alternative (always valid):** user runs manual `/sdd-develop - <portable-plan-path> - Step N` without this skill (RF05 / CA5). Manual Classic SDD does **not** require memory-bank (CA7).

**Mental map (ids unchanged):** O3 ≈ **apply** (implement PLAN steps via `sdd-develop`). O1 ≈ explore; O2 ≈ FEATURE+PRD+CHANGE. See `CHANGE-CONTRACT.md`.

**Evidence verifier (REQ-005 / CA4):** children record `features/NNN-slug/{USnn|TSnn}/EVD/` + `STATE.md` and run `validate-evidence` inside `sdd-develop`. **Verifier ≠ O3** — do **not** use O3 / Task parallelism as the evidence verifier mechanism (sequential script gate only). Levels: `off` \| `cheap` \| `standard` \| `strict`. Contract: `EVD-STATE-CONTRACT.md`.

**Living loop / TRACE (REQ-006 / CA5):** at feature-wave close, children (or the final develop child) append `features/NNN-slug/TRACE.jsonl` and run **converge → sync current → archive**, then `validate-trace -RequireArchiveComplete`. Parent must **not** use O3 parallelism as the archive verifier. Contract: `TRACE-ARCHIVE-CONTRACT.md`.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/command.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Pipeline Orchestrated Delivery, paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Invocation contexts (`direct` vs `orchestrated`, `IC-DIRECT-ORCHESTRATED`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Storage | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Dynamic manifest / repository-global root resolution (only when resolving storage) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE-RESOLUTION.md` |
| Step 0 Memory Bank Gate | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |
| Memory-bank create/refresh | `{{TOOLKIT_ROOT}}/skills/memory-bank-init/SKILL.md` |
| Develop contract (source of truth) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/SKILL.md` + `{{TOOLKIT_ROOT}}/skills/sdd-develop/reference.md` |
| SESSION gates | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md` |
| CONTINUITY template | `{{TOOLKIT_ROOT}}/skills/_shared/templates/features/CONTINUITY.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/<section>.md` |
| Execution modes (serial/parallel/manual; queue/claim) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/execution-modes.md` |
| plan-acquisition (REQ-008 / CA3) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/plan-acquisition.md` |
| Execution display (before each spawn and after each receipt) | `{{TOOLKIT_ROOT}}/skills/sdd-develop/references/execution-display.md` |
| Develop modes `continuous` \| `step_by_step` (007 REQ-009) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/develop-modes.md` |
| plan-contract + delivery-baseline (REQ-010) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/plan-contract.md` |
| O3 paired baseline and delta/risk review (REQ-010) | `{{TOOLKIT_ROOT}}/skills/orchestrate-develop/references/step-queue-spawn.md` |
| Spawn native vs fallback (capability `subagents`) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Task subagent model (default omit; rare premium gate) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Code review (ask mode) | `{{TOOLKIT_ROOT}}/skills/code-review/SKILL.md` |

**Never by default:** do not preload `references/command.md` before Step -1 gates; do not preload `sdd-develop` + all developer guideline packs into the parent, or paste guideline bodies into develop children. Parent loads contracts and SPAWN; children load `sdd-develop` for their one step.

**Progressive load:** `PIPELINE.md` + `STORAGE.md` first; after gates load `references/command.md` for step discovery; fan-out to `MEMORY-BANK.md` at Step 0, `SPAWN.md` before spawn, `sdd-develop` contract into the child prompt path only, and **one** `references/<section>.md` per Process step — never full `reference.md` when a section file exists (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Command playbook (step discovery) | `references/command.md` |
| Gate / Orchestrated Delivery | `PIPELINE.md` |
| Feature / PLAN / bank roots | `STORAGE.md` |
| Step 0 Memory Bank | `MEMORY-BANK.md` |
| Before Task / fallback to manual develop | `SPAWN.md` |
| Child implement contract | `{{TOOLKIT_ROOT}}/skills/sdd-develop/SKILL.md` |
| Preconditions / Step 0 / Step N refresh-light | `references/preconditions.md` |
| Anti-bypass checklist (CA5) | `references/anti-bypass.md` |
| Step queue / spawn child / Task skeleton | `references/step-queue-spawn.md` |
| Step 5.5 post-implement verifier (`verify_mode`) | `references/step-verifier.md` |
| Safe parallelism | `references/parallelism.md` |
| Execution modes (serial/parallel/manual + ledger) | `references/execution-modes.md` |
| plan-acquisition (canonical PLAN) | `references/plan-acquisition.md` |
| Develop modes `continuous` \| `step_by_step` | `references/develop-modes.md` |
| plan-contract markers + delivery-baseline | `references/plan-contract.md` |
| CONTINUITY / handoff / stop conditions | `references/continuity-handoff.md` |
| Contract reuse / boundaries / invoke strings | `references/contract-boundaries.md` |
| Caveman / resolve feature / PLAN set | `references/process-common.md` |
| Must not (full) | `references/must-not.md` |
| Review handoff | `{{TOOLKIT_ROOT}}/skills/code-review/SKILL.md` |

## Process

After gates: **Read `references/command.md`** for ordered step discovery (do not dump this Process section into child prompts). Then load `references/<section>.md` for the current step only — **not** full `reference.md`. Do not skip gates.

### Step -1b - Caveman Mode (Full cap)
Apply Full caveman prefs when active. Read `references/process-common.md` § Process — Caveman (Full cap).

### 1. Gate check
Report the Step -1 gate checklist in chat. Load `PIPELINE.md` (Orchestrated Delivery) and `SESSION.md`. **STOP** if any gate unchecked. Ask user **sim** before spawning the first develop child. That confirm has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers every pending question. Silence, timeout, and end of turn are not answers. After the answer, resume this skill until the spawn finishes or this skill declares a blocker with the cause. The required **sim** before writes stays.

### 1b. Resolve invocation context
Load `INVOCATION-CONTEXTS.md`. This invoked `orchestrate-develop` skill runs as `orchestrated` (`IC-DIRECT-ORCHESTRATED`); every develop child handoff must include `invocation_context: orchestrated` (path cite only — no contract body dump). This route belongs to the active O3 invocation. It does not make a separate Classic/direct `sdd-develop` invocation orchestrated merely because a parent coordinates work, `orchestrator_mode=always`, or its PLAN changes O3 contracts.

### 2. Resolve feature / PLAN set (plan-acquisition)
Load `STORAGE.md` and `STORAGE-RESOLUTION.md`; resolve feature + `bank_root`; path sanitize; **plan-acquisition** for canonical PLAN path(s) or **STOP** if missing. Before queue parsing, session creation, claim, or specialist invocation, run the deterministic read-only artifact gate:

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/Invoke-O3ArtifactPreflight.ps1" -FeatureRoot <feature-root> -PlanPath <canonical-plan> -RepoPath <repo-root> -SddRoot <sdd-root> -EmitStepTable
```

Any nonzero result is `plan_stale` / blocked: do not create or update a session, claim, or specialist (including an implementer specialist). Inspect the exact diagnostic and classify it before stopping. If the failure is a repairable PRD/PLAN/CHANGE structural or cross-artifact inconsistency with no unresolved material decision, automatically route correction through O2 (`orchestrate-deliver`) in this same invocation; O2's existing owner skills perform the correction and its approval/write gates. Do not ask the operator to rerun O2 or relay routine validator output. If a returned specialist authored the affected document, use a fresh bounded invocation under the same owner contract; never reuse the completed child. If the correction changes approved meaning, requires missing evidence/access, reveals a product/contract question, or the owner contract requires a human approval, stop only at that actual gate and ask for the specific input. After O2 reconciliation, reread canonical artifacts and rerun this preflight; only a passing result permits O3 to create/update a session, acquire a claim, or dispatch a code implementer. Never edit PRD/PLAN/CHANGE from O3 or weaken a validator. Re-run after checkpoint/CONTINUITY reconciliation and immediately before every subsequent effect; do not rely on an earlier snapshot. Only exact PLAN metadata `Status=approved` passes. Parse queue and dependency order exclusively from the saved PLAN; validate that its six related artifacts agree, then derive CONTINUITY from the saved and re-read PLAN. Report the validator's `features_versioned` state verbatim; `false` means local SDD files are unversioned and may not accompany commits/clones. Do not call them committed. Read `references/plan-acquisition.md` and `references/process-common.md` § Process — Resolve feature / PLAN set.

### 3. Step 0 - Memory Bank Gate
Follow `MEMORY-BANK.md` (policy default **`auto`**). Bank root = resolved `bank_root` - **not** under `features/`. Pass **`bank_path`** into every develop child as read-only Prior context. Read `references/preconditions.md` § Step 0 - Memory Bank Gate.

### 4. Build step queue (deps)
Parse pending steps; respect Deps; resolve **execution mode** (`serial` default) and **develop pacing** (`step_by_step` default \| `continuous`); present the pending-only dispatch queue separately from the complete PLAN-step table; wait for **sim**. Every user-facing O3 status summary or transition must show the complete table for every PLAN step exactly once, including when no step is eligible or a blocker stops the queue. Never derive the displayed rows from the pending-only dispatch queue. That confirm has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers every pending question. Silence, timeout, and end of turn are not answers. After the answer, resume this skill until the queued step finishes or this skill declares a blocker with the cause. Read `references/execution-modes.md`, `references/develop-modes.md`, `references/plan-contract.md`, and `references/step-queue-spawn.md`.

### 5. Spawn exactly one step child (CA5)
Load `sdd-develop/references/execution-display.md` before the first spawn and after each receipt. Before the first spawn, render the complete O3 PLAN-step progress table from `LIVE-STAGE-TABLE.md`, with one row for every PLAN step. Use `Invoke-O3ArtifactPreflight.ps1 -EmitStepTable` to render the deterministic table from the freshly re-read canonical PLAN. When current validated receipt, checkpoint, session, or claim evidence changes an operational status, build a complete JSON array with one `{ Id, Status, Evidence }` object for every canonical PLAN step and pass it using `-StepStateOverridesPath`; use the re-read PLAN status for unchanged steps and overlay only values supported by reconciled evidence. The formatter rejects missing, duplicate, extra, or invalid rows. This projection changes display only; never use it to alter PLAN validation or dispatch eligibility. Keep the pending-only dispatch queue separate; it never provides display rows. After each child return, validate the receipt and reconcile the persisted PLAN checkpoint, then redraw the complete table before evaluating the next spawn. Update the affected row when a blocker, failure, or other advancement gate becomes observable. Every O3 status message and transition, including blocked, stopped, approval, and dispatch summaries, includes the full table. If the host exposes no intermediate event, keep the last verifiable state; do not invent streaming or a heartbeat. A valid receipt also gets a short result naming the step, status (`done`, `blocked`, or `failed`), and tests. Do not put the weighted stage table, the `Develop:` heartbeat, or a raw ledger dump in the chat. The O3 progress table is the operator-facing step ledger at close; the persisted PLAN progress table remains durable state. Track closeout gates separately.

Use `ROSTER.md` as the spawn source of truth: call `repo-analyst` for brownfield/impact uncertainty or `needs_api`; call `architect` for `needs_domain`, greenfield, or brownfield mirror; call `database` only for `needs_database` or persistence in scope. Evaluate those conditions once before the first PLAN step, not before every intermediate step. Do not repeat that impact, architecture, and persistence pass before an intermediate step. Run the same pass again when code review is requested against that PLAN. Drift in contract, order, or acceptance stops with `plan_stale` and returns to `sdd-plan`. Do not rewrite the graph. Honor the ledger claim. One Task = one PLAN step. Omit Task `model` by default. If Task is unavailable, hand off to manual `/sdd-develop`. When fallback work requires editing and the host is in Plan/Ask, pause and explicitly ask the operator to switch to Agent; do not attempt the edit or silently change mode. Read `references/step-queue-spawn.md` and `references/anti-bypass.md`.

Before the first child of a brownfield or impact-uncertain PLAN, load the applicable O1 `ANALYSIS/` and `ARCH/` artifacts and compare their evidenced areas with the first eligible step's declared artifacts and affected components. Pass their portable paths and only the relevant evidence summary to that child. The child reads the cited analysis and checks that its current target area is covered before editing; a step target outside the analysis, contradictory current evidence, or an unresolved material gap blocks that first spawn for a focused analysis refresh. If the context establishes that no brownfield analysis applies, record the reason. Do not repeat this repository-level check for later steps unless material drift changes the affected area; each step still performs its own scoped pre-implementation analysis under `sdd-develop`.

Before a child changes code, show the current branch and apply the integration-branch gate. That gate belongs to this skill, `sdd-develop`, `developer`, and `*-developer` (`core/policy/guardrails.md`).

Immediately before invoking each child, re-run `Invoke-O3ArtifactPreflight.ps1`; then perform SESSION and PLAN-LEDGER checks. The preflight is read-only and must pass before those effects. O3 parent is the single claim lifecycle owner: acquire exactly once before spawn/handoff (the mode gate already acquires for serial/parallel), pass `claim_holder`, retain it while execution may continue, and release only after receipt, SESSION, and durable PLAN checkpoint reconcile. Confirmed pre-execution dispatch failure or confirmed cancellation may release after checkpoint verification; uncertain execution or source conflict retains the claim and blocks advancement. Record the release confirmation or retention reason in the parent reconciliation summary. Set `invocation_context=orchestrated` explicitly in every child handoff and provide the scoped checklist input required by the O3 contract. A stale/missing/inconsistent artifact pauses the queue for reconciliation; do not silently use CONTINUITY as a substitute queue. The child's direct PLAN fallback never waives O3 preflight, parent-claim status verification, or checklist requirements.

Each child invocation is idle after its single PLAN step returns. Continue it (SendMessage) only for the same topic and scope while its context is still relevant; a new request, a different scope, or an already-large context uses a fresh invocation with a bounded handoff. After a child returns, the parent runs `scripts/validation/Invoke-O3ReceiptValidation.ps1` against the returned JSON before reconciliation, supplying the expected repo/PLAN/step, `-AllowedPathPrefixesPath` to the coordinator's JSON list of portable path prefixes, and `-AuthorizedRootsPath` to its separate coordinator-controlled JSON object mapping aliases to absolute roots. External alias roots come only from the coordinator's trusted local context and are never read from the receipt. Then validate the receipt against the PLAN acceptance, session gates, and claim; read and reconcile the checkpoint the child already persisted; show the step ledger and short result; release the claim with the same `claim_holder` only after execution is complete and sources agree; then evaluate the next spawn. The child `sdd-develop` session is the sole writer of that step's PLAN row, evidence, and checkpoint; the parent is read-only for those fields and never repairs them by a second write. If the checkpoint is incomplete, execution may still be active, or sources conflict with the receipt, keep the step blocked and retain the claim; return the correction to its owner in a fresh invocation only when safe. The PLAN ledger/checkpoint is durable step state; the PLAN-LEDGER claim is the atomic pre-work reservation; the short result is communication; and `CONTINUITY.md` is the parent's separate synthesis/path handoff. None substitutes for another.

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`: `done` permits evaluation of the next step only after reconciliation; `blocked` keeps dependents stopped and names the missing prerequisite/input; `failed` reports evidence and a bounded recovery action. An unanswered user question is `open_question` and remains blocked. Do not repeat a spawn, prompt, or state transition without new user input or changed evidence and revalidation. A handoff suggestion alone never advances the queue.

The child producer must emit relay `status: done` for a successful PLAN step; do not copy the PLAN row label `COMPLETED` into the receipt. For interoperability, `Invoke-O3ReceiptValidation.ps1` accepts only the trimmed, case-insensitive aliases `complete` and `completed` and normalizes them to canonical `done`. After validation, reconcile using the guard's `canonical_receipt` projection, never the child's raw status token. `blocked` and `failed` remain distinct; any other status or an implementation outside the PLAN acceptance blocks the step. Do not delegate the next step. Do not invent a fix. Do not rewrite the PLAN. If receipt validation is missing, incomplete, inconsistent, blocked, or failed, pause the step and all dependents; do not persist a successful completion or spawn the dependent. In `continuous`, use `Test-ContinuousQueueStepAuthorization` after the checkpoint and progress table have been re-read and the step ledger and short result have been shown; its authorization covers only the first eligible next step and is consumed by that spawn. Re-evaluate after every child return. `step_by_step` still requires confirmation for each spawn.

For a canonical PLAN stored under global SDD storage outside the application repository, also pass `-SddRoot <effective-sdd-root>` from trusted coordinator context; keep `-RepoRoot` pointed at the application repository. Omit `-SddRoot` for repo-local PLANs. The receipt's `planPath` remains portable as `sdd/<path-relative-to-SddRoot>`. Before spawn, the coordinator must authorize the external artifact alias and portable path prefixes in its separate inputs. In `files[]`, global SDD files use `external:<alias>/<relative-path>`; application files remain repository-relative. Optional `deletedFiles[]` uses the same portable scope and alias rules for removed paths; the validator checks the authorized parent path and requires the leaf entry to be absent. Never derive `SddRoot`, alias roots, or authorized prefixes from child receipt data. Existing containment and scope checks still apply.

### 5.5 Post-implement verifier (opt-in)
When `preferences.json` has `verify_mode: true`, spawn a **read-only verifier child** after a successful implementer return and **before** CONTINUITY update / next spawn. Default `verify_mode` is `false` — skip when unset. The verifier uses its separate result contract in `references/step-verifier.md`; do not validate it as an implementer relay. Read that reference.

### 6. Safe parallelism (optional)
Default **serial** mode. Parallel only when mode is `parallel` **and** all independence conditions + user **sim** + distinct SESSION files; cap ≤4. Mode violations reject/audit — never silent ignore. Read `references/execution-modes.md` and `references/parallelism.md`.

### 7. Stop conditions
Stop on story/feature done, context pressure, child blocked, or **cancelar**. Read `references/continuity-handoff.md` § Process — Stop conditions.

### 8. CONTINUITY
Update phase / Memory-bank / estado / handoff at each milestone. Read `references/continuity-handoff.md`.

### 9. Step N - Memory Bank refresh-light (after code changes)
When a child changed app files: confirm → `refresh-light` → CONTINUITY `refreshed` (or skip). Read `references/continuity-handoff.md` § Process — Step N refresh-light and `references/preconditions.md` § Step N - refresh-light.

### 10. Handoff
Run the scope-close loop only when the operator asked to close the wave. When the operator did not ask, do not start `run-tests`, `code-review`, a post-review rerun, the security review, or another specialist the operator did not request. For a requested close, render and maintain the separate O3 closeout table in `LIVE-STAGE-TABLE.md` alongside the PLAN-step table; update it after each gate result and any later change that affects its evidence.

When the operator asked to close the wave, use this required order: `run-tests` -> `code-review` -> `run-tests` after review changes (or record that no changes required a rerun) -> the `security` role/prompt review of the diff -> assign an applicable build to `shell-runner` at US close only -> ask `/commit` -> ask `/push` separately. If no build command applies, record `not applicable`. Do not run build per step. When code review is requested against this PLAN, run the impact, architecture, and persistence pass again before that review (`repo-analyst`, `architect`, and `database` when the PLAN cites persistence). That second pass is not a per-step spawn. Read `references/continuity-handoff.md` § Handoff copy. The security handoff is role-based (`{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md`); use the host’s documented spawn mechanism when available, otherwise perform the bounded fallback in-parent. Do not claim a `/security` command or host capability that is not present. A requested wave close may still record `converge`, `sync_current`, and `archive` (`TRACE-ARCHIVE-CONTRACT.md`). Do not delete that contract.

## Anti-bypass checklist (must enforce)

Parent and children **must not** bypass CA5. Enforce the full table in `references/anti-bypass.md` before every spawn and before marking any step done. Critical: parent writes **no** app code; one child = one PLAN step; **sim** before next spawn; PLAN-scoped SESSION files for parallel children.

## Must not

Enforce the full list in `references/must-not.md`. Critical always-on: no parent app code; no multi-step children; no hard-fail when Task unavailable (fallback `/sdd-develop`); portable paths only; do not ignore `IC-DIRECT-ORCHESTRATED` (`INVOCATION-CONTEXTS.md`).

## Handoff

| Situation | Next |
|-----------|------|
| Next PLAN step | New chat -> `orchestrate-develop` **or** `sdd-develop - <plan> - Step N` |
| Story/feature done | `run-tests`, then `code-review`, then `run-tests` after review changes, then the security role/prompt review, then `/commit`, then `/push` (`references/continuity-handoff.md`) |
| Missing PLAN | `orchestrate-deliver` / `sdd-plan` |
| Prefer no orchestrator | Manual `sdd-develop` only |

### Canonical strings

```text
/orchestrate-develop - <portable-feature-path>
```

```text
/sdd-develop - <portable-plan-path> - Step N
```

```text
/code-review
/code-review - multi-angle
```
