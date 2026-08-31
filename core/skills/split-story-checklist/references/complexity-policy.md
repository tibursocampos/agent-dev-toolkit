## TASKS complexity policy (REQ-004)

| FEATURE **Complexity** | Behavior |
|------------------------|----------|
| `trivial` (small) | **Do not** require TASKS / `REFINE/tasks.md` — skip Write unless operator insists |
| `medium` or `complex` | **Require** TASKS checklist before considering the breakdown done |

Align with `CHANGE-CONTRACT.md`. Brownfield CHANGE is owned by O2 / `sdd-spec`, not this skill.

---

## Context management

Per `context-management.mdc`: after writing a large checklist, checkpoint at ≥ 40% context; hand off continuation with file path and next group id.
