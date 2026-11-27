# Architecture

<!-- BEGIN GENERATED: inventory-summary -->
_Entry points and layout from the current inventory (2026-11-20T16:26:13.4871755Z; 144 source(s); stack: markdown, powershell; 52 skills; hash `fb07cb6220b3a73b1db80888222f17cc0e77c9aeb49d4654afa0b176d4450bcc`; status: ready)._

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
| Specialist prompt contracts | `core/skills/_shared/agents/prompts/`, `RECEIPT.md`, and `ROSTER.md` |
| Canonical SDD templates | `core/skills/_shared/templates/` |
| Router index | `core/router/AGENTS.md` |
| Session orchestration policy | `core/policy/orchestrator-session.md` |
| Host spawn contract | `docs/SPAWN.md` |
| Adapter path guard | `adapters/_shared/GuardCommon.ps1` |
| Shared adapter validation assertions | `scripts/_lib/AdapterChecks.ps1` |
| Host uninstallers | `adapters/grok/Uninstall-GrokToolkit.ps1`, `adapters/opencode/Uninstall-OpenCodeToolkit.ps1`, `adapters/openhands/Uninstall-OpenHandsToolkit.ps1` |
<!-- END GENERATED: inventory-summary -->

## Overview

The toolkit maintains an agent-neutral core and publishes host-specific layouts through adapters. The PowerShell CLI provides sync, validation, list, and uninstall operations. It defaults to an in-repository fixture; writes under a real user profile require `-AllowUserHome`.

## Feature delivery paths

The catalog defines three feature-delivery paths with separate artifact lifecycles. Classic SDD writes a PRD and PLAN for a story; Orchestrated Delivery coordinates selected stories, approves the complete PLAN set once, and dispatches O3 serially; ADT Delivery carries refinement through implementation in one evolving feature-root `PLAN.md` with its own approval and closeout. Backlog Refine is optional preparation. Memory Bank, continuity files, specialist sidecars, and generic validators are not universal flow prerequisites. See `core/skills/_shared/skills-catalog/CATALOG.md`, `core/skills/_shared/sdd-artifacts/PIPELINE.md`, and `core/skills/_shared/adt-delivery/`.

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
- Copilot publishing supports `-Mode user|repo`. Codex direct sync defaults to `Both` (home skills and plugin package); guided Sync also offers `Both`, `Local`, and `Plugin`. Optional `-UserScope` mirrors skills to a second personal root.
- Runtime preferences are initialized by `scripts/_lib/Initialize-SddPreferences.ps1`; missing preferences default `orchestrator_mode` to `adaptive`.
- `core/skills/adt-settings/SKILL.md` defines session-wide subagent model and effort choice; omitted adapter overrides inherit the parent selection. This documents configuration behavior, while host runtime application still requires provider-specific evidence.
- Hermes uninstall reports `KeyedOnly=true` and `WholesaleWipe=false` for its bounded toolkit-owned removal. `scripts/_lib/AdapterChecks.ps1` checks the folded policy and Copilot publish-mode install-root checks; contract assertions do not prove live-host behavior.
- Each `Publish-Hooks` returns a `HookActivation` (`manual`, `automatic`, `unavailable`, or `blocked`); sync prints it per adapter. A hook publish failure does not stop sync: failures are collected, listed at the end with a fix line, and sync exits 0.
- Codex publishes only the SubagentStop trace hook (`emit-trace.ps1`); Copilot publishes an empty `hooks.json`; Hermes publishes the compatibility plugin without agent-hooks and registers no hook. The shared `GuardCommon.ps1` is an always-allow shim, so path and secret verdicts are host-owned for these hosts.
- Uninstall removes legacy guard files (`guard-pre-tool.*`, `_hook-common.ps1`, `GuardCommon.ps1`, `authorization-contract.json`) listed in `scripts/runtime/uninstall-artifacts.json`, so installs made before the change are cleaned.
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
