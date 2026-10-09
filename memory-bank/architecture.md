# Architecture

<!-- BEGIN GENERATED: inventory-summary -->
_Entry points and layout hints from inventory (2026-10-09T22:01:32.3234953Z; hash `c97a99d739c2692581e2bec63cfc6f1b895834b45e5db88e21b03fd72fcdfea6`)._

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
| Shared path guard | `adapters/_shared/GuardCommon.ps1` |
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
- Published PowerShell hook JSON readers use `[Console]::OpenStandardInput()` first and `[Console]::In` only when that read is empty (`adapters/cursor/assets/hooks/_hook-common.ps1` and the same pattern on the other hook assets).
- Copilot agent publish keeps one `nome.agent.md` per catalog agent and drops the parallel `nome.md` (`adapters/copilot/Publish-CopilotAgents.ps1`).
- A missing `preferences.json` is created on first sync with `orchestrator_mode` `always` (`scripts/_lib/Initialize-SddPreferences.ps1`).
- Required pull-request check `ci-ok` needs `validate`, `validate-windows-adapter-smoke`, `validate-ubuntu`, `validate-ubuntu-adapter-smoke`, and `docs-strict` (`.github/workflows/validate-toolkit.yml`).

## Notes

Evidence-based only. Mark unknowns in `.inventory/gaps.md`.
**No secrets.**
