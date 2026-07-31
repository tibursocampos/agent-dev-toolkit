# Inventory gaps

Unchecked items mean the bank is incomplete for that topic.  
Use `- [ ] BLOCKING:` only when Step 0 must treat the bank as stale/incomplete.

## MVP coverage

- [ ] project-context filled from evidence
- [ ] tech-stack.json matches detected manifests
- [ ] architecture entry points verified
- [ ] domain-knowledge has at least one evidenced area (or N/A noted)
- [ ] conventions aligned with AGENTS/README
- [ ] known-risks reviewed once

## Phase 2 / optional rich contracts

List only when signals suggest they matter; do **not** create these files in MVP.

- [ ] api-contracts (OpenAPI/Swagger detected: {{OPENAPI_HINT}})
- [ ] database-schema (EF/Prisma/SQL migrations detected: {{DB_HINT}})
- [ ] component-catalog (design system / large UI kit detected: {{UI_HINT}})

## Blocking

<!-- Example: - [ ] BLOCKING: no README and no AGENTS - cannot establish purpose -->

## Notes

Gaps are regenerable under `.inventory/`. Prefer gitignoring `.inventory/` in the consumer.
