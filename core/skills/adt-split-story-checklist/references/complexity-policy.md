## Optional checklist use

`adt-split-story-checklist` is an independently invocable planning aid. Classic `adt-sdd-plan` and Orchestrated Delivery O2 can derive executable PLAN steps directly from the approved demand or PRD; neither requires `TASKS.md` or `REFINE/tasks.md` at any complexity.

Use the checklist when the operator requests it or when it provides distinct value for grouping already-refined steps. Complexity labels do not decide whether it is required, create a workflow gate, or block planning. When invoked, this skill remains the sole writer of its own checklist; `adt-sdd-plan` may consult it as optional context without copying or renumbering useful IDs and dependencies.

Do not require a `TASKS` file, a complexity source, PRD contestation, or an O2 gate to invoke this optional tool. Align any useful brownfield context with the PRD or PLAN; an existing CHANGE file is optional context.

---

## Context management

The owning workflow's canonical artifact remains the source of persisted progress; this optional tool does not add a separate progress or stop gate.
