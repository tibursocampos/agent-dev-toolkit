## Update protocol (document-implement skill)

After each completed step, `document-implement` updates `docs/documentation-plan/plan.md`: status, progress bar, **Next step** line, and checked deliverables.

---

## Context management

Per `{{TOOLKIT_ROOT}}/rules/context-management.mdc`:

- After overview + plan draft: checkpoint
- When planning many domains in one session: save `plan.md` at ≥ 40% and hand off continuation

Pause message includes: `docs/documentation-plan/plan.md` path, steps completed, next step id.

---

## Relationship to SDD

| Skill | Use |
|-------|-----|
| `plan` / `sdd-develop` | Feature delivery PRD/PLAN - `PRD/`, `PLAN/`, or `{{SDD_ROOT}}/<repo-id>/` per `STORAGE.md` |
| `document-plan` | Cross-cutting documentation strategy - output `docs/documentation-plan/plan.md` only |
| `document-implement` | Executes one step of `docs/documentation-plan/plan.md` |

Do **not** read or write SDD `PLAN/PLAN_*.md` when executing `document-plan` / `document-implement`. Do **not** read `docs/documentation-plan/plan.md` when executing SDD `sdd-plan` / `sdd-develop`.
