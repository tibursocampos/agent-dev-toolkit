# sdd-develop — canonical scripts

After the user says **sim** for this step, **MUST** persist develop `step_confirmed` via `-File` (cwd = repo root) — **MUST NOT** paste inline PowerShell that mutates session JSON under `sessions/`:

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -PlanPath <plan> -RepoPath . -SddRoot <sdd-root> [-Step N]
```

After targeted tests execute and their results are ready to report, persist the tests gate through the same canonical helper:

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1" -Action tests-run -PlanPath <plan> -RepoPath . -SddRoot <sdd-root> [-Step N]
```

Before ending the develop scope, reset both gates with `-Action reset` (optionally pass `-CurrentStep N+1`). Never mutate the session JSON inline. `tests-run` fails unless `step_confirmed` is already true.

Treat every session-helper invocation, including reset, as a hard gate. A nonzero exit, denied write, or missing confirmation output stops the operation; return `blocked` or `failed` with the observed cause and do not continue or report success. Never bypass the helper or edit session JSON inline. If the canonical SDD root is unwritable, ask the operator to restore a writable root through the supported setup mechanism before retrying the helper.

For a direct invocation that requires a PLAN ledger claim, **MUST** also call once:

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/ledger/Invoke-PlanLedgerClaim.ps1" -Action claim -PlanPath <plan> -Step N -Holder <holder> -RepoPath . -SddRoot <sdd-root>
```

For `invocation_context=orchestrated`, the O3 parent owns this acquisition; the child only checks the matching parent reservation with `-Action status` as specified below. Prefer **one** Shell approve that chains the session helper and direct claim for a direct invocation when the host allows. **CT6:** if the session helper skips rewrite because `step_confirmed` is already true, still ensure the required direct claim exists; for O3, the parent must ensure its claim exists once, while a child must never reacquire it.
