---
name: adt-sdd-plan
description: Create an executable implementation PLAN from an existing PRD or sufficiently specified demand. Use when creating a plan or invoking /adt-sdd-plan.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It provides shared guardrails, session-use boundaries, and user-language rules. Then load the shared SDD `PIPELINE.md`, `STORAGE.md`, and `INVOCATION-CONTEXTS.md` as needed for the current work.

# Skill: adt-sdd-plan

## Outcome

Create or update one canonical PLAN in the user's artifact language and at the feature/story path defined by `STORAGE.md`. A PLAN describes an executable sequence, dependencies, acceptance, validation, evidence, and the single progress table used during implementation. Keep step descriptions complete enough to guide implementation without duplicating status in multiple places.

The PLAN may be derived from a canonical PRD or a sufficiently specified demand. A direct planning call may prepare and save its draft without a separate write approval. Present the complete PLAN for one explicit approval before implementation. If invoked inside O2, O2 owns the approval and progress display; this skill contributes its result without creating another table or approval interaction.

## Process

1. Resolve the invocation context once: direct or orchestrated. Do not infer O2 from sibling files. Reuse the context passed by the parent when present.
2. Resolve the authorized source: use a relevant PRD when available; otherwise use the demand and cited evidence. Read only relevant optional FEATURE, STORY, analysis, Memory Bank, CHANGE, CONTINUITY, or TASKS material. Missing or stale sidecars do not block planning.
3. Clarify only decisions that prevent determining behavior, acceptance, scope, required access, or an implementation choice. Identify affected work; minor questions do not block independent planning.
4. Inspect repository evidence only where needed to determine constraints, dependencies, risks, and suitable validation. Distinguish observed behavior from inference, proposal, and gap. Do not claim runtime behavior based on static evidence.
5. Derive outcome-based steps directly from the source. Group related work, represent real dependencies, and avoid file-only steps or speculative code detail. `adt-split-story-checklist` is optional and remains independently invocable; use an existing linked checklist as context when useful, but do not require or create TASKS files.
6. Draft the PLAN using `templates/sdd/PLAN.md`. Include a single execution progress table with step, dependencies, state, evidence/validation, and blocker/next action. Include current behavior, intended change, and concrete risks for brownfield work when relevant. Add specialized sections only when they help this request.
7. Review the draft once for outcome coverage, dependencies, acceptance, material risks, validation, evidence limits, and scope. Fix substantive gaps. Use `references/self-review.md` and `references/challenge-vagueness.md` as guidance, not as separate authorization or formatting gates.
8. Save the PLAN in the canonical path. Structural validators may be used as optional diagnostics; titles, numbering, section grammar, and validator output do not authorize or block the workflow by themselves. Resolve substantive gaps directly.
9. For a direct invocation, present the complete plan for one explicit approval before implementation and end with a handoff. Do not start implementation automatically. For an O2 invocation, return the plan result to O2 for its single approval of the explicitly listed plan set.

## Invocation and display

- A directly invoked `adt-sdd-plan` owns one contextual progress table for its planning stages.
- When O2 invokes this skill internally, O2 remains the sole table owner. Represent this work in O2's story row.
- Use `LIVE-STAGE-TABLE.md` for owner and display points. Do not add a cumulative checkpoint or persist the chat table in the PLAN.

## Boundaries

- Do not implement application or test code.
- Do not create or edit CONTINUITY, CHANGE, TASKS, FEATURE, or STORY solely to satisfy planning format or navigation.
- Preserve existing user artifacts; consult them only when relevant, and do not convert or delete them.
- Keep portable paths in written artifacts. Do not paste full PRD or Memory Bank bodies into the PLAN or handoff.
- A material change to an already approved implementation plan needs a new decision for the affected work.
- Do not commit, push, create a PR, publish, or install as a side effect of planning.

## References

| Need | Reference |
|---|---|
| Ordered workflow and table projection | `references/command.md` |
| Optional checklist context | `references/checklist-acquisition.md` |
| Outcome-based step sizing | `references/baby-step-sizing.md` |
| Single substantive review | `references/self-review.md` |
| Acceptance wording | `references/challenge-vagueness.md` |
| Template guidance | `references/template-usage.md` |
| Portable paths and PLAN location | `references/filename-numbering.md`, shared `STORAGE.md` |
| Optional validator diagnostics | `references/validate-plan.md` |
| Selective evidence retrieval | `references/selective-retrieval.md` |
