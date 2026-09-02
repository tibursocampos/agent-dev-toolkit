## Execution modes (REQ-003 / CA3)

Canonical modes contract for `orchestrate-develop` queue / claim / parallelism.

**Language:** This guideline is **English**. Identifiers, mode ids, reason codes, and audit fields stay **English**. Operator chat may be **pt-BR**.

Companions: `references/step-queue-spawn.md`, `references/parallelism.md`, `skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md` (`PLAN-LEDGER-CONTRACT`), `skills/_shared/agents/SPAWN.md`.

---

## Purpose

Declare how O3 schedules PLAN steps and **honor** that declaration. A declared mode must drive claim, queue pick, and parallelism. Violations are **rejected or audited** — never silently ignored.

This is **operator governance** for Orchestrated Delivery O3. It does **not** replace SESSION gates (`step_confirmed` / `tests_run`) and does **not** pin child Task `model` ≠ parent (Eixo B/C).

## Declared modes

| Mode id | Default? | Queue | Ledger claim | Parallelism |
|---------|----------|-------|--------------|-------------|
| `serial` | **Yes** | One ready step in flight | Required before each spawn (`Invoke-PlanLedgerClaim`) | Parallel Task wave **forbidden** |
| `parallel` | No (opt-in) | Ready set may run concurrently | Required **per** child step | Allowed only when independence + user **sim** + distinct SESSION files; cap ≤4 (`SPAWN.md`) |
| `manual` | Fallback when `subagents=none` / Task unavailable | No Task spawn | Optional (operator may still claim) | Handoff to `/sdd-develop` only |

Unknown mode ids are **invalid** — reject with reason `mode_unknown` (do not invent a silent default other than documenting that unresolved preference → treat as `serial`).

## Where the mode is declared

Resolve in order (first explicit wins):

1. Operator choice in the current O3 confirm (`série` / `paralelo` / `manual`) after the parent presents the queue
2. Feature `CONTINUITY.md` field or note naming `execution_mode: serial|parallel|manual` when present
3. Default **`serial`**

`preferences.json` `orchestrator_mode` (`always`|`adaptive`) is **parent role**, not this table — do not conflate.

## Queue rules

1. Build the ready set from PLAN deps (`references/step-queue-spawn.md`).
2. Apply the active mode **before** spawn:
   - `serial` → pick exactly one ready step; refuse a multi-child wave
   - `parallel` → may pick up to ≤4 independent ready steps after **sim**; each child gets its own PLAN+step SESSION file
   - `manual` → do not Task-spawn; emit `/sdd-develop - <portable-plan-path> - Step N`
3. Never enqueue a step whose deps are not Completed.

## Claim rules (ledger integration)

Cite `PLAN-LEDGER-CONTRACT` — do **not** invent a second claim SoT.

| Mode | Rule |
|------|------|
| `serial` / `parallel` | Parent (or child before implement) **must** obtain an atomic claim for the step via `scripts/ledger/Invoke-PlanLedgerClaim.ps1` |
| Double-claim | Ledger reject is audible (`step_already_claimed`) — mode layer does not overwrite |
| `manual` | Claim optional; if used, same ledger contract applies |

## Parallelism rules

Reuse `references/parallelism.md` independence conditions. Mode gate adds:

| Active mode | Intent `parallel-spawn` |
|-------------|-------------------------|
| `serial` | **Reject** (`mode_parallel_forbidden`) + audit |
| `parallel` | Allow only if independence + **sim** + SESSION+ledger hold |
| `manual` | **Reject** (`mode_task_spawn_forbidden`) — use `manual-handoff` |

Evidence / TRACE verifiers remain **sequential** (**Verifier ≠ O3**) regardless of mode.

## Model-lock (transversal)

Modes **must not** pin child Task `model` to a slug different from the parent session. Omit `model` by default (`SUBAGENT-MODEL.md`). Depth/threads still follow `SPAWN.md` caps.

## Violation algorithm (observable)

1. Resolve declared mode (or default `serial`).
2. Classify intended action: `serial-spawn` | `parallel-spawn` | `manual-handoff`.
3. If invalid pairing → **do not spawn**. Append one audit line; exit non-zero with human-readable reason.
4. If valid Task spawn → require ledger claim success for each step before/at spawn boundary.
5. Never “best-effort ignore” a mode mismatch.

### Audit line (JSONL)

Under the SDD sessions ledger tree (same root as PLAN-LEDGER):

```text
{sessionsRoot}/{repo-hash}/ledger/execution-mode.audit.jsonl
```

```json
{
  "at": "2026-09-02T18:00:00Z",
  "event": "mode_rejected",
  "reason": "mode_parallel_forbidden",
  "mode": "serial",
  "intent": "parallel-spawn",
  "plan_path": "features/.../PLAN_....md",
  "step": 3
}
```

Stdout/stderr **must** include `reason`, `mode`, and `intent` so operators can verify CA3 without opening the audit file.

| Reason code | When |
|-------------|------|
| `mode_unknown` | Mode id not in the declared table |
| `mode_parallel_forbidden` | `serial` + `parallel-spawn` |
| `mode_task_spawn_forbidden` | `manual` + Task spawn intent |
| `mode_claim_required` | Allowed spawn but ledger claim missing/failed |
| `mode_ok` | Gate allowed (optional success log; not required in audit) |

## Structural enforcement

```text
.\scripts\ledger\Invoke-ExecutionModeGate.ps1 -Mode serial -Intent parallel-spawn -PlanPath <path> -Step N -SessionsRoot <temp>
.\scripts\validation\Assert-ExecutionModes.ps1
```

`Assert-ExecutionModes.ps1` must prove: this ref present + `orchestrate-develop` wire, serial rejects parallel intent with audit, and allowed spawn path integrates PLAN-LEDGER claim.

## Skill wiring

| Consumer | Load |
|----------|------|
| `orchestrate-develop` | This file via lazy-load / `reference.md` before queue (step 4) and parallelism (step 6) |
| O3 parent | Run mode gate before Task spawn; cite ledger contract |
| Children | Honor hold from ledger; one step only |

Selective retrieval: portable paths only; never dump full PRD or full `memory-bank/` (`SR-NO-FULL-DUMP`).
