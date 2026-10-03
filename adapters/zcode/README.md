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

## How to invoke

| Item | Value |
|------|-------|
| Skills path (live) | `~/.zcode/skills/<id>/SKILL.md` |
| Explicit form | `$id` |
| Examples | `$help-skills`, `$sdd-spec` |
| After sync | Settings → Skills → Refresh if the product requires it |

Canonical form is the skill **id**; `$` is the ZCode host prefix (same token as Codex, different product).

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Primary launches subagents via **Agent** tool; built-ins `general-purpose` / `Explore`; custom under `~/.zcode/agents/` |
| Toolkit contract | Prefer Agent tool when `subagents=native`; SPAWN fallback otherwise |
| Published files | `Publish-Agents` copies `core/agents/` → `InstallRoot/agents/` (live `~/.zcode/agents/`). |

Do not confuse with the unrelated open-source CLI named “Z-CODE” (different project).

### Child assignment lifecycle

Batch related, bounded work before dispatch. Each dispatched task is one child assignment: once that child returns any result (complete, incomplete, blocked, or failed), treat the handle as closed and never follow up, reopen, resume, or reuse it. Any new task, review, or correction—including a lengthy correction to returned work—must use a fresh child handle; do not send returned work back to its former child. Clarifications are allowed only while the child is still running and must stay within its original assignment. Use the host's close/stop control when available; handle termination, retention, and context erasure are host-controlled, so do not promise that a returned child process or its context was killed or erased. Canonical policy: `core/skills/_shared/agents/SPAWN.md`.

## Uninstall (keyed)

Removes only toolkit-managed paths (core skill ids) and reverse-merges `cli/config.json` / `hooks/hooks.json` (drop toolkit overlay; keep aliens). **`AGENTS.md` is deleted only when provenance confirms toolkit ownership** via InstallRoot `.toolkit-managed-publish.json` (sha256 recorded on publish) or a legacy hash match to resolved `core/router/AGENTS.md`; operator edits are preserved. Preserves alien skills/hooks and **does not** remove `sdd/sessions` or `sdd/manifest.json`. Does **not** wipe InstallRoot wholesale. Supports `-WhatIf`.


### Official references

- [Agents / AGENTS.md](https://zcode.z.ai/en/docs/agents)
- [Subagents](https://zcode.z.ai/en/docs/subagents)
- [Skills](https://zcode.z.ai/en/docs/skill)
- [Hooks](https://zcode.z.ai/en/docs/hooks)
- [Plugins](https://zcode.z.ai/en/docs/plugin)

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
