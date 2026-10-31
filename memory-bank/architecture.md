# Architecture

<!-- BEGIN GENERATED: inventory-summary -->
_Entry points and layout from the current inventory (2026-10-30T00:32:30Z; hash `8aff168d2fe4178874796e16319d5e7c15d994e1bede413229116e70fa0b3fe3`)._

| Signal | Path |
|--------|------|
| Operator CLI | `scripts/toolkit.ps1` |
| Sync orchestrator | `scripts/sync-agent.ps1` |
| Agent validator | `scripts/validate-agent.ps1` |
| Core validation suite | `scripts/validation/validate-core.ps1` |
| Memory Bank inventory | `scripts/inventory/Invoke-MemoryBankInventory.ps1` |
| Agent registry | `adapters/registry.json` |
| Skills catalog | `core/skills/_shared/skills-catalog/CATALOG.md` |
| Shared SDD contracts | `core/skills/_shared/sdd-artifacts/` |
| Router index | `core/router/AGENTS.md` |
| Adapter path guard | `adapters/_shared/GuardCommon.ps1` |
<!-- END GENERATED: inventory-summary -->

## Overview

The toolkit maintains an agent-neutral core and publishes host-specific layouts through adapters. The PowerShell CLI provides sync, validation, list, and uninstall operations. It defaults to an in-repository fixture; writes under a real user profile require `-AllowUserHome`.

## Layers

| Layer | Responsibility | Main paths |
|-------|----------------|------------|
| Core | Skills, policy, router, SDD contracts, catalog | `core/skills/`, `core/policy/`, `core/router/` |
| Adapters | Transform and publish core assets for each supported host | `adapters/<id>/`, `adapters/registry.json` |
| CLI | Operator menu and scripted actions | `scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1` |
| Validation | Assertions, fixtures, lab smokes, inventory and preflight checks | `scripts/validation/`, `scripts/inventory/` |
| Delivery automation | CI, docs build, release publication and ancestry reconciliation | `.github/workflows/` |

## Runtime and integration boundaries

- Adapter capabilities and supported hosts are declared in `adapters/registry.json`; host-specific behavior is implemented by each adapter.
- `scripts/toolkit.ps1` dispatches command-line validation scripts in child PowerShell processes so their top-level `exit` codes return to the menu rather than terminating it. Standalone scripts retain their normal exit-code behavior.
- Install roots are fixture-first. Profile writes require `-AllowUserHome`; local fixtures do not prove behavior in a live host.
- Copilot publishing supports `-Mode user|repo`. Codex user-scope skill mirroring is optional and off by default.
- Runtime preferences are initialized by `scripts/_lib/Initialize-SddPreferences.ps1`; missing preferences default `orchestrator_mode` to `adaptive`.
- The SDD storage source of truth is `core/skills/_shared/sdd-artifacts/STORAGE.md`; feature and Memory Bank storage share the resolved root.

## CI and release flow

- GitHub CI runs for pull requests to `develop`. The current source defines `validate` and `ci-ok` aggregate checks, adapter smokes, and `docs-strict`; the current local changes passed `validate-core.ps1` and a strict MkDocs build. A pushed feature branch without a PR has no run from this PR-triggered workflow.
- The release path is a `develop` to `master` PR merged with a merge commit only; `protect-release` allows only that method (changed 2026-10-31). Required `release-source` checks the head is `develop`. The release workflow publishes the tag/assets and opens a reconciliation PR to bring the promoted commit into `develop`.
- Recovery uses `workflow_dispatch` on `master`/`main` with `reconcile_only=true` and no version input. It reconciles the current promoted commit without creating another release. The GitHub App credentials `RELEASE_SYNC_APP_ID` and `RELEASE_SYNC_APP_PRIVATE_KEY` are configured and the App is installed on the repository; the preflight passed on 2026-10-31.
- Release and CI branch rules are configured in GitHub, not fully represented by files in this repository. Validate the actual required checks on a PR before treating a new workflow as remotely verified.

## External behavior and evidence limits

- `TOOLKIT_RELEASE_OWNER`, `TOOLKIT_RELEASE_REPO`, `TOOLKIT_RELEASE_ZIP_ASSET`, `TOOLKIT_RELEASE_CHECKSUM_ASSET`, and `TOOLKIT_SYNC_AGENT` are release-bootstrap environment variable names; never store their values here.
- `HERMES_HOME`, `ADT_ANTIGRAVITY_SUBAGENTS`, and `ADT_ANTIGRAVITY_PRODUCT_VERSION` are supported environment override/probe names.
- Classic external-access contracts and fixture tests establish local authorization rules, not provider-wide production I/O or host isolation. O3 receipt `files[]` is evidence-only and grants no Classic read/write access.

## Notes

Use `.inventory/gaps.md` for unresolved evidence and external dependencies. Do not infer live-host behavior from fixture validation.
