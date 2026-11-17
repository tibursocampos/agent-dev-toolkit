# Optional checklist context

`adt-split-story-checklist` is independently invocable. `adt-sdd-plan` does not require, create, edit, or validate a `TASKS.md` or `REFINE/tasks.md` file based on complexity.

When a PRD links a checklist or the operator provides its canonical path, consult it when it adds useful grouping, dependency, or implementation context. Existing IDs may be preserved when they remain useful. The PRD or authorized demand remains the source for scope and acceptance; the checklist does not silently change them.

If optional checklist content materially conflicts with the PRD or demand about scope, acceptance, or dependencies, identify the specific conflict and ask only for the decision needed to continue the affected work. A missing, incomplete, or differently formatted optional checklist is not a planning blocker. Do not invoke `adt-split-story-checklist` automatically.

| Situation | Handling |
|---|---|
| No checklist exists | Derive plan steps directly from the PRD or demand. |
| Checklist is linked or provided and consistent | Use relevant context; keep the plan executable and outcome-based. |
| Checklist conflicts with the source of scope | Surface the material conflict; do not silently promote checklist items into scope. |
| User asks to create or refine a checklist | Hand off to the independently invoked `adt-split-story-checklist` workflow. |

Checklist acquisition never creates a second approval, progress table, or persisted authorization state.
