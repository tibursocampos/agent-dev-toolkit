# Inventory gaps

Unchecked items mean the bank is incomplete for that topic. Use `- [ ] BLOCKING:` only when Step 0 must treat the bank as stale/incomplete.

## MVP coverage

- [x] `project-context.md` refreshed from README, CLI, CI and repository contracts.
- [x] `tech-stack.json` matches the detected PowerShell/Markdown stack and documentation tooling.
- [x] Architecture entry points and CI/release boundaries reviewed against current source.
- [x] Domain areas and terms are evidenced; no unsupported product domain was added.
- [x] Conventions aligned with README, AGENTS, catalog and validation contracts.
- [x] Known risks reconciled against current CI/release configuration and evidence limits.

## Phase 2 / rich contracts

Current reviewed inventory has no DDL/SQL migrations, OpenAPI/Swagger specification, or UI component map. These files are not required unless such source material is added or cited later.

- [x] `api-contracts.md` — not indicated by current sources.
- [x] `database-schema.md` — not indicated by current sources.
- [x] `component-catalog.md` — not indicated by current sources.

## Open gaps

- [ ] Configure `RELEASE_SYNC_APP_ID` and `RELEASE_SYNC_APP_PRIVATE_KEY` in GitHub Actions with the required narrow permissions; verify live token mint and ancestry reconciliation. No secret values are stored here.
- [ ] Run GitHub Actions for the final workflow changes on a PR to `develop`; local `validate-core` and docs build do not prove remote checks/ruleset integration.
- [ ] Confirm real host/provider external-access enforcement, production I/O, isolation/TOCTOU behavior, and the Windows case-sensitive-directory fixture; current evidence remains contract/fixture-only.

## Blocking

_(none)_

## Notes

Inventory is `ready` at hash `8aff168d2fe4178874796e16319d5e7c15d994e1bede413229116e70fa0b3fe3` (`138 source(s); stack: markdown, powershell`). The operator acknowledged the 20-source drift from the prior snapshot; the generated drift blocker was cleared and inventory rerun successfully. Remaining unchecked items are external follow-ups, not Memory Bank write blockers.
