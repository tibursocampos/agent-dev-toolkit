Language: English

# Project context

<!-- BEGIN GENERATED: inventory-summary -->
| Field | Value |
|-------|--------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-10-09T13:51:08.7695991Z |
| **Status** | ready |
| **Inventory hash** | `678207ff40295caacb42ed788b10f1c2344ea398ffd22abbf426285782e8da07` |
| **Primary stack signals** | markdown, powershell (131 sources; 46 skills; 90 assert scripts) |
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
