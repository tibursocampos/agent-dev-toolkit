## Update protocol (adt-document-implement skill)

After each completed step, `adt-document-implement` updates `docs/documentation-plan/plan.md`: status, progress bar, **Next step** line, and checked deliverables.

---

## Context management

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

- After overview + plan draft: checkpoint
Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

Pause message includes: `docs/documentation-plan/plan.md` path, steps completed, next step id.

---

## Relationship to SDD

| Skill | Use |
|-------|-----|
| `plan` / `adt-sdd-develop` | Feature delivery PRD/PLAN - `PRD/`, `PLAN/`, or `{{SDD_ROOT}}/<repo-id>/` per `STORAGE.md` |
| `adt-document-plan` | Cross-cutting documentation strategy - output `docs/documentation-plan/plan.md` only |
| `adt-document-implement` | Executes one step of `docs/documentation-plan/plan.md` (new file ≈ one step; update ≈ coalesced; spawn on large new/adt-refactor) |

Do **not** read or write SDD `PLAN/PLAN_*.md` when executing `adt-document-plan` / `adt-document-implement`. Do **not** read `docs/documentation-plan/plan.md` when executing SDD `adt-sdd-plan` / `adt-sdd-develop`.
