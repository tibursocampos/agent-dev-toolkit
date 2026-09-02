## PLAN-LEDGER (REQ-002 / CA2)

Canonical contract: `skills/_shared/sdd-artifacts/PLAN-LEDGER-CONTRACT.md` (`PLAN-LEDGER-CONTRACT`).

When authoring or updating a PLAN that will run under parallel O3 / multi-child develop:

1. **Cite** the contract path — do **not** paste claim JSON or ledger schema into the PLAN body (PLAN magro).
2. Ensure step ids are stable integers matching `PASSO` / `STEP` headings so ledger `{N}` aligns with develop session `plan-{planHash}-step-{N}.json`.
3. Document (in Aceite / notes when relevant) that double-claim of the same step must fail audibly — enforcement: `scripts/ledger/Invoke-PlanLedgerClaim.ps1` + `scripts/validation/Assert-PlanLedgerContract.ps1`.

Do **not** invent a second claim SoT under `features/` or `.agent-trace/`. Ledger files live under the SDD sessions tree per the contract.

Selective retrieval: cite portable paths only; never dump full PRD or full `memory-bank/` (`SR-NO-FULL-DUMP`).
