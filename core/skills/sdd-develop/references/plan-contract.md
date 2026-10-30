# Plan-contract markers + delivery-baseline

Contract ids: **`plan-contract`** (markers) and **`delivery-baseline`** (observable done). zero duration / effort / story-point estimates in develop checkpoints and ledger.

**Language:** English marker keys where cited in contracts; PLAN body language follows the PLAN file.

Companions: `references/plan-acquisition.md`, `references/develop-modes.md`, `references/plan-update.md`, `SESSION.md`.

---

## plan-contract markers (observável)

When reading or updating a PLAN step, agents **must** recognize and honor these markers:

| Marker | Role |
|--------|------|
| Step heading | Lifecycle marker only; status token is authoritative |
| `**Status:**` `PENDING` \| `IN_PROGRESS` \| `BLOCKED` \| `COMPLETED` \| `SKIPPED` | Lifecycle (`status-legend.md`) |
| `**Deps:**` / dependency Completed gate | Ordering |
| `**Entregáveis:**` / Deliverables checkboxes | Scope of the step |
| `**Aceite:**` or `**Acceptance:**` lines citing `REQ-NNN` / `CA` / `CT` | Acceptance binding. Either label counts |
| Header `**Progresso**` / `**Progress**` `N/M` + optional bar | Feature progress |
| `**Próximo passo:**` / `**Next step:**` | Handoff pointer |

Do **not** require or invent time/effort fields (`Time:`, `duration`, `effort`, `story points`, `~N min`, token-budget-as-SLA) as part of this contract.

## delivery-baseline (observável)

### Implementation Definition of Ready (DoR) — direct and O3

Before the first implementation step of a PLAN, both direct `sdd-develop` and
O3 `orchestrate-develop` evaluate the same DoR. O3 performs this check before
the first child spawn; direct execution performs it before implementing the
first step. Later steps do not repeat the PLAN-level gate, but still require
their own completed dependencies and step acceptance.

The DoR passes only when all of these are observable in the approved PRD/PLAN:

1. The canonical PRD and PLAN are approved and their paths are resolved.
2. Every in-scope PRD REQ maps to a verifiable CA and one or more PLAN steps;
   each step has acceptance text tied to its REQ/CA.
3. Every step names its applicable validation (test, build, structural check,
   or justified non-applicability), explicit dependencies, and scope/OOS source.
4. Dependencies are valid and no unanswered decision can change scope,
   implementation, or acceptance.
5. The PLAN records a review result and portable supporting evidence for the
   readiness assessment. A planned check is not evidence that it passed.

If any item is absent, contradictory, or unverifiable, stop before the first
implementation step, name the exact missing artifact/row, and leave the step
`PENDING` (or preserve an existing `BLOCKED` status). `READY` only closes
clarification questions; it never substitutes for this DoR. See the shared
check in `orchestrate-develop/references/preconditions.md`.

The PLAN DoR is shared, but context-specific inputs remain distinct:

- `direct`: the approved canonical PLAN and its REQ/CA-bound acceptance,
  dependencies, and declared validations are sufficient execution inputs.
  `REFINE/tasks.md` is not required or created. A checklist is considered only
  when the current invocation explicitly adopts it and its PLAN relationship is
  explicit and consistent.
- `orchestrated`: O3 must pass its preflight and retain the O1/O2-owned
  artifacts and checklist inputs required by its parent contract. The child
  uses only the parent's scoped paths/rows; missing or inconsistent required
  inputs block or return to O2. The direct rule is not a fallback for O3.

Both contexts keep the same approval, dependency, acceptance, session, and
validation meaning. `orchestrator_mode` and sibling files never change the
resolved `invocation_context`.

O3 relay receipts retain the canonical `done` | `blocked` | `failed` outcome
vocabulary. `COMPLETED` is a persisted PLAN lifecycle state, never a receipt
status; direct operator-facing reports identify their resolved
`invocation_context` without widening the O3 relay allowlist.

### Step and PLAN Definition of Done (DoD)

A step may be marked **`COMPLETED`** only when **all** hold:

1. **plan-acquisition** succeeded for the canonical PLAN + step.
2. The step was marked `IN_PROGRESS` and the PLAN file was re-read before the edit.
3. Every acceptance item for **this** step is met, every declared applicable validation passed, and results/evidence are recorded in the step ledger or the declared evidence artifact. Acceptance without validation, a planned check without a result, or a missing required evidence reference is not completion. A failure sets the step to `BLOCKED` with the cause in the PLAN. Dependents stay `PENDING`. Resume a `BLOCKED` step only when the recorded block is gone from the file.
4. Targeted build/tests for the step’s stack ran when the step claims code/test work.
5. Develop SESSION / ledger rules intact (one-step; no second SoT).
6. PLAN progress and the execution checkpoint updated per `plan-update.md`.

The PLAN/US may be closed as `COMPLETED` only after its DoD reconciles every
required REQ and CA to completed steps and recorded implementation/test
evidence, all required validations have passed, and no unresolved mandatory
requirement or blocking review finding remains. Record skipped or
non-applicable checks with their rationale; never infer success from `READY`,
an empty finding list, or an acceptance statement alone.

### Validation and closure states

Keep these result tokens separate from PLAN/step lifecycle and human approval:

| Result | Meaning | Closure effect |
|--------|---------|----------------|
| `PLANNED` | Check named for future execution | No evidence; cannot pass acceptance or close a step |
| `PASS` | Applicable check executed/reviewed against the current target and evidence recorded | May satisfy only the mapped criterion and boundary |
| `FAIL` | Applicable check executed and failed | Blocks the mapped criterion and its dependent closure |
| `SKIPPED` | Check not run, explicitly deferred, or declared non-applicable with a reason | Never equals `PASS`; a required or deferred check remains pending. A declared non-applicable check is non-blocking only when the PLAN permits it and acceptance has sufficient distinct evidence |
| unknown / conflict | No authoritative result, or persisted records disagree | Blocks the owner transition until reconciled |

`COMPLETED` requires every acceptance item plus a recorded `PASS` for each
applicable required validation. A step marked `SKIPPED` cannot count as a
completed step or as evidence for overall PLAN closure. A new or changed PLAN
may map its acceptance elsewhere only through its owner and explicit approval;
do not rewrite historical status in bulk.

Use the PLAN's behavior-level coverage decisions to select validation for this
step. BDD describes observable acceptance; it does not impose a new automated
test in every step. Apply TDD selectively when test-first feedback adds timely,
distinct evidence for a changed behavior, risk, or boundary. Reuse existing
coverage when it still proves the current behavior, and add or change a check
only when the planned primary proof is missing or stale. Follow the consumer's
runner, libraries, doubles/mocks, and test structure. Do not repeat the same
validation at every layer: test lower-layer behavior when it is distinct and
test composition when the combined path adds evidence.

A deferred check is pending, never a pass, and cannot satisfy an intermediate step's acceptance or approve that step. Its owner and checkpoint must be recorded. It may be assigned to the final test-consolidation step only when it does not gate the current step's acceptance; final consolidation maps applicable acceptance criteria to tests/evidence and runs all required checks before US/PLAN DoD. A check declared non-applicable needs a reason and enough distinct evidence to support acceptance. Do not remove tests without proving they add no unique coverage, and retain valid evidence unless a newer equivalent or stronger result for the same criterion on the current implementation explicitly supersedes it. Record the supersession reason and replacement; keep the old artifact.

No duration.

**Out of baseline (forbidden as Complete gates):** elapsed minutes, ideal hours, story points, “quick win”, or any duration/effort estimate.

## Forbidden estimate patterns (grep-friendly)

Do not add to PLAN Implementation notes, CONTINUITY checkpoints, SESSION, or ledger claim payloads:

- `duration`, `effort`, `story point`, `story-points`
- `Time:` / `ETA` / `~30 min` / `~45 min` as acceptance criteria
- Token-budget figures used as delivery SLA (token context pressure ≠ estimate)

Planning prose already present in a PLAN **Notas** from `sdd-plan` is not rewritten by this step unless the develop session owns that edit — **new** skill output must stay estimate-free.

## Skill wiring

| Consumer | Load |
|----------|------|
| `sdd-develop` | Before marking Completed (with `plan-update.md`) |
| `orchestrate-develop` | When presenting queue / accepting child receipt — judge Complete via delivery-baseline, not clocks |

## Checklist

- [ ] Markers table present
- [ ] `delivery-baseline` named and conditions listed
- [ ] Explicit zero-estimates rule
- [ ] No weakening of one-step / SESSION / ledger
