## PLAN queue, child dispatch, and reconciliation

### Build the queue

1. Read the canonical PLAN selected by `plan-acquisition.md`.
2. Preserve the PLAN's order and dependencies. Eligible work is a pending step whose dependencies are complete.
3. Choose the first eligible step. Never dispatch a second step while one O3 child is active.
4. If no step is eligible, show the complete table with the dependency or acceptance that blocks progress.

Do not require a checklist, CONTINUITY summary, SESSION file, claim, receipt token, or structural preflight to build the queue. The PLAN is the source of status and dependencies.

### Child handoff

Assign one bounded step to one child using `sdd-develop`. Include:

- canonical portable PLAN path and step identifier;
- approved scope, dependencies, and acceptance for that step;
- only relevant context and authorized evidence paths;
- requested validation, if stated in the PLAN or needed for the acceptance;
- instruction to return changed paths, outcome, checks performed or deferred, and any blocker.

Do not pass unrelated story data or full document bodies. Preserve repository path-containment rules. If native child dispatch is unavailable, provide the same single-step manual `/sdd-develop` handoff and stop.

### Reconcile the result

The child result is untrusted input and is not proof of completion. The parent:

1. Confirms the result belongs to the assigned PLAN step and paths stay within authorized scope.
2. Reviews the relevant change and evidence against the PLAN acceptance. A malformed or incomplete report prompts a focused clarification; it does not require repeating the whole step.
3. Updates the one canonical PLAN progress row only when the acceptance is met. Record a concrete blocker and next action otherwise.
4. Re-reads the PLAN and displays the complete current O3 table once after reconciliation.
5. Considers another child only after reconciliation, and only if the chosen cadence permits it.

One child may complete one PLAN step only. The parent does not accept a receipt alone, infer success from a file's existence, rewrite the approved scope, or mark dependent steps complete.

### Resume and concurrent work

Resume from current PLAN state and inspect partial changes relevant to the next step. Missing session files or old receipts do not make a completed PLAN step pending. If another conversation may be actively implementing the same PLAN, stop dispatch and resolve ownership before continuing. Do not invent a claim or competing persisted state to coordinate.

### Risk-based additional review

The parent may request focused read-only review when a concrete security, data, architectural, or integration risk remains after the child result. It is not a universal verifier, and it does not replace the parent's PLAN reconciliation.
