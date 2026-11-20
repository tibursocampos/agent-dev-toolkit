# O1 specialist investigation

Use the shared `ROSTER.md` for role mapping and `SPAWN.md` for native-agent
availability, delegation, and fallback. O1 does not maintain a second role map.

## When to involve a specialist

First state the concrete question and why its answer could affect the outcome,
scope, acceptance, risk, access, or implementation. Select only the specialist
needed to answer it. Use the relevant API, persistence, worker or security block
in `skills/_shared/sdd-artifacts/AUTHORING-CONTENT.md` to scope the investigation.
A `needs_*` signal or brownfield/greenfield label alone
does not require a spawn, folder, or artifact.

Independent investigations may run in parallel within the shared cap. Each
specialist owns a bounded question and reports inspected source, what it
establishes, evidence limits, and impact on the story or proposed decision. Suggestions remain recommendations until the operator
chooses them. O1 reconciles specialist findings into FEATURE/STORY or a
separate ANALYSIS/ARCH/SEC record when useful.

If native subagents are unavailable, use the workflow's documented in-parent
fallback where permitted. Missing a specialist tool alone is not a reason to
fail O1. No specialist implements application code in O1.

## Return handling

Check the relevant artifact and evidence, not only the specialist's receipt.
Record material findings in the canonical outcome record; do not create
CONTINUITY as a receipt or progress mirror. Reconcile the result and redraw
O1's single live table per `LIVE-STAGE-TABLE.md`.
