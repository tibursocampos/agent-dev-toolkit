# Integrated unit plan format

One plan represents one accepted US or TS unit in one repository. The canonical path is `features/NNN-slug/(USnn|TSnn)/PLAN.md`, matching the unit's stable ID. Multiple repository plans share a `plan_set_id` and refer to the common feature refinement.

## Normative sections

1. **Identity and inputs:** unit ID/type, repository, plan-set ID where applicable, portable source IDs/revisions, and material input identity tuples.
   - **Plan dependencies:** a unit that depends on another plan declares it under `## Plan dependencies` with the predecessor's current identity and the needed steps, for example `Requires plan: features/NNN-slug/US01/PLAN.md identity=E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 steps=US01-S2`. Syntax and checks: `SCHEMAS.md` section 10.2.
2. **Purpose and boundaries:** approved objective, included/excluded scope, risks and assumptions. Cite decisions by ID; do not restate their normative value.
   - **Preconditions:** preparatory conditions the operator owns (for example the work branch or workspace state), each with an owner and how it is observed (checkpoint branch/head or the operator's confirmation). The plan lists them but never instructs the executor to run Git for them.
3. **Acceptance criteria:** include only for a simple unit without feature refinement. Otherwise cite the approved criterion IDs from `REFINEMENT.md` under `## Refinement references`.
   - **Refinement references:** a level-2 heading `## Refinement references` (optional `<n>. ` prefix) with one line per cited item: `Uses: <features/NNN-slug/REFINEMENT.md> <ID> hash=<64 UPPERCASE hex>`. Read the hash through `Get-DeliveryRefinementItems.ps1`. A `Uses:` line outside that heading is an error (`refinement_reference_invalid`). The referenced refinement must be approved with a current identity. Plans never restate a referenced item's value, and never declare a `### <ID> ...` heading for an ID defined in a referenced refinement (`plan_restates_refinement_item`).

   ```markdown
   ## Refinement references

   Uses: features/NNN-slug/REFINEMENT.md CA-001 hash=E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
   ```

4. **Traceability matrix:** each applicable criterion ID cited under `## Refinement references` maps to implementing step IDs and validation evidence. Every criterion must be implemented or explicitly dispositioned by the approved source.
5. **Shared files:** for a plan set, enumerate repository paths touched by each unit. Any intersection names owning unit, operation, ordering and merge rule. No unexplained overlap is permitted.
6. **Steps:** stable IDs `<UNIT>-S<n>` (for example `US01-S1`), one observable outcome per step, target paths/symbols, criterion IDs, predecessor IDs, validation method/evidence, risks and reversal. Declare steps machine-readably:
   - `## Steps` (level-2; an optional leading `<n>. ` is allowed) starts the list.
   - `### <id> <title>` (level-3) per step, where `<id>` matches `[A-Za-z0-9][A-Za-z0-9._-]*`.
   - Under each step heading: `Depends on: <id>[, <id>...]` or `Depends on: none`, then `Validation: <non-empty text>`.
   - Optional under each step heading: `Evidence: <name>[, <name>...]` lists the evidence this step persists, and `Needs evidence: <step-id>/<name>[, <step-id>/<name>...]` lists the evidence it consumes. Omit the line or use `none` when there is none.
     - Names are slugs matching `^[a-z0-9][a-z0-9-]*$`. `none` is not mixed with names.
     - Each line appears at most once per step.
     - Step ids must not contain `--`, and must be unique ignoring letter case.
     - A needed source must be a declared predecessor (transitive `Depends on:`) that declares the name.
     - Evidence must not contain secrets or credentials. The helper rejects known patterns and never echoes content.

   ```markdown
   ## Steps

   ### US01-S1 Add the parser
   Depends on: none
   Validation: parser unit tests pass
   Evidence: parser-fixtures

   ### US01-S2 Wire the parser into the command
   Depends on: US01-S1
   Validation: command integration test passes
   Needs evidence: US01-S1/parser-fixtures
   ```

   A unit outside Git declares its baseline as the Evidence of its first step.
7. **Validation and completion:** checks required by criteria, existing repository instructions and accepted risks; completion is evidenced, not inferred from status.
   - **Activation and rollback:** required for any step with an external effect or a dependence on a platform, API, SDK or integration. State the preconditions and their owners; the activation order; the validation, labelled as local syntax or fixture check, external tool check, or real integrated behavior check (local syntax or fixtures never prove publishability or integration); the rollback steps and their owner. Credentials, tokens and personal data must not be printed or stored in test output or receipts. No upload, publication or external call without separate authorization.
8. **Operational blocks:** progress, checkpoint, approval and one block per declared step using the exact marker grammar in `EXECUTION.md`. Each declared step has exactly one `STEP` block whose `depends_on` mirrors its declared `Depends on:` text.

## Multi-repository plan set

- Produce one executable plan for each repository with approved work.
- Keep shared feature decisions and criteria in the refinement. Each plan declares only the IDs and input hashes it consumes.
- A repository assessed as requiring no change is represented by an evidence-backed `NO_CHANGE` entry in the refinement, not by an empty plan.
- Identify cross-repository dependencies and order explicitly. Do not imply parallel execution where a dependency or shared contract prevents it. Cross-plan order and shared contracts are declared with `## Plan dependencies`, and selection-time checks cover only direct predecessors.
- Validate the complete set for missing units, duplicate IDs, unresolved dependencies, stale input identities and file intersections before any plan approval.

## Drafting and persistence

Use this outline to make the plan understandable and executable; do not run or wait on legacy SDD plan validators, scorecards, or content-quality checklists. The cold reader and critic review the stabilized draft. Before the preview is presented for approval, the draft must pass `{{TOOLKIT_ROOT}}/scripts/runtime/Test-DeliveryPlanPreflight.ps1` (run on the scratch snapshot at `features/NNN-slug/scratch/delivery-review/<name>.md` or on the written canonical file; the preflight accepts only those paths); failures block presenting the plan as ready. The preflight is not an approval and does not replace the cold review.

After that review, the operator's explicit approval of the displayed plan authorizes writing it to the canonical path. After writing, run the preflight again with `-ExpectedIdentity` set to the identity of the displayed content; a mismatch means the written file differs from what was approved. Keep operational blocks outside the normative content hash according to `EXECUTION.md`; do not change the defined projection ad hoc. Subsequent implementation and resume use this plan plus repository instructions and its declared dependencies, rather than reconstructing scope from competing Story/PRD/checklist copies.
