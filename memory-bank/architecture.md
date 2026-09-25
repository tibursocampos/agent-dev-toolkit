# Architecture

<!-- BEGIN GENERATED: inventory-summary -->
_Entry points and layout hints from inventory (2026-09-25T14:11:35.6866622Z; hash `c77bee05c991485a5392f3cdda52e220ae04ca390656cca797a1a05fdd34446d`)._

| Signal | Path |
|--------|------|
| CLI menu | `scripts/toolkit.ps1` |
| Sync orchestrator | `scripts/sync-agent.ps1` |
| Validate orchestrator | `scripts/validate-agent.ps1` |
| Core contract suite | `scripts/validation/validate-core.ps1` |
| Agent registry | `adapters/registry.json` |
| Skills | `core/skills/*/SKILL.md` |
| Policy | `core/policy/` |
| Router index | `core/router/AGENTS.md` |
| SDD storage contract | `core/sdd/STORAGE.md` |
<!-- END GENERATED: inventory-summary -->

## Overview

One agent-neutral core is published by per-agent adapters into each host install layout. The CLI (`scripts/toolkit.ps1`) is the operator entry for sync, validate, and uninstall. Default `InstallRoot` is an in-repo fixture. A live user-home write is opt-in via `-AllowUserHome`.

## Layers / modules

| Layer | Responsibility | Path hints |
|-------|----------------|------------|
| Core | Skills, policy, router, SDD contracts | `core/skills/`, `core/policy/`, `core/router/`, `core/sdd/` |
| Adapters | Map core into one agent install layout; registry capabilities | `adapters/<id>/`, `adapters/registry.json` |
| CLI | Menu and `-Action` flags: Sync, Validate, SyncAndValidate, ValidateCore, ListAgents, Uninstall, Backup | `scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1` |
| Validation | In-repo contract asserts and fixture smokes | `scripts/validation/` |

## Entry points

- `scripts/toolkit.ps1` — Smart Manager and scripted `-Action`.
- `scripts/sync-agent.ps1` — publish core for one registry agent.
- `scripts/validate-agent.ps1` — fixture smoke when `InstallRoot` is available.
- `scripts/validation/validate-core.ps1` — core suite with no user-home sync.

## Integration points

- Host install roots resolved per adapter. Live profile paths require `-AllowUserHome`.
- Copilot publish takes `-Mode user` or `-Mode repo`.
- Codex publish accepts optional `-UserScope` (mirrors skills under the user skills root; off by default).
- Release bootstrap reads env names only: `TOOLKIT_RELEASE_OWNER`, `TOOLKIT_RELEASE_REPO`, `TOOLKIT_RELEASE_ZIP_ASSET`, `TOOLKIT_RELEASE_CHECKSUM_ASSET`, `TOOLKIT_SYNC_AGENT`.
- Hermes home override name: `HERMES_HOME`.
- Antigravity subagent probe names: `ADT_ANTIGRAVITY_SUBAGENTS`, `ADT_ANTIGRAVITY_PRODUCT_VERSION`.

## Notes

Evidence-based only. Mark unknowns in `.inventory/gaps.md`.
**No secrets.**
