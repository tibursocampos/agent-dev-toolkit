## Preconditions checklist

- [ ] Gate check reported; user **sim** for this O3 run / next spawn
- [ ] Feature and/or PLAN path resolved (`STORAGE.md`, classic)
- [ ] **Step 0** Memory Bank Gate done (`auto`; explicit `skip-memory-bank` only to bypass)
- [ ] At least one `features/**/PLAN/PLAN_*.md` under story folders (or global `.../features/**/PLAN/`)
- [ ] Next step deps **Completed** / **Concluídos**
- [ ] Before the first child spawn, shared implementation DoR from `sdd-develop/references/plan-contract.md` passes: approved canonical PRD/PLAN; complete REQ→CA→step and step-acceptance mapping; declared validations; explicit dependencies and scope/OOS; no unresolved scope/implementation/acceptance decision; recorded readiness review with portable evidence
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

At queue close, reconcile all required REQ/CA rows, completed-step acceptance,
declared validations and their results/evidence. Do not report the PLAN/US as
complete while any required row is unvalidated, evidence is missing, or a
mandatory requirement/blocking review finding remains unresolved. Use the
shared `delivery-baseline` in `sdd-develop/references/plan-contract.md`.

## Step 0 - Memory Bank Gate (CA4 / CT3)

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
