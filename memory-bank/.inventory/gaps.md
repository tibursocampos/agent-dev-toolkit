# Inventory gaps

Unchecked items mean the bank is incomplete for that topic.
Use `- [ ] BLOCKING:` only when Step 0 must treat the bank as stale/incomplete.

## MVP coverage

- [x] project-context filled from evidence
- [x] tech-stack.json matches detected manifests (markdown, powershell)
- [x] architecture entry points verified
- [x] domain-knowledge has at least one evidenced area (or N/A noted)
- [x] conventions aligned with AGENTS/README
- [x] known-risks reviewed once

## Phase 2 / rich contracts

When Prior/cited content already has DDL, OpenAPI, or a UI component map, the matching file is **BLOCKING** (write/promote it, or `- [ ] BLOCKING:` until written).

- [x] api-contracts (OpenAPI/Swagger detected: no)
- [x] database-schema (EF/Prisma/SQL migrations detected: no)
- [x] component-catalog (design system / large UI kit detected: no)

## Blocking

_(none)_

## Notes

Refresh 2026-10-09. Inventory `status=ready`, hash `c97a99d739c2692581e2bec63cfc6f1b895834b45e5db88e21b03fd72fcdfea6`. Synthesis roles: `repo_analyst`, `architect`, `security`.

- [ ] `features/012-multiprovider-toolkit-corrections/` has story PRDs and `00-INDICE-E-DECISOES.md` and no `FEATURE.md`.
- [ ] `features/013-code-review-improvements/` has `CONTINUITY.md` and story PRDs and no `FEATURE.md`.
