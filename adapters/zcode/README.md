# ZCode adapter (`zcode`)

Publish surfaces for **ZCode ADE** (`~/.zcode`). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `zcode` |
| Purpose | Publish skills, hooks, and router into a ZCode InstallRoot |
| Sync fixture | `scripts/validation/fixtures/zcode-install-root` |
| `subagents` (registry) | `native` |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent zcode -InstallRoot .\scripts\validation\fixtures\zcode-install-root
```

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Primary launches subagents via **Agent** tool; built-ins `general-purpose` / `Explore`; custom under `~/.zcode/agents/` |
| Toolkit contract | Prefer Agent tool when `subagents=native`; SPAWN fallback otherwise |

Do not confuse with the unrelated open-source CLI named “Z-CODE” (different project).

## Uninstall

`Uninstall-Toolkit` is **not implemented** (fail-closed stub — no filesystem writes). Keyed uninstall is implemented on other Tier 1 agents (Claude, Copilot, Codex, OpenCode, Antigravity, Grok).

### Official references

- [Subagents](https://zcode.z.ai/en/docs/subagents)


Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
