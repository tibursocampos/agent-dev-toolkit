## Preconditions checklist

- [ ] Gate check reported; user **sim** for this O3 run / next spawn
- [ ] Feature and/or PLAN path resolved (`STORAGE.md`, classic)
- [ ] **Step 0** Memory Bank Gate done (`auto`; explicit `skip-memory-bank` only to bypass)
- [ ] At least one `features/**/PLAN/PLAN_*.md` under story folders (or global `.../features/**/PLAN/`)
- [ ] Next step deps **Completed** / **Concluídos**
- [ ] Before the first child spawn, shared implementation DoR from `sdd-develop/references/plan-contract.md` passes: approved canonical PRD/PLAN; complete REQ→CA→step and step-acceptance mapping; declared validations; explicit dependencies and scope/OOS; no unresolved scope/implementation/acceptance decision; recorded readiness review with portable evidence
- [ ] For brownfield or impact-uncertain work, applicable `ANALYSIS/` and `ARCH/` evidence covers the first eligible step's affected areas, or a justified non-applicability is recorded; no material conflict or gap remains before first spawn
- [ ] Parent will **not** implement app code
- [ ] Child prompts include `memoryBankPath` (read-only, selective)

If no PLAN -> hand off to O2 / `sdd-plan`. If user prefers no orchestrator -> document manual `sdd-develop` and stop (Classic SDD: no memory-bank gate - CA7).

---

The shared DoR is evaluated once before the first child spawn, not once per
step. A missing, contradictory, or unverifiable item blocks queue creation and
all spawns: report the exact PRD/PLAN row or evidence gap and preserve the
affected step as `PENDING` (or its existing `BLOCKED` status). A green
clarification `READY` does not pass this implementation gate. Direct
`sdd-develop` uses the same checklist before its first implementation step;
per-step dependency and acceptance gates remain active throughout the queue.

## First-step brownfield evidence

Before spawning the first implementer for a brownfield or impact-uncertain
PLAN, read the applicable O1 `ANALYSIS/` and `ARCH/` artifacts required by
`ROSTER.md`. Compare their evidence-backed affected areas and relevant
components with the first eligible PLAN step's declared artifacts and scope.
An artifact's presence or a generic architecture summary alone does not prove
coverage. If the step targets an area not covered by the evidence, current code
contradicts a material finding, or a material gap remains, stop the first
spawn and request a focused analysis refresh; do not let the implementer infer
a replacement convention. When the feature context establishes that brownfield
analysis does not apply, record the reason instead of creating a stub.

### Coverage matrix and decision

Before deciding that coverage is sufficient, record one matrix row for each area or boundary that the first eligible step could affect. Derive candidate areas from that step's accepted behavior, declared artifacts, and relevant dependencies; do not add unrelated layers or tools.

| Field | Required value |
|-------|----------------|
| Area / boundary | The relevant repository area or technical boundary |
| Applicable | `YES` or `NO` for the first eligible step |
| Reason | Required when `Applicable=NO`; explain from the step's scope why the area cannot affect it |
| Evidence | Portable path plus symbol, section, or configuration key; required for `Applicable=YES` |
| Confidence | `CONFIRMED`, `INFERRED`, or `GAP` |
| Result | `COVERED`, `JUSTIFIED_N/A`, or `GAP` |

Use `COVERED` only for an applicable area supported by direct, representative evidence, or by an approved architecture decision when the area is genuinely new. Such a row has `Confidence=CONFIRMED` and an evidence path. `INFERRED` alone cannot establish coverage or authorize an implementation convention; record it as `GAP` until confirmed. `Applicable=NO` requires a scope-based reason and `Result=JUSTIFIED_N/A`. An applicable area without reliable evidence, with contradictory evidence, or with an unresolved material decision has `Result=GAP`.

A gap is material when resolving it could change accepted behavior, architecture or convention, security, data, API or routing, compatibility, tests, or the step's scope. If it cannot affect any of those for this step, mark the area not applicable and explain why; do not leave an unexplained gap. The overall result is `SUFFICIENT` only when every row is `COVERED` or `JUSTIFIED_N/A` and no contradiction or material decision remains. Any `GAP` blocks the first spawn and requires focused analysis; do not pass an incomplete matrix as sufficient.

When coverage is sufficient, pass the implementer the portable analysis paths and a short summary of only the findings relevant to its step. The implementer must read those sources and confirm that its exact target area is covered before editing. Keep the analysis human-readable and selectively retrieved; do not paste full artifacts into the child prompt. Perform this repository-level coverage check once before the first step, not before every intermediate step. Repeat it only when plan/source drift materially changes the affected area; the ordinary step-local code analysis still applies to every child.

At queue close, reconcile all required REQ/CA rows, completed-step acceptance,
declared validations and their results/evidence. Do not report the PLAN/US as
complete while any required row is unvalidated, evidence is missing, or a
mandatory requirement/blocking review finding remains unresolved. Use the
shared `delivery-baseline` in `sdd-develop/references/plan-contract.md`.

## Step 0 - Memory Bank Gate

| Check | Pass |
|-------|------|
| Bank path | Resolved `bank_root` (`STORAGE.md`) - not under `features/` |
| Fresh healthy bank | No rewrite; CONTINUITY status `fresh` |
| Refresh this run | CONTINUITY status `refreshed` |
| Children | Receive bank path; selective read; no bank dump |
| CONTINUITY vs bank | CONTINUITY = phase/handoff; bank = workspace map |
| 1-step contract | Unchanged - one child = one PLAN step |

## Step N - refresh-light (after code changes)

| Check | Pass |
|-------|------|
| Trigger | At least one child changed app files this O3 run |
| Mode | `memory-bank-init` **`refresh-light`** only (not full prose rewrite) |
| Confirm | pt-BR `sim` / `pular` / `cancelar` before write |
| Skip | No code changes, or user chose `pular` |
| CONTINUITY | Status `refreshed` when Step N ran |
