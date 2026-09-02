# electron-developer — scope

## When to escalate to SDD

Recommend `sdd-spec` -> `sdd-plan` -> `sdd-develop` if two or more apply: main+renderer+packaging overhaul, auto-update pipeline, cross-repo impact, 10+ files, or existing approved PLAN.

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to renderer UI; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Renderer stack (orchestration)

Detect renderer framework from `package.json`:

| Dependency | Lazy-load guidelines |
|------------|---------------------|
| `react` | `react-guidelines/` |
| `vue` | `vue-guidelines/` |
| Neither | `javascript-guidelines/`, `html-css-guidelines/` |

**Stay in `electron-developer` identity** - load stack guidelines for UI patterns only; do not switch to `react-developer` / `vue-developer`.
