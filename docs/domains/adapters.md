# Domain: Adapters

Adapters map `core/` into each agent’s install layout and expose a stable PowerShell surface for sync, validate, smoke, and uninstall.

**Authoritative per-agent detail:** [ADAPTERS.md](../ADAPTERS.md). This page is the RAG-friendly summary.

## Registry

File: `adapters/registry.json`

| Field | Meaning |
|-------|---------|
| `id` | CLI `-Agent` token |
| `displayName` | Human label |
| `module` | Path under `adapters/` to dot-source |
| `capabilities` | Boolean publish flags + string `subagents` enum (`native` \| `none`) |

List agents:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
```

## Registered agents

| id | Module | Typical live root |
|----|--------|-------------------|
| `cursor` | `cursor/CursorAdapter.ps1` | `~/.cursor` |
| `antigravity` | `antigravity/AntigravityAdapter.ps1` | `~/.gemini` |
| `claude` | `claude/ClaudeAdapter.ps1` | `~/.claude` |
| `codex` | `codex/CodexAdapter.ps1` | `~/.codex` (dual-root: plugin skills + `rules/` + optional `~/.agents/skills`) |
| `copilot` | `copilot/CopilotAdapter.ps1` | `~/.copilot` or `.github` |
| `opencode` | `opencode/OpenCodeAdapter.ps1` | `~/.config/opencode` |
| `grok` | `grok/GrokAdapter.ps1` | `~/.grok` |
| `zcode` | `zcode/ZCodeAdapter.ps1` | `~/.zcode` |
| `hermes` | `hermes/HermesAdapter.ps1` | `~/.hermes` (skills + `AGENTS.md` at that root) |
| `openhands` | `openhands/OpenHandsAdapter.ps1` | Project tree; user skills `~/.agents/skills` |

Contract stubs / shared helpers: `adapters/_contract/AdapterContract.ps1`.

## Public commands

| Command | Intent |
|---------|--------|
| `Get-Capabilities` | Capability flags (incl. `subagents`) |
| `Get-InstallRoots` | Official roots metadata |
| `Publish-Skills` / `Publish-Policy` / `Publish-Router` / `Publish-Hooks` | Publish into InstallRoot |
| `Get-SddRoot` | Resolve / prepare SDD state root |
| `Invoke-SmokeValidate` | Fixture filesystem smoke |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts (all adapters; preserves SDD state) |

Orchestrators: `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`, `scripts/toolkit.ps1`. **Backup** (`-Action Backup`) is a CLI stub only — it does **not** call an adapter.

## Subagents / SPAWN

Capability `subagents` is the string enum `native` \| `none` (not boolean). Most adapters declare `native`. **OpenHands** declares `none` (Canvas/ACP is not parent→child; SPAWN fallback in-parent). **Antigravity** *effective* capability may differ (fail-closed version probe). Contract: [SPAWN.md](../SPAWN.md) and `core/skills/_shared/agents/SPAWN.md`. Language surfaces: `core/skills/_shared/agents/LANGUAGE.md` (chat + artifacts match user chat; spawn/receipts **en-US**). Per-host spawn mechanism: each adapter README **Spawn / subagents** section.

## Notable semantics

| Topic | Behavior |
|-------|----------|
| Home guard | USERPROFILE paths need `-AllowUserHome` |
| Copilot Mode | `-Mode user\|repo` required |
| OpenCode hooks | Plugin JS only (`HooksSemantics=plugin-only`); CI smoke = filesystem only |
| Codex dual-root | Plugin skills under `InstallRoot/plugin`; Publish-Policy → `InstallRoot/rules`; default sync plugin-only; `-UserScope` → fixture `.agents/skills` or live `~/.agents/skills` (+ `-AllowUserHome`) |
| Codex / Grok trust | Manual in the product UI; never required for CI green |
| ZCode vs GLM | `zcode` = ADE filesystem; GLM Coding Plan is out of scope |
| Hermes | Native `~/.hermes`; policy folded into `AGENTS.md`; no `rules/`; hooks/plugin/agents false; `delegate_task`; MEMORY.md seed-if-missing; never SOUL.md/gateway |
| OpenHands | Project tree + optional `~/.agents/skills`; Agent Skills not microagents; shell hooks; `subagents=none` |
| Antigravity legacy | `antigravity-ide/plugins` opt-in / docs only — not default smoke |
| Keyed uninstall | All registered adapters; preserves `sdd/sessions` + `sdd/manifest.json` |
| Sync prepare | Every sync runs `Get-SddRoot -Prepare` |

## Module READMEs

- [adapters/cursor/README.md](../../adapters/cursor/README.md) — hooks merge; keyed uninstall (preserves SDD)
- [adapters/antigravity/README.md](../../adapters/antigravity/README.md) — official `config/*`; spawn probe
- [adapters/claude/README.md](../../adapters/claude/README.md) — settings merge, narrow permissions, keyed uninstall
- [adapters/codex/README.md](../../adapters/codex/README.md) — dual-root plugin/rules; UserScope; keyed uninstall
- [adapters/copilot/README.md](../../adapters/copilot/README.md) — Mode user\|repo; keyed uninstall
- [adapters/opencode/README.md](../../adapters/opencode/README.md) — plugin-only hooks; keyed uninstall
- [adapters/grok/README.md](../../adapters/grok/README.md) — native `.grok`, trust note; keyed uninstall
- [adapters/zcode/README.md](../../adapters/zcode/README.md) — ADE filesystem; keyed uninstall (preserves SDD)
- [adapters/hermes/README.md](../../adapters/hermes/README.md) — native `~/.hermes`; folded policy; `delegate_task`; keyed uninstall
- [adapters/openhands/README.md](../../adapters/openhands/README.md) — project tree + user skills; not microagents; keyed uninstall

## Related

- [ADAPTERS.md](../ADAPTERS.md) — full contract
- [ARCHITECTURE.md](../ARCHITECTURE.md) — install layout tables
- [domains/cli-scripts.md](cli-scripts.md)
