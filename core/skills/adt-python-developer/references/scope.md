# adt-python-developer — scope

## When to prefer SDD instead

Recommend `/adt-sdd-spec` -> `adt-sdd-plan` -> `adt-sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ packages/layers (API, services, persistence, workers) across many modules |
| Database | New or altered schema / Alembic (or equivalent) migrations |
| Repos | Backend and another repo or service |
| Integrations | New messaging, external APIs, or consumers |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `adt-sdd-develop` |
