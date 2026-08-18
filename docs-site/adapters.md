# Adapters

Adapters publish the shared **core** (skills, policy, router, hooks where supported) into each agent’s install layout. Orchestrators (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolve an agent via `adapters/registry.json`, then call that entry’s PowerShell module.

For the product walkthrough, start at [Get started](../get-started/). Core vs adapters: [Architecture](../architecture/). After sync: [Using skills](../using-skills/).

## Supported agents

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
| `hermes` | Hermes |
| `openhands` | OpenHands |

Closed implemented set: these 10 ids. Each has a concrete module with publish + in-repo smoke test.

## Codex note

Codex is **dual-root**: plugin skills live under `InstallRoot/plugin` (`rules=true` Publish-Policy → `InstallRoot/rules`); product/AGENTS/hooks parent is InstallRoot (live `~/.codex`). Default sync is **plugin-only**; optional `-UserScope` mirrors skills to fixture `InstallRoot/.agents/skills` or live `~/.agents/skills` (needs `-AllowUserHome`). Full contract: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) · operator guide: [Using skills](../using-skills/).

## Hermes note

Live InstallRoot is `~/.hermes`. Skills and `AGENTS.md` land **directly** under that root (`~/.hermes/skills`, not `~/.hermes/.hermes/skills`). Policy is folded into `AGENTS.md` (no `rules/` tree). Hooks are not published. Invoke skills with `/id` (each installed skill is a slash command).

## OpenHands note

**Project** InstallRoot is the repo root: skills at `.agents/skills/`, roster at `.agents/agents/`, folded `AGENTS.md`, shell hooks under `.openhands/`, plugin metadata at `.plugin/plugin.json`. **Live user skills** use `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` so skills land at `~/.agents/skills`. Canvas is **not** subagent spawn (`subagents=none`; SPAWN fallback in-parent).

## How sync works

1. Prefer interactive `scripts/toolkit.ps1` (Smart Manager).
2. Resolve `-Agent <id>` in [`adapters/registry.json`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/registry.json).
3. Load the adapter module (`Publish-*`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`, …).
4. Default `InstallRoot` is an in-repo fixture; live USERPROFILE paths require explicit `-AllowUserHome`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
# or: -Agent cursor | copilot | hermes | openhands | …
```

## Source tree

Per-agent READMEs and modules live under the repository adapters directory:

- [adapters/ on GitHub](https://github.com/tibursocampos/agent-dev-toolkit/tree/master/adapters)
- Full contract and install-root tables: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md)

Next: [Get started](../get-started/) · [Using skills](../using-skills/) · [Architecture](../architecture/)
