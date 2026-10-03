# Project context

<!-- BEGIN GENERATED: inventory-summary -->
| Field | Value |
|-------|--------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-10-03T01:54:07.4768932Z |
| **Status** | ready |
| **Inventory hash** | `e6945fcf9ff1624d36f42fce412054838856a6b6d8f5518d1f219bf3f1469725` |
| **Primary stack signals** | markdown, powershell (125 sources) |
<!-- END GENERATED: inventory-summary -->

## Purpose

**agent-dev-toolkit** ships one portable core (skills, policy, router, SDD contracts) plus per-agent adapters that publish that core into host install roots. `scripts/toolkit.ps1` syncs, validates, and uninstalls. The default write destination is an in-repo fixture. Live profile writes require `-AllowUserHome`.

## Actors / users

- Operators who sync a supported agent and invoke skills by id.
- Maintainers who run core validation and fixture smokes.

## Boundaries

- In scope: `core/` (skills, policy, router, SDD contracts), `adapters/` (registry publish surfaces), CLI under `scripts/` (`toolkit.ps1`, `sync-agent.ps1`, `validate-agent.ps1`), in-repo install fixtures, and CI that runs validate-core plus fixture smokes.
- Out of scope: Spec Kit, uv, and specify as a runtime dependency; SQLite/FTS as a deliverable.

## Links

- README: `README.md`
- Router index: `core/router/AGENTS.md`
- Agent registry: `adapters/registry.json`
- Skills catalog: `core/skills/_shared/skills-catalog/CATALOG.md`

## Notes

Keep this file short. Details belong in `architecture.md` / `domain-knowledge.md`.
**No secrets** - env var names only.
