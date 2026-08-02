# Adapters

Adapters publish the shared **core** (skills, policy, router, hooks where supported) into each agent’s install layout. Orchestrators (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolve an agent via `adapters/registry.json`, then call that entry’s PowerShell module.

## Tier-1 agents

| id | displayName |
|----|-------------|
| `cursor` | Cursor |
| `antigravity` | Antigravity |
| `claude` | Claude Code |
| `codex` | Codex |
| `copilot` | GitHub Copilot |
| `opencode` | OpenCode |
| `grok` | Grok Build |
| `zcode` | ZCode |

All eight have concrete modules with publish + in-repo smoke test.

## How sync works

1. Resolve `-Agent <id>` in [`adapters/registry.json`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/registry.json).
2. Load the adapter module (`Publish-*`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`, …).
3. Default `InstallRoot` is an in-repo fixture; live USERPROFILE paths require explicit `-AllowUserHome`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
```

## Source tree

Per-agent READMEs and modules live under the repository adapters directory:

- [adapters/ on GitHub](https://github.com/tibursocampos/agent-dev-toolkit/tree/master/adapters)
- Full contract and install-root tables: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md)
