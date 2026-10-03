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


### Child assignment lifecycle

Batch related, bounded work before dispatch. Each dispatched task is one child assignment: once that child returns any result (complete, incomplete, blocked, or failed), treat the handle as closed and never follow up, reopen, resume, or reuse it. Any new task, review, or correction—including a lengthy correction to returned work—must use a fresh child handle; do not send returned work back to its former child. Clarifications are allowed only while the child is still running and must stay within its original assignment. Use the host's close/stop control when available; handle termination, retention, and context erasure are host-controlled, so do not promise that a returned child process or its context was killed or erased. Canonical policy: `core/skills/_shared/agents/SPAWN.md`.

### Official references

- [Rules / AGENTS.md](https://opencode.ai/docs/rules/)
- [Skills](https://opencode.ai/docs/skills/)
- [Agents](https://opencode.ai/docs/agents/)
- [Config](https://opencode.ai/docs/config/)
- [Plugins](https://opencode.ai/docs/plugins/)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
