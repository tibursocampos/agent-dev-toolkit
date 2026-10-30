## TASKS complexity policy

| FEATURE **Complexity** | Behavior |
|------------------------|----------|
| `trivial` (small) | Do not write `REFINE/tasks.md`. Report that the plan uses one step |
| `medium` or `complex` | Write the checklist before `sdd-plan`. The caller is `orchestrate-deliver` after PRD contestation, or `/split-story-checklist` when `sdd-plan` stopped because the file was missing. `sdd-plan` does not write this file |

Align with `CHANGE-CONTRACT.md`. Brownfield CHANGE is owned by O2 / `sdd-spec`, not this skill.

---

## Context management

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.
