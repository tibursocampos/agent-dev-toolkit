# Integrated delivery document contract

Status: Stage 1 design contract. Prose language follows operator/repository language; paths and stable IDs remain portable.

## Document set

The default canonical set is one `REFINEMENT.md` per multi-unit feature and one `(USnn|TSnn)/PLAN.md` per executable unit and affected repository. A simple single-unit feature may use the unit plan as its only canonical document when it has no cross-unit decision/dependency, shared-file ordering, changed shared contract, or material decision that must govern more than that unit. A `NO_CHANGE` repository has a decision and evidence reference in the feature refinement, not an artificial plan.

No standalone `FEATURE.md`, `STORY.md`, `PRD/`, `REFINE/tasks.md`, `CRITERIA.md`, `CONTINUITY.md`, `ANALYSIS/`, `ARCH/`, or `SEC/` is created by default. A detailed attachment is permitted only under the ownership/consumer rule in `FLOW.md`; it does not become an alternate source of truth.

## Refinement content

The feature refinement contains:

1. Identity and declared inputs: portable path, stable source ID/revision or content hash, language.
2. Triage: complexity and material specialist signals with reasons.
3. Objective, scope, exclusions, current/target flow when relevant.
4. Decision register with stable `D-###`, status, question/answer, normative value, supersession, and affected unit/criterion IDs.
5. Acceptance criteria once, with stable `CA-###`, Given/When/Then, evidence source IDs, validation, and status.
6. Specialist findings and technical evidence as concise summaries with source, confidence, limitation, and affected IDs.
7. Risks, assumptions, unresolved questions, and owner.
8. Unit definitions, dependencies, affected repository disposition (`AFFECTED`/`NO_CHANGE`) and evidence, shared-file ownership and execution order.
9. Definition of done by criterion ID.
10. Approval state and review identity only in the single APPROVAL operational block, excluded from normative identity per `SCHEMAS.md` section 6.3.

## Unit plan content

Each unit/repository plan contains:

- unit and repository identity;
- approved requirement/criterion/decision IDs and identity for each declared material input;
- evidence links and limitations needed by the implementer;
- criterion-to-step-to-test traceability;
- stable step IDs prefixed by unit, such as `US01-S1`;
- one behavior outcome per step, target paths/symbols, dependencies, validation command/evidence, and risk/reversal;
- shared-file ownership and ordering when multiple plans in one repository overlap;
- explicit `NO_CHANGE` only in the refinement, not an implementation plan;
- operational progress, approval, per-step state, and checkpoint block.

## Source of truth and lifecycle

- A decision's normative value exists only in its decision register entry; other sections cite its ID.
- Acceptance criteria are defined once in the refinement, or in the plan for the simple single-unit case. Plans and receipts cite the ID and body hash.
- An amended decision supersedes its prior record; it does not erase or silently rewrite history.
- Operational progress changes do not alter content approval identity. Any change to approved normative content or a declared material input invalidates the affected approval/review and downstream dependents.
- A plan cannot renumber, split, merge, or silently rewrite adopted step IDs after execution starts.
- No full Q&A transcript, raw agent output, repeated PRD, checklist, or copy of feature decisions is embedded. Keep only decisions and evidence required to understand, approve, execute, and resume.

## Approval identity

The `identity` is the normative projection hash of the approved document (`SCHEMAS.md` section 4); the operational block is excluded. Declared material input tuples (portable identifier, immutable revision or recomputed content hash, role, and affected requirement/criterion/step IDs) are covered by the separate `input_identity`, and an approval binds both. The validator recalculates hashes; a declared hash is never trusted as proof. Identity depends on the document kind: a declared `REFINEMENT.md` or unit `PLAN.md` input is identified by its normative identity, and any other file by the SHA-256 of its raw bytes (`SCHEMAS.md` section 10.2). External sources cited by alias (`alias:<name>` paths and `source` kinds) are identified as defined in `SCHEMAS.md` section 10.3.

Before feature approval, plan approval, implementation, and resume, verify each tuple. Missing, changed, ambiguous, or unverifiable inputs block the affected scope. Reconcile impact; obtain fresh review and explicit approval for affected content. Unreferenced files do not invalidate approval merely because they were read. Hash normalization, the normative projection, and the marker grammar are specified in `SCHEMAS.md` (sections 1 and 4) and implemented in `scripts/_lib/DeliveryGrammar.ps1`.

## Portability and privacy

Artifacts use portable repository-relative paths or approved aliases. Never write user-home paths, secrets, tokens, raw personal memories, or full private session transcripts. Evidence references distinguish `CONFIRMED`, `INFERRED`, and `GAP`; unavailable evidence is not fabricated.
