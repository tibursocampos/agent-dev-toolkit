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

## How to invoke

| Item | Value |
|------|-------|
| Skills path (live) | `~/.config/opencode/skills` |
| Explicit form | OpenCode **`skill` tool** (not slash-first) |
| Example | `skill({ name: "help-skills" })` |

Canonical form is the skill **id** / `name` argument.

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Agents with `mode: subagent`; primary invokes via **Task** tool; manual `@` mention |
| Toolkit contract | Prefer OpenCode Task / subagent when `subagents=native`; SPAWN fallback otherwise |
| Published files | `Publish-Agents` copies `core/agents/` → `InstallRoot/agents/` (`agents=true`). |

### Official references

- [Rules / AGENTS.md](https://opencode.ai/docs/rules/)
- [Skills](https://opencode.ai/docs/skills/)
- [Agents](https://opencode.ai/docs/agents/)
- [Config](https://opencode.ai/docs/config/)
- [Plugins](https://opencode.ai/docs/plugins/)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
