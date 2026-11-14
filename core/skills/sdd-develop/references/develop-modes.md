# Develop pacing modes (`continuous` | `step_by_step`)

**REQ-009 / CA3 / CT3 (feature 007).** Mode ids: **`continuous`** \| **`step_by_step`**. Distinct from O3 queue modes `serial` \| `parallel` \| `manual` (`orchestrate-develop/references/execution-modes.md`). Distinct from **006 REQ-009** (`## Related` navigation).

**Language:** English mode ids. Operator chat follows the user chat language (`LANGUAGE.md`).

Portability: `LOCAL_ONLY` until commit and push both exist. `SHARED` only after both. Default pacing remains `step_by_step`. In `continuous`, the parent still shows the live table and the step summary for each step (the step summary is the full PLAN-step table plus the short result). It does not go silent between steps. The child still executes one step. The parent is who starts the next step.

Companions: `references/plan-acquisition.md`, `references/plan-contract.md`, `SESSION.md`, `PLAN-LEDGER-CONTRACT.md`.

---

## Purpose

Declare how the operator/orchestrator **paces** PLAN steps. For direct Classic SDD, the default remains one step and stop; a finite sequence requires explicit current authorization. ADT Delivery follows its own implementation skill and approved plan. Both modes **preserve**:

- **One PLAN step per gate scope**. Each scope records and resets its own gates before another begins.
- SESSION develop gates + PLAN-LEDGER claim SoT (006) — **no second SoT**

Resolve the execution route before pacing. A canonical PLAN plus an explicit step starts that step in the current `sdd-develop` session after dependency and confirmation gates; it never requires a new session. If the invocation omits a step or route, `plan-acquisition.md` asks manual-per-invocation vs O3. This route is separate from pacing and `preferences.json` `orchestrator_mode` (`always` | `adaptive`).

## Mode table

| Mode id | Default? | Direct `/sdd-develop` | O3 parent (`orchestrate-develop`) |
|---------|----------|----------------------|-----------------------------------|
| `step_by_step` | **Yes** | Explicitly requested eligible step → execute now, mark Complete → **STOP**; handoff invoke for Step N+1 only | Present queue; require **sim** before **each** spawn |
| `continuous` | No (opt-in) | Direct Classic: execute the explicitly authorized step, reset and stop unless a finite current authorization covers another step; before continuation, revalidate approval, inputs, dependencies, and gates. | After initial queue **sim**, the parent may spawn the next ready step only after receipt, session, claim, checkpoint, and queue reconciliation. The parent still shows `execution-display.md`: the full PLAN-step table plus the short result. It does not go silent between steps. **Each child still executes one step.** |

Unknown mode id → treat as `step_by_step` (document the fallback; do not invent silent third pacing mode).

## Where declared (first explicit wins)

1. Operator invoke / confirm: `continuous` \| `step_by_step` (pt-BR synonyms: `contínuo` / `passo a passo` map to these ids)
2. Feature `CONTINUITY.md` note `develop_mode: continuous|step_by_step` when present
3. Default **`step_by_step`**

Do **not** conflate with `preferences.json` `orchestrator_mode` (`always`|`adaptive`) or with `execution-modes` `serial|parallel|manual`.

## Hard rules (both modes)

1. One PLAN step per gate scope; never merge multiple PLAN steps into one direct develop scope or O3 child. A separately authorized continuous coordinator may open the next scope only after reset and full revalidation.
2. Persist `step_confirmed` via `Invoke-DevelopSessionGate.ps1`; claim via `Invoke-PlanLedgerClaim.ps1` when required — **no** inline session JSON mutation.
3. Evidence / TRACE verifiers stay sequential (**Verifier ≠ O3**).
4. Zero duration/effort estimates in pacing prompts or checkpoints (`references/plan-contract.md`).

## Chat tokens (observable)

```text
develop_mode: step_by_step | continuous
plan-acquisition: ok
next: STOP | continue only under the active finite authorization, after closing/resetting and revalidating this step's gate scope
```

## Checklist (manual)

- [ ] Both mode ids appear in this ref and are cited from `sdd-develop` + `orchestrate-develop` indexes
- [ ] Direct Classic defaults to one step; any continuation has finite current authorization and resets/revalidates every gate scope
- [ ] O3 retains one PLAN step per child and its receipt/session/claim/checkpoint/queue gates
- [ ] No policy sentence narrows all `continuous` cadence to O3 or says every next step requires a new chat
- [ ] Cross-link to `execution-modes.md` clarifies serial/parallel ≠ continuous/step_by_step

Switch `continuous` and `step_by_step` only when no step is `IN_PROGRESS` and the tree is still the tree recorded on the checkpoint.
