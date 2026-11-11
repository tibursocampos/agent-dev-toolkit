# Integrated unit plan format

One plan represents one accepted US or TS unit in one repository. The canonical path is `features/NNN-slug/(USnn|TSnn)/PLAN.md`, matching the unit's stable ID. Multiple repository plans share a `plan_set_id` and refer to the common feature refinement.

## Normative sections

1. **Identity and inputs:** unit ID/type, repository, plan-set ID where applicable, portable source IDs/revisions, and material input identity tuples.
2. **Purpose and boundaries:** approved objective, included/excluded scope, risks and assumptions. Cite decisions by ID; do not restate their normative value.
3. **Acceptance criteria:** include only for a simple unit without feature refinement. Otherwise reference the approved criterion IDs and body hashes from `REFINEMENT.md`.
4. **Traceability matrix:** each applicable criterion ID maps to implementing step IDs and validation evidence. Every criterion must be implemented or explicitly dispositioned by the approved source.
5. **Shared files:** for a plan set, enumerate repository paths touched by each unit. Any intersection names owning unit, operation, ordering and merge rule. No unexplained overlap is permitted.
6. **Steps:** stable IDs `<UNIT>-S<n>` (for example `US01-S1`), one observable outcome per step, target paths/symbols, criterion IDs, predecessor IDs, validation method/evidence, risks and reversal.
7. **Validation and completion:** checks required by criteria, existing repository instructions and accepted risks; completion is evidenced, not inferred from status.
8. **Operational blocks:** progress, checkpoint, approval and one block per declared step using the exact marker grammar in `EXECUTION.md`.

## Multi-repository plan set

- Produce one executable plan for each repository with approved work.
- Keep shared feature decisions and criteria in the refinement. Each plan declares only the IDs and input hashes it consumes.
- A repository assessed as requiring no change is represented by an evidence-backed `NO_CHANGE` entry in the refinement, not by an empty plan.
- Identify cross-repository dependencies and order explicitly. Do not imply parallel execution where a dependency or shared contract prevents it.
- Validate the complete set for missing units, duplicate IDs, unresolved dependencies, stale input identities and file intersections before any plan approval.

## Drafting and persistence

Use this outline to make the plan understandable and executable; do not run or wait on legacy SDD plan validators, scorecards, or content-quality checklists. The cold reader and critic review the stabilized draft. Any operational syntax needed for the execution ledger may be checked as part of saving/executing it, but it is not a second content-approval gate.

After that review, the operator's explicit approval of the displayed plan authorizes writing it to the canonical path. Keep operational blocks outside the normative content hash according to `EXECUTION.md`; do not change the defined projection ad hoc. Subsequent implementation and resume use this plan plus repository instructions and its declared dependencies, rather than reconstructing scope from competing Story/PRD/checklist copies.
