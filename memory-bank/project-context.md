Language: English

# Project context

<!-- BEGIN GENERATED: inventory-summary -->
| Field | Value |
|-------|-------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-11-06T09:34:13.5699436Z |
| **Status** | ready |
| **Inventory hash** | `9da86d44882663a19460d6c0f04c24b7d331fe44d1f005a66881ae51e8a10551` |
| **Primary stack signals** | 144 source(s); stack: markdown, powershell |
<!-- END GENERATED: inventory-summary -->

## Purpose

**agent-dev-toolkit** ships one portable core (skills, policy, router, SDD contracts) plus per-agent adapters that publish that core into host install roots. The core includes `adt-settings` for session-wide subagent model and effort selection, with parent inheritance as the fallback. `scripts/toolkit.ps1` syncs, validates, and uninstalls. The default write destination is an in-repo fixture. Live profile writes require `-AllowUserHome`.

## Actors / users

- Operators who sync a supported agent and invoke skills by id.
- Maintainers who run core validation and fixture smokes.

## Boundaries

- In scope: `core/` (skills, policy, router, SDD contracts), `adapters/` (registry-backed host publishers), CLI and inventory tooling under `scripts/`, fixture-based installs, PowerShell contract assertions, and GitHub Actions for CI, docs, and releases. CI is PR-driven into `develop`; it includes aggregate checks `validate` and `ci-ok`, adapter smokes, and a strict docs build. Local validation does not prove behavior in a live agent home or host runtime.
- Out of scope: Spec Kit, uv, and specify as runtime dependencies; SQLite/FTS; production enforcement at external agent/provider boundaries.

## Links

- README: `README.md`
- Router index: `core/router/AGENTS.md`
- Agent registry: `adapters/registry.json`
- Skills catalog: `core/skills/_shared/skills-catalog/CATALOG.md`

## Notes

Keep this file short. Details belong in `architecture.md` / `domain-knowledge.md`.
**No secrets** - env var names only.
