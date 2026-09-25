---
title: Adapters
---

# Adapters

An adapter publishes the shared **core** into one agent’s install layout. `adapters/registry.json` names the agent. The module under `adapters/<id>/` does the publish. This page is that map. Install steps are on [Get started](get-started.md).

## Registry

File: `adapters/registry.json`.

| Field | Meaning |
|-------|---------|
| `id` | CLI / `-Agent` id |
| `displayName` | Human label |
| `module` | Path relative to `adapters/` |
| `capabilities` | Booleans `skills`, `rules`, `hooks`, `router`, `plugin`, `agents`, plus string `subagents` (`native` or `none`) |
| `publishSurface` | Optional whole-file router targets. Antigravity uses managed markdown blocks. Copilot folds the router into `copilot-instructions.md` via `Publish-Policy`. Sync records sha256 in `.toolkit-managed-publish.json`. Uninstall removes a whole-file router only when the inventory hash matches |

## The ten agents

Every listed agent has a concrete module with publish and an in-repo smoke. The live Sync wizard **[1]** resolves `Get-InstallRoots` → `OfficialUserRootPath` (Enter is live home). CI and non-interactive defaults use fixtures unless `-AllowUserHome` is set.

| Agent | Live InstallRoot | Skills, rules, hooks | Skill invoke |
|-------|------------------|----------------------|--------------|
| `cursor` | `~/.cursor` | `skills/`, `rules/*.mdc`, `hooks.json`, `AGENTS.md` | `/id` |
| `antigravity` | `~/.gemini` | `config/skills`, `config/skills.json`, `config/AGENTS.md`, GUARDRAILS, `config/hooks` PreToolUse | `use skill id` or `/id` |
| `claude` | `~/.claude` | `skills/`, `rules/`, `CLAUDE.md`, hooks in `settings.json` | `/id` |
| `codex` | `~/.codex` | Dual-root: config and hooks under `~/.codex`; plugin under `InstallRoot/plugin`; `$` via `~/.codex/skills`; optional `-UserScope` `~/.agents/skills`; rules under `InstallRoot/rules` | `$id` |
| `copilot` | `~/.copilot` or `.github` | `-Mode user` or `repo`. `skills/`, `instructions/`, `copilot-instructions.md`, `hooks/` | `/id`, then `/skills reload` |
| `opencode` | `~/.config/opencode` | `skills/`, `AGENTS.md`, JS `plugins/` | `skill({ name: "…" })` |
| `grok` | `~/.grok` | `skills/`, `rules/`, `hooks/`, `AGENTS.md` | `/id` |
| `zcode` | `~/.zcode` | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` | `$id` |
| `hermes` | `$HERMES_HOME` (Windows `%LOCALAPPDATA%\hermes`; POSIX `~/.hermes`) | `skills/`, `AGENTS.md` (folded policy). Seed `memories/MEMORY.md` if missing | `/id` |
| `openhands` | Project tree. User skills `~/.agents` | Project: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/` hooks, `.plugin/plugin.json` | Mention the skill id |

## Capabilities

| Flag | Intent |
|------|--------|
| `skills` | Publish Agent Skills from `core/skills/` |
| `rules` | Publish policy from `core/policy/` |
| `hooks` | Publish hooks |
| `router` | Publish router material from `core/router/` |
| `plugin` | Plugin or extension packaging |
| `agents` | Publish roster markdown from `core/agents/` |
| `subagents` | `native` or `none`. Stub defaults must never mint `native` |

`subagents` below is the declared string in `adapters/registry.json`. Antigravity’s effective value may differ (probe later on this page).

| Agent | skills | rules | hooks | router | plugin | agents | subagents | Notes |
|-------|--------|-------|-------|--------|--------|--------|-----------|-------|
| `cursor` | true | true | true | true | false | true | `native` | `Publish-Agents` → `InstallRoot/agents/` |
| `antigravity` | true | true | true | true | true | false | `native` | Declared `native`. `Publish-Agents` is a no-op. Effective value may be `none` |
| `claude` | true | true | true | true | false | true | `native` | Hooks smoke is files only. Trust UI is out of scope |
| `codex` | true | true | true | true | true | true | `native` | Dual-root. `Publish-Agents` → `agents/*.toml`. `/hooks` trust is manual |
| `copilot` | true | true | true | false | false | true | `native` | `Publish-Router` is a no-op. Mode `repo` publishes agents |
| `opencode` | true | false | true | true | true | true | `native` | `HooksSemantics=plugin-only` (JS throw) |
| `grok` | true | true | true | true | false | true | `native` | Native under `~/.grok` |
| `zcode` | true | false | true | true | false | true | `native` | `Publish-Policy` is a no-op |
| `hermes` | true | true | true | true | true | false | `native` | Policy folded into `AGENTS.md`. Never `SOUL.md` |
| `openhands` | true | true | true | true | true | true | `none` | The only declared `none`. Roster is not native spawn |

### Path and secrets guard

Shared rules: `adapters/_shared/guard-rules.md`. Helpers: `adapters/_shared/GuardCommon.ps1`. Paths outside the workspace, and a write or delete without a resolvable path, are denied (fail-closed).

| Agent | Wiring |
|-------|--------|
| Cursor | `preToolUse` Write/Edit/Shell/Delete plus `beforeShellExecution`. `failClosed`. GuardCommon |
| Claude | PreToolUse `Write\|Edit\|Bash\|PowerShell` → `permissionDecision` deny |
| Codex | PreToolUse plus `agents/*.toml` |
| Copilot | hooks `version:1` `preToolUse` |
| OpenHands | `pre_tool_use` plus `guard_pre_tool.sh` |
| ZCode | PreToolUse |
| Grok | PreToolUse |
| OpenCode | JS `tool.execute.before` throw |
| Antigravity | `config/hooks` PreToolUse |
| Hermes | Plugin `agent-dev-toolkit-guard` plus `agent-hooks`. Keyed `config.yaml` only `plugins.enabled` / `hooks.pre_tool_call`. Never SOUL, tokens, or gateway |

Most adapters declare `subagents: native`. OpenHands declares `none` (SPAWN stays in the parent). Antigravity’s effective capability is fail-closed in `Get-Capabilities`. Probe order in `core/skills/_shared/agents/SPAWN.md`: `ADT_ANTIGRAVITY_SUBAGENTS` override → product version `>= 2.0.0` when known → parseable `agy --version` `>= 1.0.0` as a 2.0 harness proxy (the CLI stays `1.x`; do not require CLI major ≥ 2) → else `none`. Before 2.0, or when the probe cannot tell, the effective value is `none`.

Publish may emit only SPAWN-aligned depth and threads honesty, and model inherit (or omit model). Caps: developer ≤ 2, orchestrate ≤ 4. Publish does not pin a child model that differs from the parent. It does not emit host `delegation.max_spawn_depth` or config.toml knobs for Hermes, Antigravity (`agents: false`), or OpenCode.

TRACE emitter honesty:

| Claim | Hosts |
|-------|--------|
| Wired fail-open `emit-trace.ps1` | Cursor (`hooks.json` postToolUse / subagentStop). Claude (PostToolUse / SubagentStop) |
| Asset only, not a live PostToolUse wire | Codex (`Publish-Hooks` stays the PreToolUse guard) |
| Not claimed | OpenHands, OpenCode, Hermes, Grok, Copilot, Antigravity, ZCode |

Assert: `Assert-TraceEmitterFailOpen.ps1`. The trail file is `features/NNN-slug/TRACE.jsonl`.

## Public commands

Module stub: `adapters/_contract/AdapterContract.ps1`. Concrete modules live under `adapters/<id>/`.

| Command | Intent |
|---------|--------|
| `Get-Capabilities` | Report flags. The stub returns every flag `false` and `Implemented = false` |
| `Get-InstallRoots` | Resolve official roots. The stub writes no path |
| `Publish-Skills` | Publish skills. The stub writes nothing |
| `Publish-Policy` | Publish policy. The stub writes nothing |
| `Publish-Router` | Publish the router. The stub writes nothing |
| `Publish-Agents` | Publish roster markdown from `core/agents/` |
| `Publish-Hooks` | Publish hooks. The stub writes nothing |
| `Get-SddRoot` | Resolve or prepare `<InstallRoot>/sdd` |
| `Invoke-SmokeValidate` | Smoke a fixture InstallRoot. It must not require a live profile |
| `Uninstall-Toolkit` | Keyed removal. Keeps `sdd/sessions` and `sdd/manifest.json` |

A not-implemented result is `Success = false`, `Implemented = false`, `ExitCode = 1`, with an actionable message. Stubs must not write under the user profile.

### SDD root

Canonical contracts: `core/sdd/` (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`). Public state file: `manifest.json`. Helper: `scripts/_lib/Initialize-SddRootLayout.ps1`.

| Item | Value |
|------|-------|
| `Get-SddRoot` | Returns `<InstallRoot>/sdd` (`SddRoot`, `SessionsPath`, `ManifestPath`) |
| `Get-SddRoot -Prepare` | Creates `sdd/sessions/` if missing. Seeds `manifest.json` (`schema_version: 2`, empty `repositories`) only when the file is absent |
| Sync | `scripts/sync-agent.ps1` always calls `Get-SddRoot -Prepare` after Publish |
| Uninstall | Must keep `sdd/sessions/` and `sdd/manifest.json` |
| Guard | Prepare respects `Resolve-InstallRoot` (`-AllowUserHome` under the user profile) |

Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, and `{{GUARDRAILS_PATH}}` stay in `core/` on disk. Each adapter substitutes them at the destination. Needles: `scripts/validation/contracts/must-not-contain-ide.json`.

## Scripts that load a module

These three scripts resolve an agent in the registry and call the module. The install walkthrough, including `-Action` examples, stays on [Get started](get-started.md).

| Script | Behavior |
|--------|----------|
| `scripts/toolkit.ps1` | Menu or `-Action` / `-Agent`. Lists registry agents. Sync, Validate, and Uninstall require an agent. Forwards Sync and Validate. Uninstall calls `Uninstall-Toolkit`. **Backup** (`-Action Backup`) is a fail-closed stub and does not call an adapter |
| `scripts/sync-agent.ps1 -Agent <id>` | Loads the registry entry and module, calls `Publish-*`, then always `Get-SddRoot -Prepare`. Unknown or incomplete adapters exit non-zero with **not implemented** (TE04). Default InstallRoot is the in-repo fixture. A user-profile path without `-AllowUserHome` is refused |
| `scripts/validate-agent.ps1 -Agent <id>` | Always runs `validate-core`, then `Invoke-SmokeValidate` against the fixture InstallRoot. A documented no-op smoke does not fail the run. A missing or unknown `-Agent` still aborts (TE01 / TE02) |

## Cursor

| Item | Value |
|------|-------|
| Module | `adapters/cursor/CursorAdapter.ps1` |
| Official root | `~/.cursor` |
| Fixture | `scripts/validation/fixtures/cursor-install-root` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `agents` true. `plugin` false |
| Artifacts | `skills/`, `rules/*.mdc`, `AGENTS.md`, `agents/*.md`, `hooks/*.ps1`, `hooks.json`, `sdd/` |

```powershell
$cursorFixture = Join-Path $PWD 'scripts\validation\fixtures\cursor-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
```

Uninstall removes toolkit skills, rules, hooks, and `AGENTS.md`, and reverse-merges managed `hooks.json` handlers. CI: `Assert-CursorKeyedUninstall.ps1`.

## Antigravity

| Item | Value |
|------|-------|
| Module | `adapters/antigravity/AntigravityAdapter.ps1` |
| Official root | `~/.gemini` |
| Layout | `config/skills`, `config/plugins`, `config/hooks`, `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `plugin` true. `agents` false |
| `Publish-Agents` | No-op. Host spawn is `invoke_subagent` |
| `Publish-Hooks` | `config/hooks/hooks.json` plus `guard-pre-tool.ps1` |

The legacy bridge `antigravity-ide/plugins` is not a CI or default-smoke gate. Live Knowledge Items and the IDE trust UI are out of scope. Fixture: `scripts/validation/fixtures/antigravity-install-root`. Smoke: `Invoke-AntigravityCiSmoke.ps1`.

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent antigravity
```

## Claude Code

| Item | Value |
|------|-------|
| Module | `adapters/claude/ClaudeAdapter.ps1` |
| Official root | `~/.claude`. Project scope: repo `.claude/` |
| Fixture | `scripts/validation/fixtures/claude/` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `agents` true. `plugin` false |
| Artifacts | `skills/`, `rules/*.md`, `hooks/*.ps1`, `CLAUDE.md`, `agents/*.md`, merged `settings.json` |

`settings.json` merge: write `settings.json.bak` first; keyed upsert for `UserPromptSubmit`, `PreCompact`, `PostToolUse`, `PreToolUse`; additive narrow `permissions.allow` entries, one `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` per managed hook. Re-sync strips legacy broad `Bash(pwsh *)` / `Bash(powershell *)` unless `-AllowBroadShellPermissions`. Other keys stay. Encoding is UTF-8 without BOM. Invalid JSON aborts (TE01). Backup failure aborts (TE02).

`PreToolUse` matcher `Write|Edit|Bash|PowerShell` runs `guard-pre-tool.ps1`. Hook trust UI is outside smoke.

```powershell
$claudeFixture = Join-Path $PWD 'scripts\validation\fixtures\claude'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
```

## Codex

| Item | Value |
|------|-------|
| Module | `adapters/codex/CodexAdapter.ps1` |
| Product home | `~/.codex` |
| `$` mirror | `InstallRoot/skills` (live `~/.codex/skills`). The plugin path alone does not feed `$` |
| Optional USER skills | `~/.agents/skills` via `-UserScope` and, on a live home, `-AllowUserHome` |
| Fixture | `scripts/validation/fixtures/codex` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `plugin`, `agents` all true |

Default sync is plugin-only. `Publish-Agents` writes `agents/*.toml`. `AGENTS.md` uses absolute dual-root paths and keeps no `{{…}}` placeholders. Codex `/hooks` is manual. Smoke sets `RequiresHooksTrust=false`. There is no `$skill --menu` flag.

```powershell
$codexFixture = Join-Path $PWD 'scripts\validation\fixtures\codex'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot $codexFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent codex -InstallRoot $codexFixture
```

## GitHub Copilot

| Item | Value |
|------|-------|
| Module | `adapters/copilot/CopilotAdapter.ps1` |
| Required flag | `-Mode user` or `-Mode repo`. Missing or invalid mode is TE02 |
| Mode `user` | Models `~/.copilot`. Fixture `scripts/validation/fixtures/copilot/user` |
| Mode `repo` | Models `.github`. Fixture `scripts/validation/fixtures/copilot/repo` |
| Capabilities | `skills`, `rules`, `hooks`, `agents` true. `router` and `plugin` false |

The relative layout is the same in both modes: `skills/`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/`. `Publish-Router` is a no-op. Router text is folded into `copilot-instructions.md`. `agents/*.md` publish in Mode `repo` only. JetBrains and Eclipse layouts are out of scope.

```powershell
$copilotUser = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$copilotRepo = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
```

## OpenCode

| Item | Value |
|------|-------|
| Module | `adapters/opencode/OpenCodeAdapter.ps1` |
| Official root | `~/.config/opencode` |
| Fixture | `scripts/validation/fixtures/opencode/` |
| Capabilities | `skills`, `hooks`, `router`, `plugin`, `agents` true. `rules` false |
| Hooks | `HooksSemantics=plugin-only`. `plugins/agent-dev-toolkit-marker.js` |
| `Publish-Policy` | No-op |

```powershell
$opencodeFixture = Join-Path $PWD 'scripts\validation\fixtures\opencode'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent opencode -InstallRoot $opencodeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent opencode -InstallRoot $opencodeFixture
```

## ZCode

| Item | Value |
|------|-------|
| Module | `adapters/zcode/ZCodeAdapter.ps1` |
| Official root | `~/.zcode` |
| Fixture | `scripts/validation/fixtures/zcode-install-root` |
| Capabilities | `skills`, `hooks`, `router`, `agents` true. `rules` and `plugin` false |
| `Publish-Policy` | No-op |

ADE filesystem only. GLM Coding Plan (endpoint, base URL, MCP) is out of scope. Do not use agent id `zcode` for that setup. Uninstall reverse-merges `cli/config.json` and `hooks/hooks.json`. CI: `Assert-ZcodeKeyedUninstall.ps1` and `Invoke-ZCodeCiSmoke.ps1`.

```powershell
$zcodeFixture = Join-Path $PWD 'scripts\validation\fixtures\zcode-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent zcode -InstallRoot $zcodeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent zcode -InstallRoot $zcodeFixture
```

## Grok Build

| Item | Value |
|------|-------|
| Module | `adapters/grok/GrokAdapter.ps1` |
| Official root | `~/.grok` (InstallRoot is that directory) |
| Fixture | `scripts/validation/fixtures/grok` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `agents` true. `plugin` false |
| Invoke | `/id` |

Publish under InstallRoot directly. Do not nest `.grok/skills` when InstallRoot is already `~/.grok`. `/hooks-trust` is manual. Smoke does not write `trusted_folders.toml`.

```powershell
$grokFixture = Join-Path $PWD 'scripts\validation\fixtures\grok'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent grok -InstallRoot $grokFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent grok -InstallRoot $grokFixture
```

## Hermes

| Item | Value |
|------|-------|
| Module | `adapters/hermes/HermesAdapter.ps1` |
| Official root | `HERMES_HOME`, else Windows `%LOCALAPPDATA%\hermes`, else `~/.hermes` |
| Fixture | `scripts/validation/fixtures/hermes` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `plugin` true. `agents` false. `subagents` `native` |
| Invoke | `/id` via `delegate_task` for subagents |

`Publish-Policy` folds policy into `AGENTS.md` and appends `adapters/hermes/assets/spawn-bridge.md`. It does not write a `rules/` tree. `GUARDRAILS_PATH` is `InstallRoot/AGENTS.md`. `memories/MEMORY.md` is seeded once if missing. `SOUL.md` is never written. Official user-home skills do not need trust. A project copy may call `hermes skills trust`. A missing `hermes` CLI skips trust and publish still succeeds. Uninstall keeps secrets, `memories/MEMORY.md`, `SOUL.md`, and `sdd/*`.

Out of scope: gateway tokens, cron, Kanban, voice, and `delegation.*` YAML.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes `
  -InstallRoot "$env:LOCALAPPDATA\hermes" -AllowUserHome
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1
```

## OpenHands

| Item | Value |
|------|-------|
| Module | `adapters/openhands/OpenHandsAdapter.ps1` |
| Project root | `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/`, `.plugin/` |
| User skills | `~/.agents/skills` via `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` |
| Fixture | `scripts/validation/fixtures/openhands` |
| Capabilities | `skills`, `rules`, `hooks`, `router`, `plugin`, `agents` true. `subagents` `none` |

Hooks are shell, not `.ps1`: `guard_pre_tool.sh` for `pre_tool_use`. Skills work without the plugin. Canvas and ACP are not parent-to-child spawn. Placeholders resolve with `TOOLKIT_ROOT` = `InstallRoot/.agents` on a project tree, and with that home directory when InstallRoot is live `~/.agents` (skills at `skills/`, not a nested `.agents`).

Out of scope: Automation Server, cron, GitHub webhooks, sandbox YAML, LLM secrets, and legacy `.openhands/microagents/`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands
$openhandsFixture = Join-Path $PWD 'scripts\validation\fixtures\openhands'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent openhands -InstallRoot $openhandsFixture
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands `
  -InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1
```

## Constraints

- Smoke uses an in-repo fixture. A green CI run does not require a live profile sync.
- Content published to agents comes from `core/`.
- A live home write needs `-AllowUserHome` and stays outside CI.
