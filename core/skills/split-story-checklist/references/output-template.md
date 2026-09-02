## Output template (preferred: feature story)

`features/NNN-slug/USnn/REFINE/tasks.md`:

Rows are **SMART tasks** under this story only — never promote a file/class/script step into a new US/TS (`anti-task-shatter.md` / RN01).

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

## Implementation

### Group 1: [name]

**Steps covered:** 1-2 | **Wave:** 0 | **Parallel-safe with:** none

- [ ] **Step 1 - [title]**
  - Layer: [...]
  - Depends on: none
- [ ] **Step 2 - [title]**
  - Layer: [...]
  - Depends on: Step 1

---

## Tests

### Tests - Backend

**Steps covered:** 5 | **Wave:** 2

- [ ] **Step 5 - [title]**

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
/sdd-spec -> /sdd-plan -> /sdd-develop
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
