Language: English

# Project context

<!-- BEGIN GENERATED: inventory-summary -->
| Field | Value |
|-------|--------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-10-09T22:01:32.3234953Z |
| **Status** | ready |
| **Inventory hash** | `c97a99d739c2692581e2bec63cfc6f1b895834b45e5db88e21b03fd72fcdfea6` |
| **Primary stack signals** | markdown, powershell (131 sources; 46 skills; 90 assert scripts) |
<!-- END GENERATED: inventory-summary -->

## Purpose

**agent-dev-toolkit** ships one portable core (skills, policy, router, SDD contracts) plus per-agent adapters that publish that core into host install roots. `scripts/toolkit.ps1` syncs, validates, and uninstalls. The default write destination is an in-repo fixture. Live profile writes require `-AllowUserHome`.

## Actors / users

- Operators who sync a supported agent and invoke skills by id.
- Maintainers who run core validation and fixture smokes.

## Boundaries

- In scope: `core/` (skills, policy, router, SDD contracts), `adapters/` (registry publish surfaces), CLI under `scripts/` (`toolkit.ps1`, `sync-agent.ps1`, `validate-agent.ps1`), in-repo install fixtures, and CI on pull requests to `develop` (`validate`, adapter smokes, `docs-strict`, gate `ci-ok`). The default `validate` job runs named asserts and an `-AllowUserHome` probe under a disposable profile. It does not run `validate-core` or sync a real user home.
- Out of scope: Spec Kit, uv, and specify as a runtime dependency; SQLite/FTS as a deliverable.

## Links

- README: `README.md`
- Router index: `core/router/AGENTS.md`
- Agent registry: `adapters/registry.json`
- Skills catalog: `core/skills/_shared/skills-catalog/CATALOG.md`

## Notes

Keep this file short. Details belong in `architecture.md` / `domain-knowledge.md`.
**No secrets** - env var names only.
