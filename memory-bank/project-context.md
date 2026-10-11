Language: English

# Project context

<!-- BEGIN GENERATED: inventory-summary -->
| Field | Value |
|-------|-------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-10-11T15:39:55.7054431Z |
| **Status** | ready |
| **Inventory hash** | `91917befd5e9f11969dfafe8ec2c2f7f35722c4998b8b50d1ea8c1b8d41e583c` |
| **Primary stack signals** | 133 source(s); stack: markdown, powershell |
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
