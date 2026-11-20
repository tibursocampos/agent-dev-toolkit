## Boundary: adt-split-story-checklist vs plan vs O2

| Aspect | `adt-split-story-checklist` | `adt-sdd-plan` | `adt-orchestrate-prepare` (O2) |
|--------|-------------------|------------|----------------------------|
| Input | Refined steps / STORY | PRD | Approved US/TS backlog |
| Output | Local checklist + **type exact-set on STORY only** | `PLAN_*.md` under feature | PRD+PLAN per story (+ CHANGE when brownfield) |
| Granularity | One group per `STEP n`: path, dependency, test, checkbox. Does not restate the plan design | Copies those ids into the PLAN step packet. Does not invent a second step size and does not write `tasks.md` | After PRD contestation accepts the spec, runs this checklist when medium/complex, then `adt-sdd-plan` |
| Tracker | Never (Skip D / REQ-013: no tracker mutate) | Never | Never |

**type_classification:** resolve Bug \| User Story \| Technical Story before checklist Write; persist **Tipo** / `item_type` only on `STORY.md` — see `references/type-classification.md`. Checklist files must not fork that exact-set.

