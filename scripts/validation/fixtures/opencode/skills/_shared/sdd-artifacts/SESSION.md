# Session state and gates

Load at **step -1** of every skill. Do not paste into PRD/PLAN/sdd-spec bodies.

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/skills/_shared/sdd-artifacts/SESSION.md`

## Session file locations

Two scopes share the same directory root:

```
E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/sessions\
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

Use **PLAN+step** files when `orchestrate-develop` spawns parallel children on the **same** PLAN (steps marked parallel-safe). Default Forma A / O3 série: one `plan-{plan-hash}.json` per PLAN.

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
3. sessionsDir = E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/sessions
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

**Windows:** always hash the **absolute** path with forward slashes. Agents and `validate-session-gates.ps1` must use the same absolute form (avoid relative `$Cwd` vs absolute mismatch).

## Gate rules

| Gate | File | Set `true` when | Required for |
|------|------|-----------------|--------------|
| `storage_confirmed` | Repo | User chose local/global storage (first SDD run) | First PRD/sdd-spec write |
| `write_confirmed` | Repo | User said **sim** to confirm-before-write | New PRD/PLAN/sdd-spec/sdd-plan/tasks |
| `step_confirmed` | Develop (PLAN or PLAN+step) | User said **sim** to implement current step/task | `sdd-develop`, `document-implement` (hash `docs/documentation-plan/plan.md`) |
| `tests_run` | Develop (PLAN or PLAN+step) | Tests executed and reported | Before marking step/task done (`document-implement`: doc write verified / reported - no `dotnet test` required) |

## Before Write or mutating Shell

1. Resolve the correct session file(s) for the gate in play.
2. If required gate is `false`: **STOP** - ask user **(pt-BR)** - do not proceed.
3. After user **sim**: set gate `true`, update `updated_at`, write **that** session file only.

## After develop step completes (mandatory)

1. On the **scoped develop** file: set `step_confirmed` and `tests_run` to `false`; set `phase` to `idle` or keep `develop` with `current_step` updated.
2. On the **repo** file: set `write_confirmed` to `false` if it was used; do **not** clear another PLAN's develop gates.
3. Write only the files touched.
4. **STOP** that develop scope - handoff to new conversation (or next O3 child with its own scoped file).

## Parallel O3 (Forma C)

Parallel `sdd-develop` children **must** use distinct develop session files:

| Parallel case | Session file |
|---------------|--------------|
| Different PLANs | `plan-{planHashA}.json` and `plan-{planHashB}.json` |
| Same PLAN, parallel-safe steps | `plan-{planHash}-step-{N}.json` per step |

Also require disjoint file scopes in the working tree (see `orchestrate-develop`). No git worktrees in MVP.

## Validation script

```powershell
.\scripts\validation\validate-session-gates.ps1 -RepoPath "D:\Source\Repos\MyApp" -RequiredGate write_confirmed
.\scripts\validation\validate-session-gates.ps1 -RepoPath "D:\Source\Repos\MyApp" -PlanPath "D:\...\PLAN_004_x.md" -RequiredGate step_confirmed
.\scripts\validation\validate-session-gates.ps1 -RepoPath "D:\Source\Repos\MyApp" -PlanPath "D:\...\PLAN_004_x.md" -Step 2 -RequiredGate tests_run
.\scripts\validation\validate-session-gates.ps1 -RepoPath "D:\Source\Repos\MyApp" -PlanPath "D:\...\docs\documentation-plan\plan.md" -RequiredGate step_confirmed
```

`-PlanPath` must exist and resolve under `-RepoPath` or under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/` (global classic).

Exit 0 = gate approved; exit 1 = blocked.

## Integration

| Consumer | Use |
|----------|-----|
| All skills | Step -1 gate check before Write/Shell |
| `sdd-develop` / `document-implement` / O3 children | Develop session scoped by plan path (or PLAN+step) |
| `rules/guardrails.mdc` | References this file |
| `rules/context-management.mdc` | Complements session gates |
