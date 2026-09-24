# Develop pacing modes (`continuous` | `step_by_step`)

**REQ-009 / CA3 / CT3 (feature 007).** Mode ids: **`continuous`** \| **`step_by_step`**. Distinct from O3 queue modes `serial` \| `parallel` \| `manual` (`orchestrate-develop/references/execution-modes.md`). Distinct from **006 REQ-009** (`## Related` navigation).

**Language:** English mode ids. Operator chat may be pt-BR.

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
| `continuous` | No (opt-in) | Still **exactly one** step this session → **STOP** after Complete (hard). Emit next-step invoke; **do not** start Step N+1 in-session | After initial queue **sim**, may spawn the next ready step when prior child receipt is OK without re-presenting the full queue; **each** child still one step + ledger claim + SESSION gate |

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
