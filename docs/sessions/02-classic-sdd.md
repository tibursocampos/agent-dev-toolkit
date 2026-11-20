# 02 — Classic SDD

Classic SDD is a standalone path for one feature with a clear direction. It does not require `adt-orchestrate-analyze`, FEATURE/STORY, or a Memory Bank. The shared contract is [`PIPELINE.md`](../../core/skills/_shared/sdd-artifacts/PIPELINE.md); each skill's `SKILL.md` and references own its detailed behavior.

## Flow

| Skill | Purpose | Handoff |
|-------|---------|---------|
| `adt-sdd-spec` | Define expected behavior, scope, acceptance, relevant contracts, and material questions in a PRD. | `adt-sdd-plan` |
| `adt-sdd-plan` | Turn the PRD or a sufficiently specified demand into an executable PLAN with dependencies, acceptance, validation, and one progress table. | Present the complete PLAN for one explicit approval before implementation. |
| `adt-sdd-develop` | Implement the approved PLAN using its chosen `step_by_step` or `continuous` cadence. | Stop after one step in step-by-step mode; in continuous mode advance through eligible steps until completion or a real blocker. |

Direct `adt-sdd-spec` and `adt-sdd-plan` invocations are supported. Drafting and saving the PRD/PLAN are preparation and do not need separate approvals. A direct planning call ends with handoff; it does not automatically begin implementation.

## PRD and PLAN content

Describe the intended result and material boundaries. Write new acceptance criteria in Given / When / Then and accept equivalent existing criteria. Apply the risk-specific content in the shared guidance as appropriate. Each PLAN step should give a fresh executor enough detail to locate the work, apply the agreed behavior and produce the expected evidence. [Authoring content](../../core/skills/_shared/sdd-artifacts/AUTHORING-CONTENT.md)

Start from the canonical PRD and PLAN templates. Their headings guide the artifact; equivalent existing sections can be preserved. Keep material decisions, risks, contracts, acceptance, and execution progress in the canonical artifacts. Use a separate `ANALYSIS/`, `ARCH/`, or `SEC/` note only when it provides a distinct durable evidence record; these notes do not create another approval or progress gate.

The PLAN owns implementation sequence, dependencies, acceptance, validation evidence, blockers, and next action. It contains one canonical progress table. `adt-split-story-checklist` may help with independent backlog decomposition, but `TASKS.md` and `REFINE/tasks.md` are optional and never prerequisites for planning.

## Questions and evidence

Resolve an unanswered question before implementation only when it affects behavior, acceptance, scope, required access, or an implementation choice. Name the affected work; unrelated work may continue. Reuse relevant evidence and older artifacts when available, but do not require CONTINUITY, CHANGE, or TASKS, and do not convert or delete historical files.

## Implementation and closeout

Before each step, verify the approved PLAN, dependency eligibility, scope, acceptance, and relevant evidence. Do not require `step_confirmed`, `tests_run`, SESSION resets, or claims to authorize Classic work. Record step state, evidence/validation, and blocker or next action in the single PLAN table. Group validation when it gives clearer evidence than testing after every step.

The live progress table is a chat projection owned by the direct skill or its coordinating parent. A delegated result is checked against the PLAN acceptance and relevant evidence before the owner redraws the complete table. A receipt alone does not prove completion.

At scope close, run the PLAN-required validation and one substantive review. Reuse still-current evidence and rerun only checks invalidated by corrections. Commit, push, PR, installation, and publication are separate actions that require their own authorization.

For canonical paths, cadence and authorization boundaries, see [`PIPELINE.md`](../../core/skills/_shared/sdd-artifacts/PIPELINE.md); for the live table owner and display points, see [`LIVE-STAGE-TABLE.md`](../../core/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md).
