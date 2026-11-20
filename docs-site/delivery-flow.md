---
title: Choosing a delivery flow
---

# Choosing a delivery flow

The toolkit has three feature-delivery tracks. They are separate ways to work, not mandatory stages of one pipeline. Choose based on the shape of the demand and the artifact model you want.

| Track | Choose it when | Main artifacts | Approval before implementation |
|-------|---------------|----------------|--------------------------------|
| [Classic SDD](#classic-sdd) | One feature has a clear direction and can be planned directly. | A PRD and PLAN under the story folder in `features/NNN-slug/`. | Approve the complete PLAN once. |
| [Orchestrated Delivery](#orchestrated-delivery) | The feature needs multi-story analysis, brownfield investigation, or coordinated specialist work. | FEATURE/STORY context, then a PRD and PLAN for each selected story. | Approve the complete, explicitly listed PLAN set once. |
| [ADT Delivery](#adt-delivery) | You want an end-to-end flow that refines and plans a feature in one evolving plan. | One `features/NNN-slug/PLAN.md` through refinement, planning and implementation. | Approve the completed plan once. |

Backlog refinement and requirement review can prepare or challenge an item before a feature flow, but neither is a required stage. For a small isolated change, `adt-developer` or a stack skill is a separate shortcut.

## Classic SDD

Start with `adt-sdd-spec` → `adt-sdd-plan` → `adt-sdd-develop`. Classic is a direct path for one feature with a clear direction; it does not require O1, a Memory Bank, FEATURE/STORY files, a checklist, or specialist sidecars. The canonical story folder contains its PRD and PLAN. Planning may derive steps directly from a sufficiently specified demand, and the checklist is optional.

Implementation follows the approved PLAN's `step_by_step` or `continuous` cadence. The PLAN is the persisted implementation progress source. At closeout, complete the validation required by the PLAN and one substantive review; reuse current evidence and rerun only checks affected by a correction.

## Orchestrated Delivery

Start with `adt-orchestrate-analyze` → `adt-orchestrate-prepare` → optionally `adt-orchestrate-implement`. Use it when one feature benefits from O1 analysis and story coordination. O1 investigates concrete questions in proportion to the demand. O2 prepares a PRD and PLAN for each selected story and presents the complete listed PLAN set for one approval. O3 is optional and dispatches one PLAN step at a time, reconciling each result before the next.

Memory Bank and separate CONTINUITY, CHANGE, TASKS, ANALYSIS, ARCH, or SEC files are not default prerequisites. Use sidecars when they hold distinct useful evidence. A brownfield label alone does not require an architecture mirror. O3 closeout follows the approved PLAN's validation and one substantive review. Reuse current evidence; rerun only checks invalidated by a correction. Request a security review when a concrete risk calls for it.

Details: [Orchestrated Delivery](orchestrated-delivery.md).

## ADT Delivery

Start with `adt-delivery-flow` for end-to-end delivery, or invoke `adt-delivery-refine`, `adt-delivery-plan`, or `adt-delivery-implement` for a stage that is ready to run directly. This track keeps refinement, planning, approval, implementation progress, and closeout evidence in one evolving feature-root `PLAN.md`. The coordinator runs the stages in order; planning ends at one explicit approval before implementation. The flow has its own lifecycle and cadence, separate from Classic SDD and O1/O2/O3.

Implementation and closeout use the plan's accepted scope and validation evidence, followed by the existing `adt-code-review` skill. The flow does not commit, push, merge, or publish automatically.

## Shared boundaries

- Tracks are recommendations; Classic SDD does not require Orchestrated Delivery first.
- Only a material unanswered decision blocks the work it affects. Independent work may continue.
- Drafting and saving documents during an authorized analysis or planning stage is preparation. The approval boundary is the complete plan before implementation.
- Generic document diagnostics, exact headings, optional sidecars, and progress claims do not add approval gates.
- A correction triggers only the checks whose evidence it invalidates. Security, architecture, and data reviews are requested when a concrete risk warrants them, not as a universal per-step checklist.
