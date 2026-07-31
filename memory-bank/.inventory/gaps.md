# Inventory gaps

Unchecked items mean the bank is incomplete for that topic.
Use `- [ ] BLOCKING:` only when Step 0 must treat the bank as stale/incomplete.

## MVP coverage

- [x] project-context filled from evidence
- [x] tech-stack.json matches detected manifests (PowerShell + Markdown; no package manifests)
- [x] architecture entry points verified (toolkit / sync / validate / validate-core / CI)
- [x] domain-knowledge has at least one evidenced area (Core/Adapter/Formas/Tier 1 terms)
- [x] conventions aligned with AGENTS/README
- [x] known-risks reviewed (path safety Waves 1–8, uninstall stubs, OpenCode hooks, subagents probe, no features/ doc links)

## Phase 2 / optional rich contracts

- [ ] api-contracts (OpenAPI/Swagger detected: no)
- [ ] database-schema (EF/Prisma/SQL migrations detected: no)
- [ ] component-catalog (design system / large UI kit detected: no)

## Blocking

_(none)_

## Notes

Refresh 2026-07-31: inventory script absent in repo — manual sources.json. Cursor/Grok Claude-style split; InstallRoot `\\?\` / `\\.\` + managed prune containment. Do not invent secrets in the bank.
