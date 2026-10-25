# Session state and gates

Load at **step -1** of every skill. Do not paste into PRD/PLAN/sdd-spec bodies.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`

## Session file locations

Runtime scripts published under `<InstallRoot>/scripts/<area>` resolve an omitted `-SddRoot` to `<InstallRoot>/sdd` through the shared `Resolve-EffectiveSddRoot.ps1` helper. Session, ledger and execution-mode state therefore stays under the active installation's SDD root; helpers must not infer a root from the user profile. Explicit roots remain supported for isolated tests and deliberate callers.

Two scopes share the same directory root:

```
{{SDD_ROOT}}/sessions\
```

| Scope | Path | Gates owned |
|-------|------|-------------|
| **Repo** | `{repo-hash}.json` | `storage_confirmed`, `write_confirmed` (+ workflow / phase summary) |
| **Develop (PLAN)** | `{repo-hash}/plan-{plan-hash}.json` | `step_confirmed`, `tests_run` |
| **Develop (PLAN+step)** | `{repo-hash}/plan-{plan-hash}-step-{N}.json` | `step_confirmed`, `tests_run` (parallel same PLAN) |

`{repo-hash}` = first 16 hex chars of SHA256 of normalized `$Cwd` (forward slashes, no trailing slash).

`{plan-hash}` = first 16 hex chars of SHA256 of normalized **full plan path** - forward slashes, no trailing slash. Allowed plan paths:

| Consumer | Path hashed |
|----------|-------------|
| `sdd-develop` / O3 child | Classic `.../PLAN/PLAN_*.md` under `features/` |
| `document-implement` | `$Cwd/docs/documentation-plan/plan.md` (or user-given alternate doc plan path) |

Use **PLAN+step** files when `orchestrate-develop` spawns parallel children on the **same** PLAN (steps marked parallel-safe). Default Classic SDD / O3 série: one `plan-{plan-hash}.json` per PLAN.

**Do not mix scopes on the same PLAN:** if any `plan-{planHash}-step-*.json` exists for that PLAN, serial spawns for that PLAN **must** also use PLAN+step files (never fall back to `plan-{planHash}.json` mid-feature).

## Repo session schema

```json
{
  "repo": "D:/Source/Repos/MyApp",
  "workflow": "classic|none",
  "phase": "spec|plan|develop|idle",
  "gates": {
    "storage_confirmed": false,
    "write_confirmed": false
  },
  "current_step": null,
  "updated_at": "2026-06-21T12:00:00Z"
}
```

Legacy repo files may still contain unused `step_confirmed` / `tests_run` keys. On first develop load with a PLAN path, create a **new** scoped develop file with those gates **always `false`**. Do **not** copy develop-gate values from the flat repo JSON (that would inherit another PLAN's approval). Optionally clear `step_confirmed` / `tests_run` on the flat repo file after the scoped file exists so they are unused.

## Develop session schema

```json
{
  "repo": "D:/Source/Repos/MyApp",
  "plan_path": "D:/Source/Repos/MyApp/features/004-x/US01/PLAN/PLAN_004_x.md",
  "step": null,
  "workflow": "classic|none",
  "phase": "develop|idle",
  "gates": {
    "step_confirmed": false,
    "tests_run": false
  },
  "current_step": null,
  "updated_at": "2026-06-21T12:00:00Z"
}
```

`step` is an integer when using PLAN+step scoping; otherwise `null`.

## Resolution algorithm

### Repo session

```
1. Normalize $Cwd (replace \ with /, trim trailing /).
2. repo-hash = SHA256(normalized path)[0:16].
3. sessionsDir = {{SDD_ROOT}}/sessions
   - Create sessionsDir if missing.
4. sessionPath = sessionsDir\{repo-hash}.json
5. If file missing: create default repo schema with repo = $Cwd, workflow = none, phase = idle.
6. Read session; use storage_confirmed / write_confirmed before Write/Shell that needs them.
```

### Develop session (sdd-develop / document-implement / O3 child)

```
1. Resolve full plan path (Classic PLAN under features/, or docs/documentation-plan/plan.md).
   Normalize (\ -> /, trim trailing /). Prefer absolute path.
2. plan-hash = SHA256(normalized plan path)[0:16].
3. repo-hash as above from $Cwd.
4. Ensure sessionsDir\{repo-hash}\ exists.
5. If parallel same-PLAN step N, OR any plan-{plan-hash}-step-*.json already exists for this plan:
     sessionPath = sessionsDir\{repo-hash}\plan-{plan-hash}-step-{N}.json
   Else:
     sessionPath = sessionsDir\{repo-hash}\plan-{plan-hash}.json
6. If scoped file missing: create default develop schema with step_confirmed / tests_run = false
   (never copy develop gates from the flat repo JSON). Optionally remove step_confirmed / tests_run
   from the flat repo file so they cannot be read by mistake.
7. Read scoped session for step_confirmed / tests_run.
8. Always read repo session separately for storage_confirmed / write_confirmed when those gates apply.
```

For `-Action reset`, when `-Step` is omitted and exactly one PLAN+step session file exists for the PLAN, the helper infers that file's step. This supports advancing `-CurrentStep` while clearing the just-completed step's gates. If multiple PLAN+step files exist, pass `-Step N` explicitly; other actions continue to require explicit `-Step` whenever PLAN+step scoping is active.

**Windows:** always hash the **absolute** path with forward slashes. Agents and `validate-session-gates.ps1` must use the same absolute form (avoid relative `$Cwd` vs absolute mismatch).

## Gate rules

Operator-facing STOP / confirm prompts use the **user chat language** (`LANGUAGE.md`). Gate field names and scripts stay English.

| Gate | File | Set `true` when | Required for |
|------|------|-----------------|--------------|
| `storage_confirmed` | Repo | User chose local/global storage (first SDD run) | First PRD/sdd-spec write |
| `write_confirmed` | Repo | User said **sim** to confirm-before-write | New PRD/PLAN/sdd-spec/sdd-plan/tasks |
| `step_confirmed` | Develop (PLAN or PLAN+step) | User said **sim** to implement current step/task | `sdd-develop`, `document-implement` (hash `docs/documentation-plan/plan.md`) |
| `tests_run` | Develop (PLAN or PLAN+step) | Tests executed and reported | Before marking step/task done (`document-implement`: doc write verified / reported - no `dotnet test` required) |

**HIGH companions (WS14):** language surfaces → `agents/LANGUAGE.md`; agreed vs invented → `CONTRACT-PROVENANCE.md`. Do not hard-code artifact locale in gate prompts.

## State, approval, validation, and reconciliation

These records describe different dimensions. A reader must resolve each claim from its owning record; matching labels do not make records interchangeable.

| Dimension | Authoritative persisted record | Writer / permitted transition | What it does not prove |
|-----------|--------------------------------|-------------------------------|------------------------|
| PRD content approval | Canonical PRD metadata: `Aprovação do conteúdo` / `Content approval` plus PRD `Status` | `sdd-spec` records approval only after explicit content approval and successful PRD write. `Pronto para planejamento` / `Ready for planning` is valid only with a persisted approved content record. `sdd-develop` may change PRD `Status` to `Implementado` / `Implemented` only when the entire PLAN closes. | `write_confirmed`, a chat transcript, a receipt, or a status without the approval record does not establish content approval. Missing or conflicting approval metadata is unknown and blocks planning until the PRD owner reconciles it. |
| PLAN write authorization and approval | Canonical PLAN metadata and the repo-scoped `write_confirmed` gate | `sdd-plan` writes only after separate PLAN-write authorization; it marks PLAN `approved` only after the PLAN content is approved. | PRD approval is not PLAN-write authorization or PLAN approval. |
| Step implementation authorization | PLAN execution policy or explicit current invocation, plus PLAN-scoped `step_confirmed` | The operator may authorize a bounded sequence by an explicit source and finite scope. `sdd-develop` records each eligible step through `Invoke-DevelopSessionGate.ps1`; the authorization never bypasses dependencies, step acceptance, or validation. | A general preference, `write_confirmed`, PRD/PLAN approval, or authorization for a different step does not authorize implementation. |
| Whole-PLAN closure authorization | Explicit operator request to close the named PLAN/US, or a persisted bounded authorization whose scope explicitly includes closure | The final `sdd-develop` session records closure only after all steps and required validations pass. If the authorization does not cover closure, ask the operator separately; `tests_run` does not imply close approval. | Step authorization, PRD/PLAN approval, final receipt, or passing validation alone is not closure authorization. |
| Invocation context | Explicit `invocation_context` in the current handoff/invocation; include it in the produced session report/receipt | The caller establishes `direct` or `orchestrated`; a saved host preference does not set it. The runtime SESSION schema does not currently store this field. | `orchestrator_mode`, an existing FEATURE/STORY/CONTINUITY/checklist, or a child being delegated by a Classic coordinator does not change `direct` into `orchestrated`. |
| Execution status | PLAN step and implementation status | The `sdd-develop` session that owns the step updates that step's status and evidence; the final `sdd-develop` close updates overall PLAN/PRD implementation status. Allowed step statuses are `PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`, and `SKIPPED` (`core/skills/sdd-plan/references/status-legend.md`). | A step status, progress count, checkbox, or `COMPLETED` word in a receipt is not validation evidence. `SKIPPED` does not count as a passed step or close the PLAN. |
| Validation result | PLAN evidence cell / step ledger; `STATE.md` and `EVD/` when the configured level requires them | The session that runs or assesses the declared check records `PASS` or `FAIL` with command, boundary, and evidence. `SKIPPED` requires a reason and a declared non-applicability/deferment; `PLANNED` is intent only. | Approval, execution status, a claim, or a planned/unknown/conflicting/skipped result is not `PASS`. A required failure or unresolved result blocks its dependent acceptance and closure. |
| Session gates | Correct repo or PLAN-scoped SESSION file | Canonical session helpers own `storage_confirmed`, `write_confirmed`, `step_confirmed`, and `tests_run` transitions. Identity mismatch fails closed. | Session gates are not approval metadata, validation results, PLAN status, or a ledger claim. |
| PLAN claim | PLAN-LEDGER claim and audit records | `Invoke-PlanLedgerClaim.ps1` owns `claimed` / `released` and rejection transitions for concurrency. | A claim is a temporary reservation, not execution, approval, acceptance, test result, or closure. |
| Handoff result | Returned receipt | The assigned executor reports `done`, `blocked`, or `failed`; the caller validates it against the owning persisted records. | A receipt is not durable state and cannot rewrite or override the PLAN, SESSION, or evidence. |

### Allowed transitions

| Record | Allowed transition | Owner / guard |
|--------|--------------------|---------------|
| PRD approval/status | Content unapproved/unknown → approved + `Pronto para planejamento` / `Ready for planning`; approved PRD → `Implementado` / `Implemented` only at authorized whole-PLAN close | `sdd-spec` after explicit content approval and separate write authorization; `sdd-develop` at close. Revisions to approved content require a fresh approval record. The authorized `sdd-develop` owner may first run `Invoke-O3ArtifactPreflight.ps1 -AuthorizeCompletedPlanPrdTransition` after the PLAN has `Implementation status=COMPLETED`, every step is `COMPLETED`, and all closeout validations and explicit closure authorization are satisfied. This read-only check permits only the localized transition from the planning-ready PRD status, requires persisted content approval, and still blocks on every other preflight issue. The owner then changes only PRD `Status` to the reported target and reruns standard preflight; only that post-transition validation establishes terminal consistency and confirms the approval record remains present. The switch is an owner attestation, not identity authentication, and is not permission to bypass closure gates. |
| PLAN approval | `draft` → `approved`; an approved PLAN returns to draft only through its owner and an explicit approved revision | `sdd-plan` after separate content approval, PLAN-write authorization, and applicable structural validation. |
| PLAN implementation | `NOT_STARTED` → `IN_PROGRESS` → `COMPLETED` only with all required steps completed, validations passed, and close authorization | `sdd-develop`; `SKIPPED`, progress `N/N`, or a receipt cannot substitute for a completed step or validation. |
| PLAN step | `PENDING` → `IN_PROGRESS` → `COMPLETED` or `BLOCKED`; `BLOCKED` resumes only after the recorded cause is gone; `SKIPPED` requires owner reconciliation and cannot satisfy dependency/closure | The session executing the step is sole writer. See `core/skills/sdd-plan/references/status-legend.md` and `core/skills/sdd-develop/references/plan-update.md`. |
| Validation result | `PLANNED` → `PASS` / `FAIL` / justified `SKIPPED`; unknown/conflict → resolved result only by the owner with new evidence | The check executor/assessor records result and evidence. `SKIPPED` never becomes `PASS` and does not satisfy a required check. |
| SESSION gates | `false` → `true` via the applicable canonical helper; reset → `false` after the step scope closes | Session scripts only; identity mismatch blocks mutation. |
| PLAN claim | absent → `claimed` → `released`, or an auditable rejected claim | PLAN-ledger helper; no transition implies completed work. |
| Receipt | executor reports one terminal recommendation: `done`, `blocked`, or `failed` | Executor owns the report; caller validates it and never treats it as a persisted state transition. |

### Bounded authorization and recovery

- A sequential authorization is reusable only when its source, authorized action, finite step range/identifiers, and explicit limits are persisted in the current PLAN execution policy or supplied in the current invocation. An omitted bound, ambiguous source, or conflict is not authorization. It may prevent repeated step prompts only within that bound; the session helper still records each step's `step_confirmed` gate.
- Content approval, PRD/PLAN writing, PLAN content approval, step implementation, and whole-PLAN closure remain separate actions and gates. No gate implies another, and no approval alone satisfies a validation or closure condition.
- Recover from the persisted owner record for the dimension in question, not from chat history, host preference, or a stale receipt. Re-read the canonical PRD/PLAN and the correctly scoped SESSION/claim/evidence records. A disagreement is reported to the owner; do not repair another owner's transition, infer a winner, bulk-edit historical statuses, or advance dependents while the disagreement remains.
- `COMPLETED` requires the step's acceptance plus every applicable required validation recorded as `PASS` with evidence. A justified `SKIPPED` check may be non-blocking only when the PLAN declares it non-applicable or deferred and the acceptance has other sufficient evidence; it never becomes `PASS`. A step marked `SKIPPED`, or any `PLANNED`, unknown, conflicting, or failed required result, cannot by itself contribute to overall PLAN closure.

## Before Write or mutating Shell

### Persisted identity is a precondition to mutation (REQ-005 / CA5)

Before any existing PLAN-scoped develop session action (`ensure`, `tests-run`, or `reset`), the helper resolves the active repository and PLAN to absolute paths, normalizes separators and trailing separators, and compares them case-insensitively with persisted `repo` and `plan_path`. Both fields must match. A mismatch fails closed, reports the resolved expected and persisted identities, and leaves the session bytes unchanged. `status` also reports the mismatch instead of presenting a gate from another context. Do not repair, rewrite, or migrate a mismatched session automatically; investigate the path/context and use the correct session scope.

For a missing session, the helper creates the schema with the already-resolved active identity. Session identity fields are not inferred from the session filename/hash alone: they are verified against the active context before an existing file can change.

1. Resolve the correct session file(s) for the gate in play.
2. If required gate is `false`: **STOP** - ask user in the **user chat language** (`LANGUAGE.md`) - do not proceed.
3. After user **sim** for develop `step_confirmed`: **MUST** use the canonical helper (idempotent) via `-File` — **MUST NOT** inline-mutate session JSON. After tests execute and are reported, use `-Action tests-run`; before closing the scope, use `-Action reset`:

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -PlanPath <plan> -RepoPath <repo> -SddRoot <sdd-root> [-Step N] [-CurrentStep N]
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -Action tests-run -PlanPath <plan> -RepoPath <repo> -SddRoot <sdd-root> [-Step N]
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -Action reset -PlanPath <plan> -RepoPath <repo> -SddRoot <sdd-root> [-Step N] [-CurrentStep N]
```

- Creates the PLAN-scoped develop session schema when missing; sets `gates.step_confirmed = true`.
- **Idempotent (REQ-011 / CT5):** if `step_confirmed` is already `true`, exit 0 and **do not rewrite** the file.
- `-Action tests-run` requires `step_confirmed = true`, records tests only after execution/reporting, and skips rewriting if already true.
- `-Action reset` clears both develop gates and sets `phase = idle` after step close; it skips rewriting when both are already false.
- Every helper invocation is a required gate: a nonzero exit, denied write, or missing confirmation output stops the current operation. Report `blocked` or `failed` with the helper's cause; do not continue to claim, spawn, implement, validate completion, or report success. Never bypass the helper or mutate session JSON inline. If the canonical SDD root is not writable, ask the operator to restore a writable root through the supported setup mechanism, then retry the same helper only after that condition changes.
- **RN04 / CT6 (REQ-012):** does **not** claim the PLAN ledger — still **MUST** call `{{TOOLKIT_ROOT}}/scripts/ledger/Invoke-PlanLedgerClaim.ps1` separately when a claim is required (skip of session write does **not** skip a missing claim). Prefer one Shell approve chaining both `-File` calls when the host allows.
4. Repo gates (`storage_confirmed` / `write_confirmed`) remain on the flat `{repo-hash}.json` (helper above is develop-scope only).

## After develop step completes (mandatory)

1. On the **scoped develop** file, call the canonical helper with `-Action reset`; it sets both gates to `false` and `phase` to `idle` (optionally updating `current_step`). For a PLAN+step session, pass `-Step N` or rely on inference only when exactly one PLAN+step file exists.
2. On the **repo** file: set `write_confirmed` to `false` if it was used; do **not** clear another PLAN's develop gates.
3. Write only the files touched.
4. **STOP** that develop scope - handoff to new conversation (or next O3 child with its own scoped file).

## Parallel O3 (Orchestrated Delivery)

Parallel `sdd-develop` children **must** use distinct develop session files:

| Parallel case | Session file |
|---------------|--------------|
| Different PLANs | `plan-{planHashA}.json` and `plan-{planHashB}.json` |
| Same PLAN, parallel-safe steps | `plan-{planHash}-step-{N}.json` per step |

Also require disjoint file scopes in the working tree (see `orchestrate-develop`). No git worktrees in MVP.

## Validation script

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -SddRoot <sdd-root> -RequiredGate write_confirmed
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -PlanPath <plan> -SddRoot <sdd-root> -RequiredGate step_confirmed
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -PlanPath <plan> -Step 2 -SddRoot <sdd-root> -RequiredGate tests_run
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -PlanPath <repo>/docs/documentation-plan/plan.md -SddRoot <sdd-root> -RequiredGate step_confirmed
```

`-PlanPath` must exist and resolve under `-RepoPath` or under the classic global features root (`STORAGE.md`). Pass `-SessionsRoot` (tests) or `-SddRoot` so sessions resolve to `<SddRoot>/sessions` (same rule as ledger claim).

Exit 0 = gate approved; exit 1 = blocked.

Canonical scripts (REQ-014):

| Script | Role |
|--------|------|
| `{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1` | `ensure` sets `step_confirmed`; `-Action tests-run` records `tests_run` only after declared tests execute and pass; `-Action reset` clears both develop gates |
| `{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1` | Read/check gate true vs blocked |
| `{{TOOLKIT_ROOT}}/scripts/ledger/Invoke-PlanLedgerClaim.ps1` | Claim SoT (unchanged; not reimplemented by session helper) |

## Integration

| Consumer | Use |
|----------|-----|
| All skills | Step -1 gate check before Write/Shell |
| `sdd-develop` / `document-implement` / O3 children | Develop session scoped by plan path (or PLAN+step); **MUST** call `Invoke-DevelopSessionGate.ps1` after **sim** (REQ-012); claim still required when absent (CT6) |
| `rules/guardrails.mdc` | References this file |
