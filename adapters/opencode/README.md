# OpenCode adapter (`opencode`)

Publish surfaces for **OpenCode** (skills + JS plugins). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `opencode` |
| Purpose | Publish skills, hooks, and router into an OpenCode config InstallRoot |
| Sync fixture | `scripts/validation/fixtures/opencode` |
| `subagents` (registry) | `native` |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent opencode -InstallRoot .\scripts\validation\fixtures\opencode
```

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Agents with `mode: subagent`; primary invokes via **Task** tool; manual `@` mention |
| Toolkit contract | Prefer OpenCode Task / subagent when `subagents=native`; SPAWN fallback otherwise |

### Official references

- [Agents](https://opencode.ai/docs/agents/)
- [Config](https://opencode.ai/docs/config/) (incl. agent / permission.task)


Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
