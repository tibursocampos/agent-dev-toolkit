# Session state and gates

This contract documents session helpers only for consumers that explicitly retain them. Classic SDD (`adt-sdd-spec`, `adt-sdd-plan`, `adt-sdd-develop`) and Orchestrated Delivery (O1/O2/O3) do not use SESSION flags or claims as execution gates. Those flows use the approved PLAN and its execution table for progress. Do not load or apply this contract as an authorization prerequisite for them. `adt-document-implement` retains its scoped documentation-step helper. Other consumers may use helpers only when their own current contract explicitly requires them. ADT Delivery follows its own contracts.

Do not paste this file into PRD/PLAN/adt-sdd-spec bodies.

## Applicability

| Consumer | Session state / claims |
|---|---|
| Classic SDD (`adt-sdd-spec`, `adt-sdd-plan`, `adt-sdd-develop`) | Not required; PLAN is the persisted implementation progress source. |
| Orchestrated Delivery (O1/O2/O3) | Not required; O3 dispatch is serial and reconciles each result into PLAN. |
| ADT Delivery | Governed by ADT-specific contracts; no new SESSION dependency is introduced here. |
| `adt-document-implement` | Retains its existing scoped documentation step and validation helpers. |
| Other toolkit consumers | Apply helpers only when their own current contract explicitly requires them. |

## Compatibility schemas

Runtime scripts published under `<InstallRoot>/scripts/<area>` resolve an omitted `-SddRoot` to `<InstallRoot>/sdd` through `Resolve-EffectiveSddRoot.ps1`. Session and ledger state stays under that active installation's SDD root; helpers must not infer a root from the user profile. Explicit roots remain supported for isolated tests and deliberate callers.

Session files are stored under:

```text
{{SDD_ROOT}}/sessions/
```

| Scope | Path | Fields |
|---|---|---|
| Repo compatibility schema | `{repo-hash}.json` | `storage_confirmed`, legacy `write_confirmed` |
| PLAN compatibility schema | `{repo-hash}/plan-{plan-hash}.json` | legacy `step_confirmed`, `tests_run` |
| PLAN+step compatibility schema | `{repo-hash}/plan-{plan-hash}-step-{N}.json` | legacy per-step `step_confirmed`, `tests_run` |

The PLAN and PLAN+step schemas describe existing runtime compatibility only. Classic SDD and O1/O2/O3 must not create, consult, or require them as execution gates. `adt-document-implement` may use a PLAN-scoped file for its own documentation step.

`{repo-hash}` is the first 16 hex characters of SHA256 of the normalized absolute repository path (forward slashes, no trailing slash). `{plan-hash}` is the first 16 hex characters of SHA256 of the normalized absolute plan path. For `adt-document-implement`, that is `docs/documentation-plan/plan.md` or its explicitly selected alternate plan. On Windows, hash absolute paths with forward slashes; callers and validators must use the same form.

### Repo compatibility schema

```json
{
  "repo": "D:/Source/Repos/MyApp",
  "workflow": "classic|none",
  "phase": "spec|plan|develop|idle",
  "gates": { "storage_confirmed": false, "write_confirmed": false },
  "current_step": null,
  "updated_at": "2026-06-21T12:00:00Z"
}
```

Existing files may contain retired fields. Their presence does not make them gates for Classic SDD or Orchestrated Delivery.

### PLAN compatibility schema

```json
{
  "repo": "D:/Source/Repos/MyApp",
  "plan_path": "D:/Source/Repos/MyApp/docs/documentation-plan/plan.md",
  "step": null,
  "workflow": "classic|none",
  "phase": "develop|idle",
  "gates": { "step_confirmed": false, "tests_run": false },
  "current_step": null,
  "updated_at": "2026-06-21T12:00:00Z"
}
```

`step` is an integer only for a legacy PLAN+step file; otherwise it is `null`. Do not migrate values from a flat repo file into a PLAN-scoped file.

## `adt-document-implement` scoped helper

Only `adt-document-implement` retains the following step confirmation and documentation verification flow. Its gate authorizes that skill's bounded documentation write; it does not authorize product implementation or establish validation for a product PLAN.

Before an existing PLAN-scoped session action (`ensure`, `tests-run`, or `reset`), the helper resolves active repository and plan paths to absolute normalized paths and compares them case-insensitively with the persisted `repo` and `plan_path`. A mismatch fails closed, reports expected and persisted identities, and leaves session bytes unchanged. `status` reports a mismatch rather than presenting a gate from another context. Do not repair or migrate a mismatched session automatically.

For a missing session, the helper creates a schema with the resolved active identity. Session identity is verified against active context; it is not inferred from the filename/hash alone.

1. Resolve the document plan and its scoped session.
2. If `step_confirmed` is false, stop and ask the user in the chat language for confirmation before writing documentation.
3. After confirmation, use the canonical helper; do not edit session JSON inline. After documentation verification is executed and reported, record `tests_run`; reset the scoped gates after the documentation step closes.

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -PlanPath <plan> -RepoPath <repo> -SddRoot <sdd-root> [-Step N] [-CurrentStep N]
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -Action tests-run -PlanPath <plan> -RepoPath <repo> -SddRoot <sdd-root> [-Step N]
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -Action reset -PlanPath <plan> -RepoPath <repo> -SddRoot <sdd-root> [-Step N] [-CurrentStep N]
```

- The default action creates the scoped schema if missing and sets `gates.step_confirmed = true` after confirmation.
- It is idempotent: if `step_confirmed` is already true, it exits 0 without rewriting the file.
- `-Action tests-run` requires `step_confirmed = true` and records the documentation verification only after it has run and been reported.
- `-Action reset` clears both documentation gates and sets `phase = idle` after the step closes. It skips rewriting when both gates are already false.
- If PLAN+step compatibility files are in use, pass `-Step N` when ambiguous. Reset may infer the step only when exactly one matching PLAN+step file exists.
- A failed helper action blocks the current `adt-document-implement` documentation write or state transition. Do not bypass it or mutate session JSON inline.

## Optional validation helper

`validate-session-gates.ps1` remains available for explicit consumers and focused tests. Its exit status checks the requested field; it is not an execution gate for Classic SDD or O1/O2/O3.

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -SddRoot <sdd-root> -RequiredGate write_confirmed
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -PlanPath <plan> -SddRoot <sdd-root> -RequiredGate step_confirmed
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-session-gates.ps1" -RepoPath <repo> -PlanPath <plan> -Step 2 -SddRoot <sdd-root> -RequiredGate tests_run
```

`-PlanPath` must resolve under `-RepoPath` or the classic global features root documented in `STORAGE.md`. Use `-SddRoot` (or `-SessionsRoot` in tests) to resolve sessions under the intended root.

## Integration

| Consumer | Use |
|---|---|
| Classic SDD / O1 / O2 / O3 | No SESSION or claim gate; progress is persisted in PLAN. |
| `adt-document-implement` | Retains its existing scoped documentation step helper. |
| Other consumers | Use helpers only when their own explicit current contract requires them. |
| `rules/guardrails.mdc` | References this applicability matrix. |
