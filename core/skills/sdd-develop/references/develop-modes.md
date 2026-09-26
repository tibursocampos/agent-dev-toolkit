# Develop pacing modes (`continuous` | `step_by_step`)

**REQ-009 / CA3 / CT3 (feature 007).** Mode ids: **`continuous`** \| **`step_by_step`**. Distinct from O3 queue modes `serial` \| `parallel` \| `manual` (`orchestrate-develop/references/execution-modes.md`). Distinct from **006 REQ-009** (`## Related` navigation).

**Language:** English mode ids. Operator chat follows the user chat language (`LANGUAGE.md`).

Portability: `LOCAL_ONLY` until commit and push both exist. `SHARED` only after both. Default pacing remains `step_by_step`. In `continuous`, the parent still shows the live table and the step summary for each step. It does not go silent between steps. The child still executes one step. The parent is who starts the next step.

Companions: `references/plan-acquisition.md`, `references/plan-contract.md`, `SESSION.md`, `PLAN-LEDGER-CONTRACT.md`.

---

## Purpose

Declare how the operator/orchestrator **paces** PLAN steps. Both modes **preserve**:

- **One PLAN step per `sdd-develop` session scope** (guardrails / RNF-003)
- SESSION develop gates + PLAN-LEDGER claim SoT (006) — **no second SoT**

## Mode table

| Mode id | Default? | Direct `/sdd-develop` | O3 parent (`orchestrate-develop`) |
|---------|----------|----------------------|-----------------------------------|
| `step_by_step` | **Yes** | One step → mark Complete → **STOP**; handoff invoke for Step N+1 only | Present queue; require **sim** before **each** spawn |
| `continuous` | No (opt-in) | Still **exactly one** step this session → **STOP** after the report (hard). The parent may start the next ready step. The child does not. | After initial queue **sim**, the parent may spawn the next ready step. The parent still shows `execution-display.md` and the step summary. It does not go silent between steps. **each** child still one step |

Unknown mode id → treat as `step_by_step` (document the fallback; do not invent silent third pacing mode).

## Where declared (first explicit wins)

1. Operator invoke / confirm: `continuous` \| `step_by_step` (pt-BR synonyms: `contínuo` / `passo a passo` map to these ids)
2. Feature `CONTINUITY.md` note `develop_mode: continuous|step_by_step` when present
3. Default **`step_by_step`**

Do **not** conflate with `preferences.json` `orchestrator_mode` (`always`|`adaptive`) or with `execution-modes` `serial|parallel|manual`.

## Hard rules (both modes)

1. Child / direct develop: **one** PLAN step only; never multi-step in one develop scope.
2. Persist `step_confirmed` via `Invoke-DevelopSessionGate.ps1`; claim via `Invoke-PlanLedgerClaim.ps1` when required — **no** inline session JSON mutation.
3. Evidence / TRACE verifiers stay sequential (**Verifier ≠ O3**).
4. Zero duration/effort estimates in pacing prompts or checkpoints (`references/plan-contract.md`).

## Chat tokens (observable)

```text
develop_mode: step_by_step | continuous
plan-acquisition: ok
next: STOP | emit /sdd-develop ... Step N+1 (do not execute)
```

## CT3 checklist (manual)

- [ ] Both mode ids appear in this ref and are cited from `sdd-develop` + `orchestrate-develop` indexes
- [ ] `continuous` text does **not** authorize multi-step `sdd-develop`
- [ ] Cross-link to `execution-modes.md` clarifies serial/parallel ≠ continuous/step_by_step

Switch `continuous` and `step_by_step` only when no step is `IN_PROGRESS` and the tree is still the tree recorded on the checkpoint.
