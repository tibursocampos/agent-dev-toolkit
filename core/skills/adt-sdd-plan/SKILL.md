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
3. Clarify only decisions that prevent determining behavior, acceptance, scope, required access, or an implementation choice. Record the question or observable answer in the PLAN and identify affected work. Minor questions do not block independent planning.
4. Inspect every file, symbol and contract that the steps name, in this session, and reread them as needed to determine constraints, dependencies, risks, and suitable validation. Distinguish observed behavior from inference, proposal, and gap. Do not claim runtime behavior based on static evidence.
5. Derive outcome-based steps directly from the source. Group related work, represent real dependencies, and avoid file-only steps; include the exact contract excerpt that a step creates or changes; avoid speculative code (behavior the source does not show). `adt-split-story-checklist` is optional and remains independently invocable; use an existing linked checklist as context when useful, but do not require or create TASKS files.
6. Draft the PLAN using `templates/sdd/PLAN.md` and `references/template-usage.md`. Specify each step's preconditions, paths and symbols, intended changes, limits, error behavior, acceptance and expected evidence. Resolve material design choices before handing off affected steps. Keep dependencies and status in the single progress table.
7. Review the draft once for outcome coverage, dependencies, acceptance, material risks, validation, evidence limits, and scope. Fix substantive gaps. Use `references/self-review.md` and `references/challenge-vagueness.md` as guidance, not as separate authorization or formatting gates.
8. Save the PLAN in the canonical path. Preserve equivalent headings, numbering and wording when revising existing plans. Resolve substantive gaps directly.
9. For a direct invocation, present the complete plan for one explicit approval before implementation and end with a handoff. Do not start implementation automatically. For an O2 invocation, return the plan result to O2 for its single approval of the explicitly listed plan set.

## Invocation and display

- A directly invoked `adt-sdd-plan` owns one contextual progress table for its planning stages.
- When O2 invokes this skill internally, O2 remains the sole table owner. Represent this work in O2's story row.
- Use `LIVE-STAGE-TABLE.md` for owner and display points. Do not add a cumulative checkpoint or persist the chat table in the PLAN.

## Executable steps (mandatory)

Every step you write, check or execute must be executable by a less capable agent that reads only the step, the files it names and the decisions it cites. Full rule: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/EXECUTABLE-STEP.md`.
- Each step lists exact files (`modify` or `create`), exact symbols (with `path:line` read in this session, or `create`), a code block for each contract it creates or changes, numbered edits, a validation command with its filter, and acceptance IDs.
- Forbidden in approved steps: `a confirmar`, `TBD`, `se necessário`, `ajustar se`, `conforme adequado`, `decidir`, `escolher`, `etc.`, and a reference to another step's result without its excerpt.
- Planner: before presenting, check each step with the three questions in that file (files exist or `create`; symbols read or `create`; no forbidden word). Fix each `no` once.
- Implementer: before editing a step, check it with those three questions. If it fails, mark it BLOCKED with `plan defect: <what is missing>` and return to the planner. Do not guess. Business or architecture decisions go to the operator, once.

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
| Legacy PLAN diagnostic (explicit request only) | `references/validate-plan.md` |
| Selective evidence retrieval | `references/selective-retrieval.md` |
