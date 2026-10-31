# Claude adapter (`claude`)

Publish surfaces for **Claude Code**. InstallRoot defaults to an in-repo fixture; paths under `USERPROFILE` require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `claude` |
| `subagents` (registry) | `native` |

## How to invoke

| Item | Value |
|------|-------|
| Skills path (live) | `~/.claude/skills/<id>/SKILL.md` (or project `.claude/`) |
| Explicit form | `/id` |
| Examples | `/help-skills`, `/sdd-spec`, `/sdd-plan` |

Canonical form is the skill **id**; `/` is the Claude host prefix.

## Shell sandbox and network

Claude Code's shell sandbox applies to Bash, PowerShell, and child processes on macOS, Linux, and WSL2; native Windows commands run unsandboxed. The sandbox and permission prompts are separate controls, and credentials available to the host do not make network hosts reachable from a sandboxed command. When a command fails, inspect its error and active runtime, then use the host's normal prompt or a narrow configured filesystem/domain exception. If policy blocks the exception, stop and report it. Do not disable isolation, use an unsandboxed retry, or alter Claude settings during toolkit setup without an explicit operator request.

Official reference: [Claude Code sandboxing](https://code.claude.com/docs/en/sandboxing).

## Spawn / subagents

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Claude Code **Agent** / Task-equivalent spawn |
| Toolkit contract | Prefer Task/Agent naming in skills when `subagents=native`; SPAWN in-parent fallback otherwise |
| Published files | `Publish-Agents` copies `core/agents/` to `InstallRoot/agents/` (live `~/.claude/agents/`). Small roster only (not every `*-developer` skill). |
| Model inherit | Every published agent carries `model: inherit`; publish asserts it after copy. |
| Child spawn guard | Every published agent carries `disallowedTools: Agent`, so a child cannot spawn another subagent. |
| Depth / threads | SPAWN caps ≤2 / ≤4 are enforced in the skills contract, not in Claude host settings. |
| Matrix | [`adapters/_shared/spawn-publish-honesty.md`](../_shared/spawn-publish-honesty.md) |

Matrix: [docs/SPAWN.md](../../docs/SPAWN.md). Contract: `core/skills/_shared/agents/SPAWN.md`.

### Child assignment lifecycle

Batch related, bounded work before dispatch. Each dispatched task is one child assignment: once that child returns any result (complete, incomplete, blocked, or failed), treat the handle as idle. Continue it (SendMessage where the host offers it) only for the same topic and scope while its context is still relevant; never reuse it for a different topic, a different scope, or an already large context. A new task, review, or correction on a different scope must use a fresh child handle. Clarifications are allowed only while the child is still running and must stay within its original assignment. Use the host's close/stop control when available; handle termination, retention, and context erasure are host-controlled, so do not promise that a returned child process or its context was killed or erased. Canonical policy: `core/skills/_shared/agents/SPAWN.md`.

### Agent tools per role

`Publish-Agents` writes a `tools:` allowlist into each published agent's frontmatter. The mapping lives in `Publish-ClaudeAgents.ps1` (`$script:ClaudeAgentToolsByRole`):

| Role | Tools |
|------|-------|
| `architect`, `repo-analyst`, `security`, `database` | `Read, Grep, Glob, Write, Edit` |
| `developer-child` | `Read, Grep, Glob, Write, Edit, Bash` |
| `shell-runner` | `Bash` |

`Write` and `Edit` are not path-scoped by this allowlist. A core agent without a mapping fails the publish, so a new role cannot ship with implicit tools.

## Policy to rules mapping

| Source | Destination |
|--------|-------------|
| `core/policy/{name}.md` | `<InstallRoot>/rules/{name}.md` |

- Files stay **`.md`** (Claude layout). Cursor normalizes the same core files to `.mdc`; this adapter does not.
- Frontmatter is shaped for Claude: `alwaysApply` is dropped (rules without a path scope load unconditionally), and `globs:` is renamed to `paths:` so path-scoped rules load only for matching files. The rule body is not changed.
- `model-cost-awareness.md` is a retired placeholder and is not published.
- Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` resolve relative to InstallRoot.
- Re-sync overwrites managed rule files; alien files under `rules/` are left alone.

## Router to CLAUDE.md mapping

| Source | Destination |
|--------|-------------|
| `core/router/AGENTS.md` | `<InstallRoot>/CLAUDE.md` |

- Content is **core router only**.
- After placeholder resolve, path refs ending in `.mdc` are rewritten to `.md` so they match published `rules/`.
- `Publish-Router` is implemented; capability `router=true` means `CLAUDE.md`.

## Skill frontmatter overlay

`core/skills/` stays neutral. `adapters/claude/skill-frontmatter.json` adds Claude-only fields to published `SKILL.md` files at publish time. Only these keys are merged: `name`, `disable-model-invocation`, `allowed-tools`, `argument-hint`. Every overlay key must name a skill that is published; a missing skill fails the publish.

## Hooks

| Source | Destination |
|--------|-------------|
| `adapters/claude/assets/hooks/*` | `<InstallRoot>/hooks/*` |

`Publish-Hooks` copies the scripts (managed scripts are replaced on re-sync), then merges `<InstallRoot>/settings.json`. Hook scripts run as `command` hooks. Each managed handler is `pwsh -NoProfile -File "<InstallRoot>/hooks/<script>"`.

Managed events and handlers:

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| `UserPromptSubmit` | none | `track-sdd-invocation.ps1` | Records SDD skill invocations (`use skill <id>` / `/<id>`). Always continues the prompt. |
| `UserPromptSubmit` | none | `preferences-command.ps1` | Handles the in-session commands (see below). Fail-open. |
| `SessionStart` | none | `session-start-context.ps1` | Adds the current SDD preference state as additional context. Fail-open. |
| `PostToolUse` | `Write\|Edit` | `plan-after-edit.ps1` | Records a PLAN checkpoint when a PLAN file is edited. |
| `PostToolUse` | `Write\|Edit\|Bash\|PowerShell` | `emit-trace.ps1` | Appends an allowlisted TRACE event. Fail-open. |
| `SubagentStop` | none | `emit-trace.ps1` | Appends an allowlisted TRACE event when a subagent stops. Fail-open. |

Retired events are kept only so re-sync can strip them: `PreCompact` and `PreToolUse` are projected as empty and any toolkit handler on them is removed. There is no `PreToolUse` guard hook for Claude. Enforcement is through `permissions` and the settings written below (see [docs/ENFORCEMENT.md](../../docs/ENFORCEMENT.md) and `adapters/_shared/guard-rules.md`).

Preference commands handled by `preferences-command.ps1` (case-insensitive, updates `sdd/preferences.json` under the user home):

| Command | Effect |
|---------|--------|
| `orchestrator always` / `orchestrator adaptive` / `orchestrator status` | Sets or reports `orchestrator_mode`. `orchestrate` and `parent` are accepted as aliases. |
| `caveman on` / `caveman off` / `caveman status` / `caveman lite` / `caveman full` / `caveman ultra` | Sets or reports `caveman_mode` and `caveman_level`. `stop caveman` and `normal mode` turn it off. |

### Settings merge

`Invoke-ClaudeMergeSettings` writes these keys in `settings.json`:

| Key | Managed content | Rule |
|-----|-----------------|------|
| `hooks` | Handlers for the managed events above | Keyed upsert by managed handler identity. Alien events and co-located alien handlers are kept. |
| `permissions.allow` | One narrow `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` per managed hook, plus read-only git: `Bash(git status:*)`, `Bash(git diff:*)`, `Bash(git log:*)`, `Bash(git branch --show-current:*)` | Additive, no duplicates. Legacy `Bash(pwsh *)` / `Bash(powershell *)` are stripped unless `-AllowBroadShellPermissions` is passed. |
| `permissions.ask` | `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(git merge:*)`, `Bash(git rebase:*)`, `Bash(git checkout -b:*)` | Additive. State-changing git needs operator confirmation. |
| `attribution` | `commit` and `pr` set to empty strings | Hides the default co-author and PR attribution. Other attribution keys are kept. A non-object `attribution` aborts the merge. |

Other behavior:

- Unrelated keys are preserved. UTF-8 without BOM. `settings.json.bak` is written before overwrite, plus a timestamped copy.
- Invalid JSON, a non-object `hooks` / `permissions` / `attribution`, or a backup failure aborts with no write.
- Re-sync does not duplicate toolkit allow or ask entries.
- **Smoke validates filesystem presence and command wiring only.** The Claude hook trust UI is out of scope.
- Review `settings.json` after sync.

## In-repo merge fixture

| Item | Path |
|------|------|
| InstallRoot (CI / smoke) | `scripts/validation/fixtures/claude` |
| Pre-existing `settings.json` | `scripts/validation/fixtures/claude/settings.json` |

Pass `-InstallRoot <repo>/scripts/validation/fixtures/claude`. Do not use `%USERPROFILE%` without `-AllowUserHome`. Seed markers (custom keys, alien `Notification` hook, partial `UserPromptSubmit`, user `permissions.allow`) exercise merge preservation.

## Commands

| Command | Status |
|---------|--------|
| `Publish-Skills` | Implemented (with frontmatter overlay) |
| `Publish-Policy` | Implemented (Claude rule frontmatter) |
| `Publish-Router` | Implemented |
| `Publish-Agents` | Implemented (`core/agents/` to `InstallRoot/agents/`; tools and `disallowedTools`) |
| `Publish-Hooks` (scripts + settings merge) | Implemented |
| `Invoke-ClaudeMergeSettings` | Implemented |
| `Invoke-SmokeValidate` | Implemented, filesystem only; lists missing relative paths on failure |
| `validate-agent -Agent claude` | Core + smoke against fixture |
| `sync-agent -Agent claude` | Publish-Skills, Policy, Router, Agents, Hooks |
| `toolkit.ps1 -Action ListAgents` | Lists registry entry `claude` |
| `Uninstall-Toolkit` | Keyed removal + settings reverse-merge; WhatIf supported |

### Uninstall scope

Removes only toolkit-managed paths (core skill ids, core policy to rules files, `CLAUDE.md`, asset hook scripts, managed agents) and reverse-merges `settings.json`: drops toolkit-managed hook handlers (same identity as merge) and managed `permissions.allow` / `permissions.ask` entries, plus legacy broad allows. Empty hook events are removed; alien co-located handlers on the same event are kept. Preserves alien files, `sdd/sessions`, `sdd/manifest.json`, and unrelated settings keys. Does not wipe InstallRoot or wholesale-replace settings.

### Managed vs preserved inventory

| Surface | Managed (toolkit) | Preserved (operator / alien) |
|---------|-------------------|------------------------------|
| `skills/` | Folders matching `core/skills/*` | Other skill folders / files |
| `rules/` | Files matching `core/policy/*` (`.md`) | Alien rule files |
| `agents/` | Files matching `core/agents/*` | Alien agent files |
| `CLAUDE.md` | Whole file from `core/router/AGENTS.md` (sha256 in `.toolkit-managed-publish.json`; uninstall preserves operator edits) | Sibling files at InstallRoot |
| `hooks/` | Scripts from `adapters/claude/assets/hooks/*` | Alien hook scripts |
| `settings.json` hooks | Handlers matching managed `pwsh -NoProfile -File ".../hooks/<script>"` on the managed events | Alien events (e.g. `Notification`) and alien handlers co-located on managed events |
| `settings.json` permissions | Narrow hook allows, read-only git allows, git `ask` entries (additive) | User allows / deny / ask / env / custom keys |
| `settings.json` attribution | `commit` and `pr` empty strings | Other attribution keys |
| Encoding / backup | UTF-8 without BOM; `settings.json.bak` before write | Original intact on invalid JSON abort |

Example:

```powershell
.\scripts\sync-agent.ps1 -Agent claude -InstallRoot .\scripts\validation\fixtures\claude
.\scripts\validate-agent.ps1 -Agent claude -InstallRoot .\scripts\validation\fixtures\claude
.\scripts\toolkit.ps1 -Action ListAgents
```

Live home:

```powershell
.\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

## TRACE emitters

| Field | Value |
|-------|-------|
| Events | `PostToolUse` (co-located with plan-after-edit) and `SubagentStop`, both `emit-trace.ps1` |
| Contract | Fail-open; allowlist; never echoes tool bodies |
| Matrix | `adapters/_shared/trace-emitter-honesty.md` |

## Docs and CI

- [ADAPTERS.md](../../docs/ADAPTERS.md): Claude layout, merge rules, fixture
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md): InstallRoot tree
- [INSTALL.md](../../docs/INSTALL.md): operator sync
- [VALIDATION.md](../../docs/VALIDATION.md): `Invoke-AdapterCiSmoke.ps1 -Adapter claude`

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-AdapterCiSmoke.ps1 -Adapter claude
```

Workflow step: `.github/workflows/validate-toolkit.yml`, step **Run Claude CI smoke** (no secrets; no home sync).

## Official docs (Anthropic)

- [Features overview](https://code.claude.com/docs/en/features-overview)
- [Memory / CLAUDE.md / rules](https://code.claude.com/docs/en/memory)
- [Skills](https://code.claude.com/docs/en/skills)
- [Hooks](https://code.claude.com/docs/en/hooks)
- [`.claude` directory](https://code.claude.com/docs/en/claude-directory)
- [Steering: skills, hooks, rules, subagents](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)
