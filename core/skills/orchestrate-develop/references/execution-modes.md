## Execution modes (REQ-003 / CA3)

Canonical modes contract for `orchestrate-develop` queue / claim / parallelism.

**Language:** This guideline is **English**. Identifiers, mode ids, reason codes, and audit fields stay **English**. Operator chat may be **pt-BR**.

Companions: `references/step-queue-spawn.md`, `references/parallelism.md`, `skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md` (`PLAN-LEDGER-CONTRACT`), `skills/_shared/agents/SPAWN.md`.

---

## Purpose

Declare how O3 schedules PLAN steps and **honor** that declaration. A declared mode must drive claim, queue pick, and parallelism. Violations are **rejected or audited** — never silently ignored.

This is **operator governance** for Orchestrated Delivery O3. It does **not** replace SESSION gates (`step_confirmed` / `tests_run`) and does **not** pin child Task `model` ≠ parent (Eixo B/C).

**Not develop pacing:** mode ids here are `serial` \| `parallel` \| `manual`. Pacing modes `continuous` \| `step_by_step` live in `references/develop-modes.md` (007 REQ-009) and compose with this table — they never waive one-step-per-child.

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
   - `manual` → do not Task-spawn; emit `/sdd-develop - <portable-plan-path> - Step N` with `invocation_context=orchestrated` and `claim_holder`; stop dispatch and await the operator's return with the receipt in this O3 parent flow
3. Never enqueue a step whose deps are not Completed.

### Manual handoff and host-mode gate

When `subagents=none` or the current host cannot spawn a Task, O3 uses the manual handoff for the next eligible PLAN step:

```text
/sdd-develop - <portable-plan-path> - Step N
```

Use the canonical portable PLAN path and the numeric step selected from the queue. Include `invocation_context=orchestrated`, the opaque `claim_holder`, and the scoped checklist input in the handoff. The handoff asks the operator to start a separate `sdd-develop` invocation; it does not execute the step or count as a child receipt. Stop dispatch without editing application files, running the child's validation, updating the step as completed, releasing the reservation, or claiming work was done. Resume this parent flow only when the operator returns with the invocation's receipt/checkpoint for reconciliation; without a confirmed return/stop, keep the claim held and the step blocked.

If the host is in Plan or Ask mode and that mode prevents the required writes or validation, state that Agent mode is required, show the handoff, and stop. The operator must switch modes and invoke the handoff; do not imply that the step was started or completed, and do not mutate its status or gates on the operator's behalf.

## Claim rules (ledger integration)

Cite `PLAN-LEDGER-CONTRACT` — do **not** invent a second claim SoT.

| Mode | Rule |
|------|------|
| `serial` / `parallel` | The O3 parent is the **single lifecycle owner** and **MUST** obtain exactly one atomic claim per step via the mode gate / `Invoke-PlanLedgerClaim.ps1` before spawn. A child must not claim or release that reservation. |
| Session gate | **MUST** set develop `step_confirmed` via `{{TOOLKIT_ROOT}}/scripts/session/Invoke-DevelopSessionGate.ps1` (`-File`) after operator **sim** — **MUST NOT** inline-mutate session JSON |
| Tests gate | After tests execute and results are reported, **MUST** persist `tests_run` with the same helper (`-Action tests-run`) and validate it before step completion; reset both gates with `-Action reset` on scope close |
| One Shell / step | Prefer one Shell approve chaining the session helper with the mode gate (`serial`/`parallel`) or direct claim helper (`manual`); these are distinct claim paths (`step-queue-spawn.md` § Canonical Shell boundary) |
| Allowlist (REQ-013) | Opt-in host allowlist of the two `-File` scripts only — **no** silent Shell auto-approve; path/secrets guards unchanged (`adapters/cursor/README.md` § Shell allowlist) |
| CT6 | Idempotent session skip (`step_confirmed` already true) **MUST NOT** waive the parent's missing claim — invoke the mode gate for `serial`/`parallel` or the helper for `manual`, exactly once |
| Double-claim | Ledger reject is audible (`step_already_claimed`) — mode layer does not overwrite |
| `manual` | The O3 parent must still reserve the step before handoff; it retains the claim until the separate `sdd-develop` invocation returns a reconciled receipt, then releases it. The handed-off invocation validates the parent's holder and must not claim/release. A direct invocation without an O3 parent reservation owns its own optional claim lifecycle. |

### Single-owner claim lifecycle (REQ-004 / CA4 / REQ-005 / CA5)

The PLAN-LEDGER claim is a pre-work reservation, not a child-owned gate. O3's parent acquires it once after the scoped SESSION gate and before spawn/manual handoff, records the opaque `holder` in the handoff, and retains ownership while the child may be running. In `serial` / `parallel`, the successful `Invoke-ExecutionModeGate.ps1` call performs that acquisition; do not follow it with a second `claim` call. In `manual`, the parent calls the claim helper once before emitting the handoff.

The child with `invocation_context=orchestrated` calls ledger `status` and proceeds only when `status=claimed` and `holder` matches the handoff. It must not invoke `claim` or `release`. Parent validates the receipt, SESSION gates, and durable PLAN checkpoint; only after child completion is established and sources reconcile does the parent release with the same holder. A spawn failure before execution, or cancellation with confirmed stop, is released by the parent after verifying the durable checkpoint. If execution may still be active, receipt is absent without confirmed cancellation, or durable sources conflict, retain the reservation and block advancement; do not release to enable a duplicate run. Preserve the release helper confirmation or a retention reason in the parent reconciliation summary. Direct `sdd-develop` without a parent-held reservation keeps its own claim lifecycle.

The PLAN checkpoint is durable step state, the receipt records the returned outcome, SESSION records scoped gates, the claim reserves concurrency, and `CONTINUITY.md` is parent-derived synthesis. None may be used as a substitute for another; unresolved disagreement blocks advancement and claim release.

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
4. If valid Task spawn → require session helper (`Invoke-DevelopSessionGate.ps1`) + exactly one parent-owned ledger claim success for each step before/at spawn boundary (CT6: gate already true does not skip the parent's claim).
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
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/ledger/Invoke-ExecutionModeGate.ps1" -Mode serial -Intent parallel-spawn -PlanPath <path> -Step N -SessionsRoot <temp>
.\scripts\validation\Assert-ExecutionModes.ps1
```

`Assert-ExecutionModes.ps1` must prove: this ref present + `orchestrate-develop` wire, serial rejects parallel intent with audit, and allowed spawn path integrates PLAN-LEDGER claim.

## Skill wiring

| Consumer | Load |
|----------|------|
| `orchestrate-develop` | This file via lazy-load / `reference.md` before queue (step 4) and parallelism (step 6) |
| O3 parent | Run mode gate before Task spawn; own claim acquisition, retention, reconciliation, and release; cite ledger contract |
| O3 children | Check matching parent claim with `status`; never reacquire or release; execute one step only |

Selective retrieval: portable paths only; never dump full PRD or full `memory-bank/` (`SR-NO-FULL-DUMP`).
