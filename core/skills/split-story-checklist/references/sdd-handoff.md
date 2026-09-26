## Boundary: split-story-checklist vs plan vs O2

| Aspect | `split-story-checklist` | `sdd-plan` | `orchestrate-deliver` (O2) |
|--------|-------------------|------------|----------------------------|
| Input | Refined steps / STORY | PRD | Approved US/TS backlog |
| Output | Local checklist + **type exact-set on STORY only** (REQ-012) | `PLAN_*.md` under feature | PRD+PLAN per story (+ CHANGE when brownfield) |
| Granularity | Step ids, deps, and waves in `REFINE/tasks.md` | Copies those step ids into `PLAN_*.md`. Does not invent a second step size | Multi-story orchestration |
| Tracker | Never (Skip D / REQ-013: no ADO mutate) | Never | Never |

**type_classification:** resolve Bug \| User Story \| Technical Story before checklist Write; persist **Tipo** / `item_type` only on `STORY.md` — see `references/type-classification.md`. Checklist files must not fork that exact-set.

