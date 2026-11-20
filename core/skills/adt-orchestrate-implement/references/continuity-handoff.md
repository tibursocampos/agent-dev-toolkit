## O3 handoff and stop conditions

The canonical PLAN carries implementation state. CONTINUITY, when present, is optional historical context; do not create or update it to mirror progress or to make a handoff valid.

### Stop and resume

Stop dispatch when:

- the requested PLAN scope is complete;
- a child reports a real blocker or required validation fails;
- a material scope, acceptance, access, or implementation decision is unresolved;
- another conversation may be implementing the same PLAN concurrently; or
- the user asks to stop.

State the affected work, factual evidence, and next action. Preserve the PLAN's actual state. On resume, re-read the PLAN and inspect relevant partial work. Do not repeat a completed step only because an old receipt or sidecar is missing.

If the host cannot dispatch a child, hand off the first eligible step as `/adt-sdd-develop - <portable-plan-path> - Step N - invocation_context=orchestrated` and stop. The manual executor returns evidence to the coordinator, which owns PLAN progress and closeout. The handoff is not evidence that implementation occurred.

### User-approved decisions

Carry a concise pointer to a decision only when it constrains the assigned step or requested review. Use the approved PLAN or PRD path and relevant section/criterion when available. Do not copy full conversation or create a second decision ledger. If a proposed correction changes approved scope or acceptance, stop for a decision before implementation.

### Requested closeout

Run closeout only when it is part of the requested scope. Complete PLAN-required validation and one substantive review. Reuse current results for the same stack, command, and unchanged working tree; do not rerun a full suite only because review also checks tests. After an in-scope correction, rerun only affected checks; record when no rerun was needed. Request focused specialists only for concrete risks. Keep closeout activities in O3's contextual progress table and record evidence/limits in the PLAN; do not create a second table or CONTINUITY progress state. Do not commit, push, publish, or install unless separately authorized.

The table owner redraws the complete current table after each meaningful closeout result and at handoff. If a change invalidates prior evidence, identify the affected check and re-run only the verification needed by the shared closeout contract.
