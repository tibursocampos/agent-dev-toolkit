# Architecture

## Target shape

```text
core/          # skills (kebab, 37 + _shared), policy, router, sdd contracts
adapters/      # registry.json + _contract + per-agent thin *Adapter.ps1 + Publish-* siblings
scripts/       # toolkit.ps1, sync-agent, validate-agent, _lib, validation
docs/          # public docs (incl. SPAWN.md, ADAPTERS, VALIDATION)
memory-bank/   # durable workspace map (Orchestrated Delivery Step 0)
.github/workflows/  # validate-toolkit.yml (+ enforce-release-source.yml)
```

## Layers

| Layer | Role |
|-------|------|
| Core | Agent Skills `SKILL.md` + `_shared` + policy markdown + neutral router |
| Adapter | Publish skills/policy/router/hooks into agent-specific layout; smoke via fixture root. Claude/Cursor/Grok: thin entry + `Publish-*` / `Uninstall-*` modules |
| CLI | `toolkit.ps1` chooses agent for sync/validate/uninstall |
| Lib | `Resolve-InstallRoot` (AllowUserHome, reparse, `\\?\` / `\\.\` strip, Initialize-for-write); `Copy-ToolkitManagedTree` (managed prune/copy containment) |
| CI | validate-core + keyed uninstall asserts + AllowUserHome forward + 10 agent smokes |

## Entry points

- `scripts/toolkit.ps1` — interactive menu + `-Agent`
- `scripts/sync-agent.ps1` — orchestrates adapter publish
- `scripts/validate-agent.ps1` — core contracts + adapter `Invoke-SmokeValidate`
- `scripts/validation/validate-core.ps1` — in-repo suite (no live home)
- `.github/workflows/validate-toolkit.yml` — full CI matrix

## Uninstall honesty

Keyed `Uninstall-Toolkit` implemented for all registry adapters (including Cursor, ZCode, Hermes, OpenHands).  
Preserves `sdd/sessions` and `sdd/manifest.json` (operator runtime state).

## Sync prepare (SDD state root)

Every sync runs `Get-SddRoot -Prepare` (`sdd/sessions/` + seed `manifest.json` when absent).

## Subagents

Registry: each adapter declares `subagents: native` or `none` (OpenHands is `none`). Antigravity effective capability fail-closed via `Get-Capabilities` probe. Contract: `core/skills/_shared/agents/SPAWN.md` + `docs/SPAWN.md`. Language surfaces: `core/skills/_shared/agents/LANGUAGE.md`.

## OpenCode hooks

`HooksSemantics=plugin-only` (JS plugins under `plugins/`). CI smoke is filesystem sync+validate only — not product runtime.

<!-- BEGIN GENERATED: inventory-summary -->
- Inventory at: 2026-07-31T23:38:19Z (refresh)
- Stack: PowerShell + Markdown; 37 kebab skills; 39 Assert-*.ps1 scripts
- Present: `core/skills|policy|router|sdd`, `adapters/registry.json` + `_contract` + per-agent modules (Claude/Cursor/Grok/Hermes/OpenHands split), `docs/SPAWN.md`, `Resolve-InstallRoot` + `Copy-ToolkitManagedTree`, validate-core suite (install-root / managed-skills / uninstall-path / no-features-doc-links / cursor-hooks-merge / …), CI `validate-toolkit.yml` + `enforce-release-source.yml`
- Adapter layout: thin `*Adapter.ps1` + `Publish-*` / `Uninstall-*` for Claude, Cursor, Grok (Codex/Copilot/OpenCode/ZCode/Antigravity already modular or thin)
- Local SDD `features/` gitignored — not public doc source; use `docs/` + `core/skills/_shared/agents/`
<!-- END GENERATED: inventory-summary -->

## Notes

Fonte de conteúdo inicial: cópia de `cursor-dev-toolkit` (skills/rules) + deltas de `antigravity-dev-toolkit`. Sem submodule nos twins.
