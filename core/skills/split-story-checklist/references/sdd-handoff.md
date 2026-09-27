## Boundary: split-story-checklist vs plan vs O2

| Aspect | `split-story-checklist` | `sdd-plan` | `orchestrate-deliver` (O2) |
|--------|-------------------|------------|----------------------------|
| Input | Refined steps / STORY | PRD | Approved US/TS backlog |
| Output | Local checklist + **type exact-set on STORY only** (REQ-012) | `PLAN_*.md` under feature | PRD+PLAN per story (+ CHANGE when brownfield) |
| Granularity | One group per `STEP n`: path, dependency, test, checkbox. Does not restate the plan design | Copies those ids into the PLAN step packet. Does not invent a second step size and does not write `tasks.md` | After PRD contestation accepts the spec, runs this checklist when medium/complex, then `sdd-plan` |
| Tracker | Never (Skip D / REQ-013: no ADO mutate) | Never | Never |

**type_classification:** resolve Bug \| User Story \| Technical Story before checklist Write; persist **Tipo** / `item_type` only on `STORY.md` — see `references/type-classification.md`. Checklist files must not fork that exact-set.

