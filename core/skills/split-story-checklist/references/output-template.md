## Output template (preferred: feature story)

`features/NNN-slug/USnn/REFINE/tasks.md`:

Rows are **SMART tasks** under this story only — never promote a file/class/script step into a new US/TS (`anti-task-shatter.md` / RN01).

**REQ-012:** Do **not** put `item_type`, **Tipo**, or type exact-set enums in this file. Classification lives only on `STORY.md` (`references/type-classification.md`). **Source** may cite the portable STORY path.

```markdown
# Implementation tasks: [title]

| Field | Value |
|-------|--------|
| **Source** | features/.../STORY.md \| docs/backlog/<slug>.md \| chat |
| **Doc language** | pt-BR \| English |
| **Repository** | [name] |
| **Progress** | 0/N groups |
| **Altitude** | SMART tasks (not US-per-file) |

## Summary

| Group | Steps | Wave | Status |
|-------|-------|------|--------|
| Implement [Group 1] | 1-3 | 0 | Pending |
| Implement [Group 2] | 4-5 | 1 | Pending |
| Tests - Backend | 6 | 2 | Pending |

---

Each group is one PLAN step. Do not add a step id the plan will not copy. Do not restate the design. Each box is one atomic action of that step.

## Implementation

### STEP 1 — S1: [outcome title]

☐ `PENDING` | **Wave:** 0 | **Parallel-safe with:** none

- [ ] **Action title**
  - Path: `existing/or/Proposed.cs` (`existing` or `proposed`)
  - Depends on: none
  - Test: assertion that closes this box
- [ ] **Next action in the same step**
  - Path: `...`
  - Depends on: the box above
  - Test: assertion or `none` when the step gate covers it

---

### STEP 2 — S2: [next outcome]

☐ `PENDING` | **Wave:** 1 | **Depends on:** S1

- [ ] **Action title**
  - Path: `...`
  - Depends on: S1
  - Test: assertion

---

When `sdd-develop` completes the step, mark that step's boxes `- [x]` and set the glyph to `☑`.

---

## Before PR (optional - neutral checklist)

- [ ] Build and targeted tests pass locally
- [ ] Acceptance criteria from story/backlog re-read
- [ ] PR description lists scope and test evidence
- [ ] No secrets or local paths in diff

---

## Execution order

**Critical path:** Wave 0 -> Wave 1 -> … -> Tests

**Parallel waves:** list step ids that may run together

**Next:** Group 1 - [name]

## SDD / Orchestrated Delivery handoff

```
/sdd-spec -> PRD contestation -> /split-story-checklist -> /sdd-plan -> /sdd-develop
```

or

```
/orchestrate-analyze
```

This file does **not** replace `features/.../PLAN/PLAN_*.md`.
This file does **not** create new US/TS items.
```

Shortcut path `docs/implementation-tasks/<slug>.md` (or legacy `docs/sdd-developation-tasks/`) uses the same body.

---
