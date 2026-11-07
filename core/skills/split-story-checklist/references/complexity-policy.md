## TASKS complexity policy

Resolve `invocation_context` once and use only its canonical source. The source decides whether the checklist is required; do not infer complexity from a sibling artifact or story shape.

| Context | Complexity source | `trivial` | `medium` or `complex` |
|---------|-------------------|-----------|------------------------|
| Classic `direct` | Approved PRD `Complexidade` / `Complexity` | Do not write `REFINE/tasks.md`; `sdd-plan` can derive PLAN-native steps from PRD REQ/CA | Write the checklist before `sdd-plan`; when coordinated by `sdd-plan`, this skill remains the sole writer |
| Orchestrated Delivery O2 | FEATURE **Complexity** | No checklist required; preserve regular O2 gates | Write the checklist before `sdd-plan`, after PRD contestation, under the existing O2 gates |

If the selected source is missing, unsupported, or contradictory, stop and identify the context and source that must be resolved. Do not fall back from PRD to FEATURE in `direct`, or from FEATURE to PRD in O2. When a checklist is required, `split-story-checklist` is its only author and `sdd-plan` preserves the checklist's IDs and dependencies without editing or renumbering them.

Align with `CHANGE-CONTRACT.md`. Brownfield CHANGE is owned by O2 / `sdd-spec`, not this skill.

---

## Context management

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.
