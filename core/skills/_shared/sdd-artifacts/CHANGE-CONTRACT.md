# Optional change context and task breakdown

`CHANGE.md` and `REFINE/tasks.md` are optional context artifacts. Classic SDD and Orchestrated Delivery do not require their creation, conversion, synchronization, validation, or deletion as a condition for planning or implementation.

## Brownfield context

When existing behavior matters, capture the relevant current behavior, intended change, and concrete risks in the PRD or PLAN. A separate `CHANGE.md` may help when the delta is substantial or needs its own traceable discussion. Its absence is not a blocker, including for work classified as brownfield.

Do not create an empty CHANGE stub. Do not overwrite or delete an existing CHANGE file simply because a new flow no longer requires it. If an existing note materially conflicts with the current canonical requirements or PLAN, resolve that concrete conflict before dependent implementation.

## Optional task checklist

`split-story-checklist` remains an independent, optional way to break down a STORY. Its output can inform the PLAN, but the PLAN owns the executable steps, dependencies, implementation state, evidence, and next action. `sdd-plan` may derive steps directly from the PRD without creating or synchronizing TASKS.

Existing task lists may be consulted when useful. They do not become a second source of implementation progress, and missing, stale, or differently named checklist entries do not block the PLAN by themselves.

## Scope retained

Other workflows may use CHANGE or task checklists when their own current, explicit contract requires them. This file defines no universal validation script, status protocol, or migration for those optional artifacts.
