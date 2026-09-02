# javascript-developer — scope

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ packages/layers (API, services, persistence, workers) across many modules |
| Database | New or altered schema / migrations |
| Repos | Backend and another repo or service |
| Integrations | New messaging, external APIs, or consumers |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists with `target_stack: html-css`, treat it as the acceptance source. Map to DOM/vanilla or light libs; do **not** reinterpret visual decisions.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.
