# Codex adapter (`codex`)

Publish surfaces for **Codex** (plugin + marketplace packaging). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `codex` |
| Purpose | Publish bundled plugin skills, hooks, and router for Codex |
| Sync fixture | `scripts/validation/fixtures/codex` |
| `subagents` (registry) | `native` |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot .\scripts\validation\fixtures\codex
```

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Parallel **subagent** workflows (prompt / `AGENTS.md` / skill instructions); custom agents under `.codex/agents/` or `~/.codex/agents/` |
| Toolkit contract | Prefer spawn language in skills when `subagents=native`; SPAWN fallback if multi-agent tools disabled |

### Official references

- [Subagents](https://developers.openai.com/codex/subagents)
- [Subagents (concepts)](https://developers.openai.com/codex/concepts/subagents)
- Config `[agents]` / `agents.enabled` (product docs)


## `.codex-plugin` extras (honesty)

On **Publish-Skills**, the adapter keeps only `plugin/.codex-plugin/plugin.json` in that directory. Any other files already present under `.codex-plugin` (alien extras) are **deleted** before rewriting the managed manifest. Do not store custom files there if you need them to survive sync.

Keyed **Uninstall-Toolkit** removes the managed `plugin.json` (and an empty `.codex-plugin` dir when applicable); it does **not** wipe `plugin/` or `.agents/` wholesale.

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
