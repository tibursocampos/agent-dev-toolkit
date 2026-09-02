# Adapters

Public adapter contract for `agent-dev-toolkit`: shared **core** published into each agent install layout via concrete adapter modules.

## Purpose

Adapters map shared **core** into each agent’s install layout and expose a stable PowerShell surface for sync, validate, and smoke. Orchestrators (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolve an agent via `adapters/registry.json`, then call the module named on that entry.

### Orchestrators

| Script | Behavior |
|--------|----------|
| `scripts/toolkit.ps1` | Menu or `-Action`/`-Agent`. Lists registry agents; Sync/Validate/Uninstall **require** agent (no silent Cursor/home default). Forwards Sync/Validate to sync-agent / validate-agent; Uninstall calls the selected adapter’s `Uninstall-Toolkit`. **Backup** is a fail-closed CLI stub only (`-Action Backup`) — it does **not** call an adapter. |
| `scripts/sync-agent.ps1 -Agent <id>` | Loads registry entry + module; calls `Publish-*`, then always `Get-SddRoot -Prepare`. Unknown or incomplete adapters exit ≠ 0 with an explicit **not implemented** message (TE04). Defaults `InstallRoot` to in-repo fixture; refuse USERPROFILE without `-AllowUserHome`. |
| `scripts/validate-agent.ps1 -Agent <id>` | Always runs `validate-core`. Then `Invoke-SmokeValidate` against fixture `InstallRoot`. When smoke is not applicable for an agent, it is a **documented no-op** (does not fail the run). Missing/unknown `-Agent` still abort (TE01/TE02). |

## Registry

File: `adapters/registry.json`

| Field | Meaning |
|-------|---------|
| `id` | CLI / `-Agent` id (kebab-safe token) |
| `displayName` | Human label |
| `module` | Path relative to `adapters/` (dot-source target) |
| `capabilities` | Capability map: boolean publish flags (`skills`, `rules`, `hooks`, `router`, `plugin`, `agents`) + string `subagents` enum (`native` \| `none`) |
| `publishSurface` | Optional whole-file router targets the adapter may publish (`wholeFileRouter`: relative paths under InstallRoot). Antigravity uses managed markdown blocks (`[]`); Copilot folds router into `copilot-instructions.md` via `Publish-Policy` (`[]`). Sync records sha256 in InstallRoot `.toolkit-managed-publish.json`; uninstall removes whole-file routers only when inventory hash matches. |

### Registered agents

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

Every listed agent has a concrete module with publish + in-repo smoke. See the per-agent sections below.

## Official install roots (contract)

Live Sync wizard **[1]** resolves `Get-InstallRoots` → `OfficialUserRootPath` (Enter = live home). CI and non-interactive defaults still use in-repo fixtures unless `-AllowUserHome` is set.

| Agent | Live InstallRoot | Skills / rules / hooks (summary) | Skill invoke | Notes |
|-------|------------------|----------------------------------|--------------|-------|
| `cursor` | `~/.cursor` | `skills/`, `rules/*.mdc`, `hooks.json`, `AGENTS.md` | `/id` (e.g. `/help-skills`) | Also reads `~/.agents/skills` / project `.cursor/` |
| `antigravity` | `~/.gemini` | ADT publishes `config/skills`, `config/skills.json`, `config/AGENTS.md`, `config/plugins/…/GUARDRAILS.md`, `config/hooks` PreToolUse guard | `use skill id` or `/id` | Twin IDE steering often points skills/GUARDRAILS under `antigravity-ide/plugins/<id>/` via `skills.json` — see adapter README. AppData `agy\bin` = binary only |
| `claude` | `~/.claude` | `skills/`, `rules/`, `CLAUDE.md`, hooks in `settings.json` | `/id` (e.g. `/sdd-spec`) | Project scope also uses repo `.claude/` |
| `codex` | `~/.codex` | Dual-root: config/AGENTS/hooks under `~/.codex`; plugin under `InstallRoot/plugin`; **`$` discovery** via `InstallRoot/skills` (`~/.codex/skills`); optional `-UserScope` `~/.agents/skills` (opt-in only — duplicates `$` if both); rules under `InstallRoot/rules` | `$id` (e.g. `$help-skills`) | Plugin packaging ≠ `$` feed; `/hooks` is trust UI, not skill invoke; no `$skill --menu` flag |
| `copilot` | `~/.copilot` or `.github` | `-Mode user\|repo`; `skills/`, `instructions/`, `copilot-instructions.md`, `hooks/` | `/id`; after sync `/skills reload` | Same relative tree both modes |
| `opencode` | `~/.config/opencode` | `skills/`, `AGENTS.md`, hooks = JS `plugins/` | `skill` tool: `skill({ name: "…" })` | Not `~/.opencode`; not slash-first |
| `grok` | `~/.grok` | `skills/`, `rules/`, `hooks/`, `AGENTS.md` under InstallRoot (= live `~/.grok`) | `/id` (e.g. `/help-skills`) | Also reads Claude/Cursor layouts; adapter writes native. `/hooks-trust` = trust UI |
| `zcode` | `~/.zcode` | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` | `$id` (e.g. `$help-skills`) | ADE filesystem — not GLM Coding Plan |
| `hermes` | `$HERMES_HOME` (Win: `%LOCALAPPDATA%\hermes`; POSIX: `~/.hermes`) | `skills/`, `AGENTS.md` (folded policy; no `rules/`); seed `memories/MEMORY.md` if missing; plugin + `agent-hooks` path/secrets | `/id` (e.g. `/help-skills`) | Never `SOUL.md`; `delegate_task`; keyed `config.yaml` plugins.enabled / hooks.pre_tool_call only |
| `openhands` | Project tree; user skills `~/.agents` | Project: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/` hooks, `.plugin/plugin.json` | Agent Skills (product discovery; mention skill id) | Not microagents. User skills: `-InstallRoot ~/.agents -AllowUserHome`. `subagents=none` |

Primary audit source for adapter paths: this table + each agent section below + `adapters/<id>/README.md`.

## Capabilities

Flags on each registry entry and on `Get-Capabilities` output:

| Flag | Intent |
|------|--------|
| `skills` | Can publish Agent Skills from `core/skills/` |
| `rules` | Can publish policy/rules from `core/policy/` |
| `hooks` | Can publish hooks |
| `router` | Can publish router material from `core/router/` |
| `plugin` | Agent uses a plugin/extension packaging surface |
| `agents` | Can publish roster custom subagent markdown from `core/agents/` into the host `agents/` directory |
| `subagents` | String enum `native` \| `none` — host Task/equivalent for SPAWN (`core/skills/_shared/agents/SPAWN.md`). **Not** boolean. Stub/`Get-Capabilities` defaults must never mint `native`. Per-adapter evidence and host spawn mechanism: each `adapters/<id>/README.md` (**Spawn / subagents**). Matrix: [SPAWN.md](SPAWN.md). |

Honesty matrix (**registry** publish surfaces — do not claim unsupported ones):

| Agent | skills | rules | hooks | router | plugin | agents | Notes |
|-------|--------|-------|-------|--------|--------|--------|-------|
| `cursor` | true | true | true | true | false | true | `Publish-Agents` → `InstallRoot/agents/` |
| `antigravity` | true | true | true | true | true | false | PreToolUse path/secrets under `config/hooks`; `Publish-Agents` no-op; Sidecars/Automations OOS |
| `claude` | true | true | true | true | false | true | Hooks smoke = files only; trust UI out of scope; PreToolUse path/secrets deny wired |
| `codex` | true | true | true | true | true | true | Dual-root; PreToolUse path/secrets; `Publish-Agents` → `agents/*.toml`; `/hooks` trust manual |
| `copilot` | true | true | true | false | false | true | `Publish-Router` no-op; hooks `version:1` + `preToolUse` guard; Mode repo agents |
| `opencode` | true | false | true | true | true | true | `HooksSemantics=plugin-only` (JS `tool.execute.before` path/secrets throw); `Publish-Agents` → `InstallRoot/agents/` |
| `grok` | true | true | true | true | false | true | Native under `~/.grok`; PreToolUse path/secrets; `Publish-Agents` → `InstallRoot/agents/` |
| `zcode` | true | false | true | true | false | true | `Publish-Policy` no-op; PreToolUse path/secrets; `Publish-Agents` → `InstallRoot/agents/` |
| `hermes` | true | true | true | true | true | false | Native under `$HERMES_HOME`; policy folded into `AGENTS.md` (no `rules/`); plugin + shell dual hooks; `Publish-Agents` no-op; `memories/MEMORY.md` seed-if-missing; never SOUL.md |
| `openhands` | true | true | true | true | true | true | Project tree; policy folded into `AGENTS.md`; shell `pre_tool_use` path/secrets (`guard_pre_tool.sh`); `Publish-Agents` → `.agents/agents/` (roster, not native spawn); `subagents=none` |

### Shared path/secrets guard (native)

Rules: [`adapters/_shared/guard-rules.md`](../adapters/_shared/guard-rules.md) · helpers: [`GuardCommon.ps1`](../adapters/_shared/GuardCommon.ps1). Outside-workspace paths and write/delete without a resolvable path are **deny** (fail-closed). Host wiring (summary):

| Agent | Wiring |
|-------|--------|
| Cursor | `preToolUse` Write/Edit/Shell/Delete + `beforeShellExecution`; `failClosed`; GuardCommon |
| Claude | PreToolUse `Write\|Edit\|Bash\|PowerShell` → `permissionDecision` deny |
| Codex | PreToolUse + `agents/*.toml` |
| Copilot | hooks `version:1` `preToolUse` |
| OpenHands | `pre_tool_use` + `guard_pre_tool.sh` (fail-closed) |
| ZCode | PreToolUse |
| Grok | PreToolUse; `agents=true` → `InstallRoot/agents/` |
| OpenCode | JS `tool.execute.before` throw; `agents=true` → `InstallRoot/agents/` |
| Antigravity | `hooks=true`; `config/hooks` PreToolUse |
| Hermes | `hooks=true` + `plugin=true`; plugin `agent-dev-toolkit-guard` + `agent-hooks`; keyed `config.yaml` only `plugins.enabled` / `hooks.pre_tool_call`; **never** SOUL / tokens / gateway |

Most adapters declare `subagents: native` (host product docs), including **Antigravity**. **OpenHands** declares `none` (Canvas/ACP is not parent→child; SPAWN fallback in-parent). **Antigravity** *effective* capability is fail-closed via `Get-Capabilities` probe (`ADT_ANTIGRAVITY_SUBAGENTS` / `agy` / product version) — pré-2.0 or unverifiable → `none`. `validate-core` checks registry, each module’s `Get-Capabilities` (Antigravity with CI override), orchestrate SPAWN/fallback text, and Antigravity probe cases. CI adapter smokes stay filesystem sync/validate — no duplicate spawn matrix there.

## Cursor (`cursor`) — publish + smoke

| Item | Value |
|------|-------|
| Agent id | `cursor` |
| Module | `adapters/cursor/CursorAdapter.ps1` |
| Official user root | `~/.cursor` (relative `.cursor` under USERPROFILE) |
| Official docs | [Rules + AGENTS.md](https://cursor.com/docs/rules), [Skills](https://cursor.com/docs/context/skills), [Hooks](https://cursor.com/docs/hooks), [Subagents](https://cursor.com/docs/context/subagents), [Agent best practices](https://cursor.com/blog/agent-best-practices) |
| Fixture | `scripts/validation/fixtures/cursor-install-root` (InstallRoot models the Cursor root; seed may include custom `hooks.json`) |
| Fixture override | `-InstallRoot <path>` (CI default: in-repo fixture; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `agents` = true; `plugin` = false |
| Key artifacts | `skills/`, `rules/*.mdc`, `AGENTS.md`, `agents/*.md`, `hooks/*.ps1`, `hooks.json`, `sdd/sessions`, `sdd/manifest.json` |
| Content source | `core/` only |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent cursor` — **no** Cursor trust UI, **no** live `~/.cursor` writes in CI |
| Path/secrets guard | `preToolUse` (`Write\|StrReplace\|Delete\|Shell`) + `beforeShellExecution` → `guard-pre-tool.ps1` (`failClosed`); shared rules in `adapters/_shared/` |

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved) |
| `rules/*.mdc` | `Publish-Policy` from `core/policy/` (`.md` → `.mdc`; no orphan `.md` rules) |
| `AGENTS.md` | `Publish-Router` from `core/router/AGENTS.md` |
| `agents/*.md` | `Publish-Agents` from `core/agents/` (roster: repo-analyst, architect, database, security, shell-runner) |
| `hooks/*.ps1` | `Publish-Hooks` from `adapters/cursor/assets/hooks/` (includes `guard-pre-tool.ps1` + published `GuardCommon.ps1`) |
| `hooks.json` | Merge at InstallRoot root (user entries preserved by `command`; invalid JSON fail-closed). Wires path/secrets `preToolUse` + `beforeShellExecution` |
| `sdd/sessions/` + `sdd/manifest.json` | `Get-SddRoot -Prepare` (seed manifest only when absent) |

### Sync / validate (CI-safe)

```powershell
$cursorFixture = Join-Path $PWD 'scripts\validation\fixtures\cursor-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
# CI / local harness (ephemeral work root; keeps versioned seed intact):
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
```

CI uses the in-repo fixture (or ephemeral copy) only. Do not sync to a live `~/.cursor` for green CI. Live home sync requires `-AllowUserHome` and stays **outside** CI.

### Uninstall

Keyed removal of toolkit skills / rules / hooks / `AGENTS.md`, plus reverse-merge of managed `hooks.json` handlers. Preserves `sdd/sessions/` and `sdd/manifest.json`. Alien files stay. WhatIf supported. CI: `Assert-CursorKeyedUninstall.ps1`.

## Antigravity (`antigravity`) — capabilities + InstallRoots

| Item | Value |
|------|-------|
| Agent id | `antigravity` |
| Module | `adapters/antigravity/AntigravityAdapter.ps1` |
| Official user root | `~/.gemini` (relative `.gemini` under USERPROFILE) |
| Official layout (under InstallRoot modeling `~/.gemini`) | `config/skills`, `config/plugins`, `config/hooks`, `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` |
| Twin IDE steering (not ADT default publish) | Working Antigravity IDE toolkits often register skills via `config/skills.json` → absolute path under `antigravity-ide/plugins/<id>/skills/` and GUARDRAILS beside that plugin; ADT publishes under `config/*` (see adapter README) |
| Official docs | [Home](https://antigravity.google/docs/home), [Skills](https://antigravity.google/docs/skills), [Rules & workflows](https://antigravity.google/docs/rules-workflows), [Subagents](https://antigravity.google/docs/subagents), [Hooks](https://antigravity.google/docs/hooks), [Plugins](https://antigravity.google/docs/plugins) |
| Legacy bridge (non-default) | `antigravity-ide/plugins` — documentation / opt-in only; **not** a CI/smoke gate |
| Fixture override | `-InstallRoot <path>` (in-repo fixture for CI; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `plugin` = true; `agents` = false |
| Key artifacts | kebab skills + `skills.json`, GUARDRAILS / `dev_persona` from core, managed `AGENTS.md` / `GEMINI.md`, `config/hooks` PreToolUse guard |
| `Publish-Hooks` | Writes `config/hooks/hooks.json` + `guard-pre-tool.ps1` (matcher `write_to_file\|replace_file_content\|multi_replace_file_content\|run_command` → `{ decision, reason }`). Legacy bridge untouched. Sidecars/Automations OOS. |
| `Publish-Agents` | **No-op** (`agents=false`): Success/Implemented. Host spawn is `invoke_subagent` only — no custom agent markdown files. |
| `Invoke-SmokeValidate` | Filesystem-only under InstallRoot (kebab skills, `skills.json`, GUARDRAILS, `dev_persona`, managed AGENTS/GEMINI, hooks when capable). Legacy bridge not gated. |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts only (core skill folders, `dev_persona`, managed plugin dir, managed `skills.json` entry, managed markdown blocks, toolkit `config/hooks` files). Preserves alien skills / legacy bridge. Preserves `sdd/sessions` + `sdd/manifest.json`. |

Default smoke/CI targets the **official** `config/*` layout under InstallRoot (kebab skills only — no underscore rename). The path `antigravity-ide/plugins` remains a **legacy bridge** only — documentation / opt-in / **read-only** (not a CI or default-smoke gate).

**Out of scope:** live Knowledge Items (KI) injection; IDE trust UI / interactive prompts. CI covers Antigravity via `Invoke-AntigravityCiSmoke.ps1` (ephemeral fixture filesystem sync+validate — no live `~/.gemini`).

`Publish-Skills` / `Publish-Policy` / `Publish-Router` / `Publish-Agents` (no-op) / `Publish-Hooks` / `Invoke-SmokeValidate` / `Uninstall-Toolkit` are implemented. Operator E2E:

```powershell
$antigravityFixture = Join-Path $PWD 'scripts\validation\fixtures\antigravity-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity -InstallRoot $antigravityFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent antigravity -InstallRoot $antigravityFixture
# default InstallRoot = FixtureRelativePath (same fixture):
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent antigravity
```


## GitHub Copilot (`copilot`) — Mode user|repo

| Item | Value |
|------|-------|
| Agent id | `copilot` |
| Module | `adapters/copilot/CopilotAdapter.ps1` |
| Required CLI flag | `-Mode user\|repo` (missing/invalid → TE02) |
| Mode `user` | InstallRoot models `~/.copilot` |
| Mode `repo` | InstallRoot models `.github` (fixture — not the toolkit working-tree `.github` by default) |
| Fixtures | `scripts/validation/fixtures/copilot/user`, `scripts/validation/fixtures/copilot/repo` |
| Fixture override | `-InstallRoot <path>` (CI default: in-repo fixture; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `agents` = true; `router` / `plugin` = false |
| Key artifacts (relative under InstallRoot) | `skills/<kebab-id>/SKILL.md`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/*`; Mode repo also `agents/*.md` |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent copilot -Mode <mode>` — **no** Copilot IDE extension, **no** GitHub login, **no** user profile |
| Uninstall | Keyed removal of toolkit skills / instructions / hooks only (RN07 — no wholesale wipe of `~/.copilot` or `.github`). Preserves `sdd/sessions` + `sdd/manifest.json` |

### Mode user vs Mode repo

| Mode | Models | Typical live path | CI InstallRoot |
|------|--------|-------------------|----------------|
| `user` | Personal Copilot root | `~/.copilot` | `scripts/validation/fixtures/copilot/user` |
| `repo` | Repo customization root | `<repo>/.github` | `scripts/validation/fixtures/copilot/repo` |

Relative layout under either InstallRoot is the same: `skills/`, `instructions/`, `copilot-instructions.md`, `hooks/`. The Mode flag selects which official root is modeled, not a different relative tree.

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved; kebab ids preserved) |
| `instructions/*.instructions.md` | `Publish-Policy` from `core/policy/` (`.md` → `*.instructions.md`; no fake Cursor `.mdc`) |
| `copilot-instructions.md` | `Publish-Policy` from `core/router/AGENTS.md` (always-on instructions) |
| `hooks/*` | `Publish-Hooks` from `adapters/copilot/assets/hooks/` when `hooks=true` — `version:1` `hooks.json` + `preToolUse` → `guard-pre-tool.ps1` (path/secrets deny; IDE trust out of scope) |
| `agents/*.md` | `Publish-Agents` from `core/agents/` **Mode repo only** (`.github/agents/`). Mode user is a documented no-op (no Copilot user-home agents dir). |

`Publish-Router` is a documented **no-op** (`router=false`). Router guidance is folded into `copilot-instructions.md` via `Publish-Policy`.

### Out of scope (CA7 / RN03)

**JetBrains** and **Eclipse** Copilot IDE layout paths are **out of scope**. This adapter publishes only official surfaces: `~/.copilot/...` (Mode user) and `.github/...` (Mode repo). Do not invent host-IDE trees for smoke or docs.

### Sync / validate (CI-safe)

```powershell
$copilotUser = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$copilotRepo = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
# matrix (both modes + home guard):
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
```

CI green does **not** use a Copilot user profile, VS Code/JetBrains/Eclipse runtime, or GitHub login. Live home sync requires `-AllowUserHome` and stays **outside** CI.

### Official docs (GitHub Copilot)

- [Customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
- [About agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Add skills (CLI)](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [Add custom instructions (CLI)](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)
- [Hooks](https://docs.github.com/en/copilot/concepts/agents/hooks)

## Claude Code (`claude`) — publish + smoke

| Item | Value |
|------|-------|
| Agent id | `claude` |
| Module | `adapters/claude/ClaudeAdapter.ps1` |
| Official user root | `~/.claude` (relative `.claude` under USERPROFILE) |
| Official project scope | `.claude/` under the repository root (e.g. `.claude/settings.json`) |
| Official docs | [Features](https://code.claude.com/docs/en/features-overview), [Memory / rules](https://code.claude.com/docs/en/memory), [Skills](https://code.claude.com/docs/en/skills), [Hooks](https://code.claude.com/docs/en/hooks), [`.claude` directory](https://code.claude.com/docs/en/claude-directory), [Steering blog](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more) |
| Fixture | `scripts/validation/fixtures/claude/` (InstallRoot models the Claude root; includes pre-existing `settings.json` for merge CT) |
| Fixture override | `-InstallRoot <path>` (CI default: in-repo fixture; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `agents` = true; `plugin` = false |
| Key artifacts | `skills/`, `rules/*.md`, `hooks/*.ps1`, `CLAUDE.md`, `agents/*.md`, merged `settings.json` |
| Content source | `core/` only (packaging layout may follow Claude / ai-prompts docs as **reference** — never copy Athena content) |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent claude` — **no** Claude trust UI, **no** live `~/.claude` writes in CI |

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved) |
| `rules/*.md` | `Publish-Policy` from `core/policy/` (keep `.md`; not Cursor `.mdc`) |
| `CLAUDE.md` | `Publish-Router` from `core/router/AGENTS.md` (`.mdc` refs rewritten to `.md`) |
| `agents/*.md` | `Publish-Agents` from `core/agents/` |
| `hooks/*.ps1` | `Publish-Hooks` from `adapters/claude/assets/hooks/` |
| `settings.json` | Merge after hooks publish (see below) |

### settings.json merge (RN03–RN05 / RN08)

| Rule | Behavior |
|------|----------|
| Backup | Write `settings.json.bak` before overwrite |
| Hooks | Keyed upsert for managed events (`UserPromptSubmit`, `PreCompact`, `PostToolUse`, `PreToolUse`); alien events preserved |
| `permissions.allow` | Additive **narrow** toolkit entries — one `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` per managed hook; no duplicates on re-sync; user allows preserved. Re-sync **strips** legacy broad `Bash(pwsh *)` / `Bash(powershell *)` unless `-AllowBroadShellPermissions` |
| Other keys | Preserved as-is (no wholesale replace) |
| Encoding | UTF-8 **without BOM** |
| Invalid JSON | Abort; do not overwrite (TE01) |
| Backup failure | Abort; no write (TE02) |

`PreToolUse` matcher `Write|Edit|Bash|PowerShell` runs `guard-pre-tool.ps1` and returns Claude `hookSpecificOutput.permissionDecision` deny/allow (path + secrets). Hook **trust UI** remains out of smoke/CI scope — green means files + merge completeness only.

### Sync / validate (CI-safe)

```powershell
$claudeFixture = Join-Path $PWD 'scripts\validation\fixtures\claude'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude -InstallRoot $claudeFixture
# CI / local harness (ephemeral work root; keeps versioned seed intact):
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
```

CI uses the in-repo fixture (or ephemeral copy) only. Do not sync to a live `~/.claude` for green CI.

### Uninstall

Keyed removal of toolkit skills / rules / hooks / `CLAUDE.md`, plus reverse-merge of managed hooks events and toolkit `permissions.allow` entries. Alien files and unrelated settings keys stay. Preserves `sdd/sessions` + `sdd/manifest.json`. WhatIf supported. Module notes: `adapters/claude/README.md`.

## Codex (`codex`) — plugin + smoke

| Item | Value |
|------|-------|
| Agent id | `codex` |
| Module | `adapters/codex/CodexAdapter.ps1` |
| Packaging | Codex **plugin** under InstallRoot `plugin/` (`.codex-plugin/plugin.json` + bundled skills + hooks) |
| Official product home | `~/.codex` (config.toml, AGENTS.md, hooks, agents) — live wizard InstallRoot |
| Official USER skills | `~/.agents/skills` (fixture: `InstallRoot/.agents/skills` via optional `-UserScope`) |
| Official `$` skills mirror | `InstallRoot/skills` (live `~/.codex/skills`) — feeds `$id` discovery; plugin path alone does **not** |
| Official marketplace | `.agents/plugins/marketplace.json` (fixture models local `source.path` `./plugin`) |
| Official docs | [Codex](https://developers.openai.com/codex), [plugins](https://developers.openai.com/codex/plugins), [skills](https://developers.openai.com/codex/skills), [hooks](https://developers.openai.com/codex/hooks), [config basic](https://developers.openai.com/codex/config-basic), [AGENTS.md](https://developers.openai.com/codex/guides/agents-md/) |
| Fixture | `scripts/validation/fixtures/codex` (pass `-InstallRoot`; USERPROFILE requires `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `plugin` / `agents` = true |
| Key artifacts | `plugin/.codex-plugin/plugin.json`, `plugin/skills/<id>/SKILL.md`, `rules/*.md`, `.agents/plugins/marketplace.json`, materialized `AGENTS.md`, `plugin/hooks/hooks.json` + `guard-pre-tool.ps1` |
| Hooks trust | Codex `/hooks` UI is **manual**; smoke/CI never invoke or require trust (RN03). PreToolUse path/secrets deny is filesystem-published only until trusted. |

### Dual-root honesty (skills vs rules)

| Surface | Location | `TOOLKIT_ROOT` note |
|---------|----------|---------------------|
| Plugin skills + CATALOG | `InstallRoot/plugin` (skills under `plugin/skills/`) | Plugin packaging; **does not** feed `$` by itself |
| `$` discovery mirror | `InstallRoot/skills` (live `~/.codex/skills`) | Feeds `$id` invoke |
| Rules / guardrails | `InstallRoot/rules/*.md` (Publish-Policy from `core/policy/`) | Rules are **not** under the plugin skills tree |
| Product / AGENTS / hooks parent | `InstallRoot` (live `~/.codex`) | Router + hooks parent |
| Optional UserScope (opt-in) | Fixture `InstallRoot/.agents/skills` · live `$HOME/.agents/skills` | Extra USER discovery — **do not** enable with home skills or `$` duplicates |

**Skill invoke:** `$id` (e.g. `$help-skills`). Native `$` or `/skills` picker = product skills menu — **not** a `--menu` flag. Codex `/hooks` = hooks trust UI, not skill invoke.

Do **not** resolve skill `_shared` under `InstallRoot/rules`. Destination-aware materialization: Publish-Router rewrites `{{TOOLKIT_ROOT}}/rules/` → InstallRoot rules tree, then remaining `{{TOOLKIT_ROOT}}` → plugin root.

### Plugin skills vs UserScope

| Scope | Path | When written |
|-------|------|--------------|
| Plugin-bundled (default) | `InstallRoot/plugin/skills/<kebab-id>/SKILL.md` | Default `Publish-Skills` |
| USER mirror (fixture) | `InstallRoot/.agents/skills/<kebab-id>/SKILL.md` | `Publish-Skills -UserScope` when InstallRoot is **not** live `~/.codex` |
| USER mirror (live) | `$HOME/.agents/skills/<kebab-id>/SKILL.md` | `Publish-Skills -UserScope` when InstallRoot is live `~/.codex` **and** `-AllowUserHome` |

Default sync is **plugin-only**. Smoke treats an **absent or empty** USER skills root as OK without `-UserScope`. CI/fixtures never require a live `$HOME/.agents/skills` write. Live UserScope without `-AllowUserHome` fails closed.

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `plugin/.codex-plugin/plugin.json` | Plugin manifest (`skills: ./skills/`) |
| `plugin/skills/<kebab-id>/SKILL.md` | Bundled skills from `core/skills/` (incl. `help-skills` + `_shared/skills-catalog/CATALOG.md` + `OPERATOR.md`) |
| `rules/*.md` | `Publish-Policy` from `core/policy/` (`rules=true`) |
| `.agents/plugins/marketplace.json` | Local marketplace entry (`source.path` `./plugin`) |
| `AGENTS.md` | `Publish-Router`: materialized dual-root **absolute** paths; **no** `{{…}}` placeholders; **no** live `docs/` links |
| `agents/*.toml` | `Publish-Agents` converts `core/agents/*.md` → Codex custom agent TOML (`name`, `description`, `developer_instructions`) under InstallRoot/agents/ |
| `plugin/hooks/hooks.json` | `Publish-Hooks` PreToolUse for `Bash` + `apply_patch\|Edit\|Write` → `guard-pre-tool.ps1` (filesystem only; trust `/hooks` out of smoke) |
| `.agents/skills/` | Optional `-UserScope` mirror of `core/skills` (fixture stand-in) |

### Smoke / sync (filesystem only — no `/hooks` trust)

| Command | Behavior |
|---------|----------|
| `Publish-Skills` | Plugin manifest + skills + marketplace; optional `-UserScope` USER mirror |
| `Publish-Policy` | Copies `core/policy` → `InstallRoot/rules/*.md` |
| `Publish-Router` | Materializes `AGENTS.md` (absolute dual-root paths; no placeholders; no `docs/` links) |
| `Publish-Agents` | Emits `core/agents/*.md` → `InstallRoot/agents/*.toml` (live `~/.codex/agents/`) |
| `Publish-Hooks` | Writes PreToolUse guard files under `plugin/hooks/` |
| `Invoke-SmokeValidate` | Asserts plugin, help-skills/CATALOG/OPERATOR, marketplace, `rules/*.md`, materialized `AGENTS.md`, hooks files; optional UserScope when mirrored; `RequiresHooksTrust=false` |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts only (no wipe of `plugin/` / `.agents` / alien files). Preserves `sdd/sessions` + `sdd/manifest.json` |
| `validate-agent -Agent codex` | Core validate + adapter smoke against fixture InstallRoot |

CI green does **not** use Codex trust UI `/hooks`. Operator may review/trust hooks on a real install **outside** CI (RN03).

```powershell
$codexFixture = Join-Path $PWD 'scripts\validation\fixtures\codex'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot $codexFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent codex -InstallRoot $codexFixture
```

### Official docs (OpenAI Codex)

- [Codex overview](https://developers.openai.com/codex)
- [Plugins](https://developers.openai.com/codex/plugins)
- [Skills](https://developers.openai.com/codex/skills)
- [Hooks](https://developers.openai.com/codex/hooks) (trust/review of plugin hooks is a human step)

## OpenCode (`opencode`) — publish + smoke

| Item | Value |
|------|-------|
| Agent id | `opencode` |
| Module | `adapters/opencode/OpenCodeAdapter.ps1` |
| Official user root | `~/.config/opencode` (relative `.config/opencode` under USERPROFILE) |
| Official docs | [opencode.ai](https://opencode.ai), [rules](https://opencode.ai/docs/rules/), [skills](https://opencode.ai/docs/skills/), [config](https://opencode.ai/docs/config/), [agents](https://opencode.ai/docs/agents/), [plugins](https://opencode.ai/docs/plugins/) |
| Fixture | `scripts/validation/fixtures/opencode/` (InstallRoot models the config root; does **not** nest another `.config/opencode`) |
| Fixture override | `-InstallRoot <path>` (CI default: in-repo fixture; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `hooks` / `router` / `plugin` / `agents` = true; `rules` = false |
| Hooks semantics | `HooksSemantics=plugin-only` — OpenCode uses **JavaScript plugins**, not shell/PS1 hooks (unlike Cursor/Claude). Smoke never requires `.ps1` hooks |
| MVP hooks (Decision A) | `Publish-Hooks` copies `plugins/agent-dev-toolkit-marker.js` with `tool.execute.before` path/secrets deny (throw) |
| Key artifacts | `skills/<kebab-id>/SKILL.md`, `AGENTS.md`, `agents/*.md`, `plugins/agent-dev-toolkit-marker.js` |
| `Publish-Policy` | Documented **no-op** (`rules=false`; no dedicated OpenCode policy surface) |
| `Publish-Agents` | Copies `core/agents/` → `InstallRoot/agents/` (`agents=true`) |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent opencode` / `Invoke-OpenCodeCiSmoke.ps1` — **no** OpenCode product runtime, **no** real `~/.config/opencode` writes in CI |
| Uninstall | Keyed removal of toolkit skills, `AGENTS.md`, and the marker plugin only (RN07 — no wholesale wipe). Preserves `sdd/sessions` + `sdd/manifest.json` |

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved; kebab ids preserved) |
| `AGENTS.md` | `Publish-Router` from `core/router/AGENTS.md` |
| `agents/*.md` | `Publish-Agents` from `core/agents/` |
| `plugins/agent-dev-toolkit-marker.js` | `Publish-Hooks` Decision A plugin (`tool.execute.before` path/secrets deny) |

### Hooks: plugin JS vs shell/PS1

Other agents (e.g. Cursor) may publish shell or PowerShell hook scripts. OpenCode does **not**: behavior extensions are JS plugins under `plugins/` ([official plugins docs](https://opencode.ai/docs/plugins/)). Claiming PS1 hook parity would be dishonest (RN03/RN04). Capability flags stay honest: `hooks=true` + `plugin=true` + `HooksSemantics=plugin-only`.

### Sync / validate (CI-safe)

```powershell
$opencodeFixture = Join-Path $PWD 'scripts\validation\fixtures\opencode'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent opencode -InstallRoot $opencodeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent opencode -InstallRoot $opencodeFixture
```

CI uses the in-repo fixture only. Do not sync to a live `~/.config/opencode` for green CI.

## ZCode (`zcode`) — Z.ai ADE

| Item | Value |
|------|-------|
| Agent id | `zcode` |
| Module | `adapters/zcode/ZCodeAdapter.ps1` |
| Official user root | `~/.zcode` (relative `.zcode` under USERPROFILE) |
| Official docs | [Agents](https://zcode.z.ai/en/docs/agents), [Subagents](https://zcode.z.ai/en/docs/subagents), [Skills](https://zcode.z.ai/en/docs/skill), [Hooks](https://zcode.z.ai/en/docs/hooks), [Plugins](https://zcode.z.ai/en/docs/plugin) |
| Fixture override | `-InstallRoot <path>` (in-repo fixture `scripts/validation/fixtures/zcode-install-root`; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `hooks` / `router` / `agents` = true; `rules` / `plugin` = false |
| Key artifacts under InstallRoot | `skills/<id>/SKILL.md`, `AGENTS.md`, `agents/*.md`, `cli/config.json`, `hooks/hooks.json` + PreToolUse path/secrets, `sdd/sessions/`, `sdd/manifest.json` |

### Install layout (relative to InstallRoot / `~/.zcode`)

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills from `core/skills/` |
| `AGENTS.md` | Router surface from `core/router/AGENTS.md` (no Cursor `rules/*.mdc` tree) |
| `agents/*.md` | `Publish-Agents` from `core/agents/` (live `~/.zcode/agents/`) |
| `cli/config.json` | Hooks config (`hooks.enabled: true` when applicable) |
| `hooks/hooks.json` | User-level hooks merge; PreToolUse path/secrets deny + exit 2 |
| `sdd/sessions/` + `sdd/manifest.json` | `Get-SddRoot -Prepare` (seed manifest only when absent) |

`Publish-Policy` is a documented **no-op** (`rules=false`). Marketplace/plugin `.zcode-plugin` packaging and ADE UI trust flows are out of MVP scope. Placeholders `{{TOOLKIT_ROOT}}` / `{{SDD_ROOT}}` / `{{GUARDRAILS_PATH}}` resolve only at the destination.

### Smoke / sync (in-repo)

```powershell
$zcodeFixture = Join-Path $PWD 'scripts\validation\fixtures\zcode-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent zcode -InstallRoot $zcodeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent zcode -InstallRoot $zcodeFixture
# CI / local harness (fixture only; never AllowUserHome):
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1
```

Default smoke never writes under `%USERPROFILE%\.zcode` unless `-AllowUserHome` is set. CI runs `Invoke-ZCodeCiSmoke.ps1` on the in-repo fixture only (CA3).

### Uninstall

`Uninstall-Toolkit` performs keyed removal (core skill folders, `AGENTS.md`) plus reverse-merge of `cli/config.json` / `hooks/hooks.json`. Preserves alien files and `sdd/sessions` / `sdd/manifest.json`. Does **not** wipe InstallRoot. CI: `Assert-ZcodeKeyedUninstall.ps1`.

### Not GLM Coding Plan (CA5 / RN04)

**GLM Coding Plan** (Z.ai endpoint / Base URL / MCP only — skills stay on the host) is **not** this adapter and remains **out of scope**. Do not use agent id `zcode` for endpoint-only GLM setup.

This module covers **ZCode (Z.ai ADE)** filesystem surfaces only: skills, `AGENTS.md`, and hooks/config under `.zcode`. Use the ZCode ADE adapter here, or the host agent’s own adapter, when you need skill/hooks publish — not GLM Coding Plan.

## Grok Build (`grok`) — native `~/.grok`

| Item | Value |
|------|-------|
| Agent id | `grok` |
| Module | `adapters/grok/GrokAdapter.ps1` |
| Official user root | `~/.grok` (relative `.grok` under USERPROFILE) — **InstallRoot is this directory** |
| Official project scope | Pass project `.grok/` as InstallRoot (skills/rules/hooks directly under it) |
| Expected live skills | `~/.grok/skills` (product path; not `~/.grok/.grok/skills`) |
| Fixture | `scripts/validation/fixtures/grok` (models `~/.grok`; pass `-InstallRoot`; USERPROFILE requires `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `agents` = true; `plugin` = false |
| Native layout | `skills/<id>/SKILL.md`, `rules/*.md`, `agents/*.md`, `hooks/*.json` (+ `session_start.ps1`, `guard-pre-tool.ps1`) under InstallRoot |
| Router | `AGENTS.md` at InstallRoot (from `core/router`) |
| Skill invoke | `/id` (e.g. `/help-skills`) |
| Hooks trust | `/hooks-trust` or `--trust` is **manual** (trust UI, not skill invoke); smoke/CI never write `trusted_folders.toml`. PreToolUse path/secrets deny is filesystem-published. |

### Native write vs Claude/Cursor compat (RN02)

Grok Build can also **read** Claude/Cursor artifacts (`CLAUDE.md`, `.claude/`, `.cursor/`). This adapter **must publish natively** under InstallRoot (`skills|rules|hooks`) — it is not enough to mirror only Claude/Cursor layouts and rely on compat. `Invoke-SmokeValidate` fails (TE04) when compat paths exist without the required native artifacts. Do **not** publish relative `.grok/skills` when InstallRoot is already `~/.grok` (that yields `~/.grok/.grok/skills`).

### Publish + smoke (filesystem only)

| Command | Behavior |
|---------|----------|
| `Publish-Skills` | Copies `core/skills` → `skills/` under InstallRoot with placeholder resolve (`TOOLKIT_ROOT` = InstallRoot) |
| `Publish-Policy` | Copies `core/policy` → `rules/*.md` |
| `Publish-Router` | Writes `AGENTS.md`; rewrites `.mdc` → `.md` refs |
| `Publish-Agents` | Copies `core/agents/` → `InstallRoot/agents/` (`agents=true`) |
| `Publish-Hooks` | Writes SessionStart + PreToolUse path/secrets guard under `hooks/` |
| `Invoke-SmokeValidate` | Asserts InstallRoot layout (TE01–TE05); **does not** invoke trust UI |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts only (no wipe of InstallRoot / `config.toml`). Preserves `sdd/sessions` + `sdd/manifest.json` |
| `validate-agent -Agent grok` | Core validate + adapter smoke against fixture InstallRoot |

CI green does **not** use Grok trust UI. Operator may run `/hooks-trust` (or `--trust`) on a real install **outside** CI.

```powershell
$grokFixture = Join-Path $PWD 'scripts\validation\fixtures\grok'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent grok -InstallRoot $grokFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent grok -InstallRoot $grokFixture
```

### Official docs (xAI)

- [Overview](https://docs.x.ai/build/overview)
- [Skills / plugins / marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces)
- [Hooks](https://docs.x.ai/build/features/hooks)
- [Project rules](https://docs.x.ai/build/features/project-rules)

Module notes: `adapters/grok/README.md`.

## Hermes (`hermes`) — native `HERMES_HOME`

| Item | Value |
|------|-------|
| Agent id | `hermes` |
| Module | `adapters/hermes/HermesAdapter.ps1` |
| Official user root | Resolve `HERMES_HOME` (process/user/machine), else Windows `%LOCALAPPDATA%\hermes`, else POSIX/WSL `~/.hermes` — **InstallRoot is that directory** |
| Expected live skills | `$HERMES_HOME/skills` (product path; not a nested `.hermes/skills` under an InstallRoot that already is the home) |
| Fixture | `scripts/validation/fixtures/hermes` (models Hermes home layout; pass `-InstallRoot`; USERPROFILE requires `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `plugin` = true; `agents` = false; `subagents` = `native` |
| Native layout | `skills/<id>/SKILL.md` + `AGENTS.md` under InstallRoot |
| Router + policy | Combined `AGENTS.md` (folded `core/policy` + Hermes-only spawn bridge; **no** `rules/` directory). Project sessions load CWD `AGENTS.md`; always-on SPAWN guidance also ships in published skills |
| Skill invoke | `/id` (e.g. `/help-skills`) |
| `memories/MEMORY.md` | Seeded once if missing; never overwritten |
| `SOUL.md` | **Never** created or overwritten |
| Official docs | [Skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills), [Creating skills](https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills), [Subagent delegation (`delegate_task`)](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation), [Context files](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files), [Hooks](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks), [Plugins](https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins), [Windows Native](https://hermes-agent.nousresearch.com/docs/user-guide/windows-native) |

### Native write vs nested home (RN02)

Publish lands at `skills/` and `AGENTS.md` **directly under** InstallRoot. Do **not** publish relative `.hermes/skills` when InstallRoot is already the Hermes home (that yields a nested `.hermes/.hermes/skills`). `Publish-Policy` folds `core/policy` into `AGENTS.md` and appends the Hermes-only spawn bridge — it does **not** write a `rules/` tree or `.mdc`. `Publish-Hooks` installs `plugins/agent-dev-toolkit-guard` + `agent-hooks/` and keyed-merges only `plugins.enabled` / `hooks.pre_tool_call` in `config.yaml`. `Publish-Agents` is a documented no-op. Core skills/policy/router must **not** teach `delegate_task` outside the SPAWN host map (anti-hallucination for other adapters).

Placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, `{{GUARDRAILS_PATH}}` resolve with **`TOOLKIT_ROOT` = InstallRoot** and **`GUARDRAILS_PATH` = InstallRoot/AGENTS.md**. Re-sync overwrites managed files; alien files under InstallRoot are left alone.

### MEMORY.md seed

On publish, if `memories/MEMORY.md` is absent at InstallRoot, the adapter writes a short seed file under `memories/`. If it already exists, it is left untouched.

### Project skills trust

Official user-home skills (`$HERMES_HOME/skills/`) do **not** need trust. If InstallRoot is **not** that official user home (project copy), Publish-Skills tries `hermes skills trust <InstallRoot>`. If the `hermes` CLI is missing, trust is skipped (publish still succeeds). Publish-Hooks may keyed-merge **only** `plugins.enabled` and `hooks.pre_tool_call` — never gateway tokens or other secrets — and does **not** set `skills.external_dirs` when publishing into the official home.

### Publish + smoke (filesystem only)

| Command | Behavior |
|---------|----------|
| `Publish-Skills` | Copies `core/skills` → `skills/` under InstallRoot with placeholder resolve; `memories/MEMORY.md` seed-if-missing; best-effort `hermes skills trust` |
| `Publish-Policy` | Folds `core/policy` into `AGENTS.md` (no `rules/` directory); appends Hermes-only spawn bridge from `adapters/hermes/assets/spawn-bridge.md` |
| `Publish-Router` | Writes `AGENTS.md` (router + folded policy + spawn bridge); rewrites `.mdc` → `.md` and `rules/` pointers to this file |
| `Publish-Agents` | Documented **no-op** (`agents=false`; no `agents/*.md` roster) |
| `Publish-Hooks` | Plugin `agent-dev-toolkit-guard` + `agent-hooks` shell dual; best-effort `hermes plugins enable`; keyed `config.yaml` merge for `plugins.enabled` + `hooks.pre_tool_call` only |
| `Invoke-SmokeValidate` | Native-layout filesystem assert including plugin/hooks; missing `hermes` CLI is not a CI failure |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts (skills, owned AGENTS.md, plugin, agent-hooks) + reverse-merge keyed config.yaml entries. Preserves secrets, `memories/MEMORY.md`, `SOUL.md`, `sdd/*` |
| `validate-agent -Agent hermes` | Core validate + adapter smoke against fixture InstallRoot |

### Out of scope (do not emit)

Gateway / platform tokens / unrelated `config.yaml` secrets; `cron/jobs.json`; Kanban, voice, Curator, Profiles; `inline_shell`; `delegation.*` YAML. Do **not** invent gateway or sandbox features.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
# scripting:
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes
$hermesFixture = Join-Path $PWD 'scripts\validation\fixtures\hermes'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent hermes -InstallRoot $hermesFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent hermes -InstallRoot $hermesFixture
# CI / local harness (ephemeral work root; keeps versioned seed intact):
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1
```

Live home (`$HERMES_HOME/skills`, Windows example `%LOCALAPPDATA%\hermes\skills`):

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes `
  -InstallRoot "$env:LOCALAPPDATA\hermes" -AllowUserHome
# or, when HERMES_HOME is set (installer default on Windows Native):
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes `
  -InstallRoot $env:HERMES_HOME -AllowUserHome
```

Module notes: `adapters/hermes/README.md`.

## OpenHands (`openhands`) — project tree + optional user skills

| Item | Value |
|------|-------|
| Agent id | `openhands` |
| Module | `adapters/openhands/OpenHandsAdapter.ps1` |
| Project InstallRoot | Repository tree: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/`, `.plugin/` |
| Live user skills | `~/.agents/skills` via `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` (skills at `skills/` — not `~/.agents/.agents/skills`) |
| Official docs | [Skills overview](https://docs.openhands.dev/overview/skills), [Creating skills](https://docs.openhands.dev/overview/skills/creating), [Repository hooks](https://docs.openhands.dev/openhands/usage/customization/hooks), [Plugins](https://docs.openhands.dev/overview/plugins) |
| Fixture | `scripts/validation/fixtures/openhands` (project tree; USERPROFILE requires `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `plugin` / `agents` = true; `subagents` = `none` |
| Skill invoke | Agent Skills (product discovery; mention skill id) — **not** legacy microagents |
| Hooks | Shell, not `.ps1`: `.openhands/hooks.json` + `.openhands/hooks/*.sh` |

`AGENTS.md`, hooks, and plugin metadata are **project-scoped** (not the user-home tree). Skills still work **without** the plugin. Canvas Profile is **not** the `.agents/agents/` roster.

### Spawn honesty

Registry / `Get-Capabilities` is `none`. OpenHands loop runs until `FinishAction` on the **main** agent. Canvas / ACP is not parent→child spawn (not Cursor Task, not Hermes `delegate_task`). SDK `TaskToolSet` is not the Canvas product. SPAWN fallback **in-parent**. Never claim `native`.

### Publish layout (project InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `.agents/skills/<id>/SKILL.md` | `Publish-Skills` from `core/skills/` (+ `_shared/`; placeholders resolved) |
| `AGENTS.md` | Router from `core/router` plus folded `core/policy` (no `rules/` tree) |
| `.agents/agents/*.md` | `Publish-Agents` from `core/agents/` (SDK/plugin roster — not native spawn) |
| `.openhands/hooks.json` + `.openhands/hooks/*.sh` | `Publish-Hooks` from adapter assets (`session_start.sh` + `guard_pre_tool.sh` for `pre_tool_use`) |
| `.plugin/plugin.json` | Plugin metadata (points at `./.agents/skills/` and `./.openhands/hooks.json`) |

Placeholders resolve with **`TOOLKIT_ROOT` = InstallRoot/.agents`** (parent of `skills/_shared`). `GUARDRAILS_PATH` is `InstallRoot/AGENTS.md`. When InstallRoot is live user home `~/.agents`, `TOOLKIT_ROOT` is that directory and skills publish at `skills/` (no nested `.agents`).

### Publish + smoke (filesystem only)

| Command | Behavior |
|---------|----------|
| `Publish-Skills` | Agent Skills under `.agents/skills/` (or `skills/` on live `~/.agents`); `_shared/` copied |
| `Publish-Policy` | Folds `core/policy` into `AGENTS.md` (no Cursor `.mdc` `rules/` tree) |
| `Publish-Router` | Writes `AGENTS.md` (combined with folded policy); rewrites `.mdc` → `.md` |
| `Publish-Agents` | Copies `core/agents/` → `.agents/agents/` (roster; not Canvas Profile) |
| `Publish-Hooks` | Shell hooks under `.openhands/` (never `.ps1`) |
| `Invoke-SmokeValidate` | Native-layout filesystem assert on the project fixture |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts only (core skill ids, toolkit hook JSON/script, `.plugin/plugin.json`, roster agent markdown, owned `AGENTS.md`). Preserves alien skills/hooks/plugin/agents files and `sdd/sessions` / `sdd/manifest.json` |
| `validate-agent -Agent openhands` | Core validate + adapter smoke against fixture InstallRoot |

### Out of scope (do not emit)

Automation Server config, cron, GitHub webhooks, sandbox YAML, LLM model config, or secrets. Do **not** publish legacy `.openhands/microagents/`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
# scripting:
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands
$openhandsFixture = Join-Path $PWD 'scripts\validation\fixtures\openhands'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent openhands -InstallRoot $openhandsFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent openhands -InstallRoot $openhandsFixture
# CI / local harness (ephemeral work root; keeps versioned seed intact):
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1
```

Live user skills home:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands `
  -InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome
```

Module notes: `adapters/openhands/README.md`.

## Public commands (contract)

Module: `adapters/_contract/AdapterContract.ps1` (shared stub). Concrete modules: `adapters/cursor/CursorAdapter.ps1`, `adapters/antigravity/AntigravityAdapter.ps1`, `adapters/claude/ClaudeAdapter.ps1`, `adapters/codex/CodexAdapter.ps1`, `adapters/copilot/CopilotAdapter.ps1`, `adapters/opencode/OpenCodeAdapter.ps1`, `adapters/grok/GrokAdapter.ps1`, `adapters/zcode/ZCodeAdapter.ps1`, `adapters/hermes/HermesAdapter.ps1`, `adapters/openhands/OpenHandsAdapter.ps1`.

| Command | Intent | Contract stub (unused modules) |
|---------|--------|--------------------|
| `Get-Capabilities` | Report capability flags | Returns all flags `false`, `Implemented = false` |
| `Get-InstallRoots` | Resolve official install roots | Not-implemented result object; **no** path writes |
| `Publish-Skills` | Publish skills into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Publish-Policy` | Publish policy into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Publish-Router` | Publish router into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Publish-Agents` | Publish roster custom subagent markdown from `core/agents/` | Not-implemented result; **no** filesystem writes |
| `Publish-Hooks` | Publish hooks into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Get-SddRoot` | Resolve / prepare `<InstallRoot>/sdd` runtime root | Contract stub returns not-implemented; concrete adapters implement; source of truth for contracts remains `core/sdd/` |
| `Invoke-SmokeValidate` | Smoke against fixture `InstallRoot` | Not-implemented result; must not require live user-profile sync |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts | Contract stub returns not-implemented; all adapters implement keyed uninstall (preserves `sdd/sessions` + `sdd/manifest.json`; **no** InstallRoot wipe) |

Helpers (not part of the publish surface, used by tests/docs):

- `Get-AdapterContractCommandNames`
- `Get-AdapterCapabilityNames`

### Module READMEs

- [adapters/cursor/README.md](../adapters/cursor/README.md)
- [adapters/antigravity/README.md](../adapters/antigravity/README.md)
- [adapters/claude/README.md](../adapters/claude/README.md)
- [adapters/codex/README.md](../adapters/codex/README.md)
- [adapters/copilot/README.md](../adapters/copilot/README.md)
- [adapters/opencode/README.md](../adapters/opencode/README.md)
- [adapters/grok/README.md](../adapters/grok/README.md)
- [adapters/zcode/README.md](../adapters/zcode/README.md)
- [adapters/hermes/README.md](../adapters/hermes/README.md)
- [adapters/openhands/README.md](../adapters/openhands/README.md)

Spawn / subagents honesty: [SPAWN.md](SPAWN.md) + each README **Spawn / subagents** section.

### Publish knobs honesty (depth / threads / inherit)

Source: [`adapters/_shared/spawn-publish-honesty.md`](../adapters/_shared/spawn-publish-honesty.md) + `SpawnPublishKnobs.ps1`. RAG summary: [domains/adapters.md](domains/adapters.md#publish-knobs-honesty-depth--threads--inherit).

Publish may emit **only** SPAWN-aligned depth/threads honesty and model **inherit** (or omit model). Caps: developer **≤2**, orchestrate **≤4**. Never pin child≠parent model slug at publish time. Hermes / OpenCode / Antigravity (`agents=false` or no-op): do **not** emit host `delegation.max_spawn_depth` / config.toml knobs.

### TRACE emitter honesty

Source: [`adapters/_shared/trace-emitter-honesty.md`](../adapters/_shared/trace-emitter-honesty.md). RAG summary: [domains/adapters.md](domains/adapters.md#trace-emitter-honesty).

| Claim | Hosts |
|-------|--------|
| **Wired** fail-open `emit-trace.ps1` | Cursor (`hooks.json` postToolUse / subagentStop); Claude (PostToolUse / SubagentStop) |
| **Asset only** — not live PostToolUse wire | Codex (`Publish-Hooks` still PreToolUse guard) |
| **Not claimed** | OpenHands, OpenCode, Hermes, Grok, Copilot, Antigravity, ZCode |

Assert: `Assert-TraceEmitterFailOpen.ps1`. Core trail schema: `TRACE-ARCHIVE-CONTRACT.md` → `features/NNN-slug/TRACE.jsonl` only.

### Not-implemented result shape

```text
Success     = false
Implemented = false
CommandName = <name>
Message     = actionable "not implemented" text
ExitCode    = 1
```

Stubs **must not** write under `%USERPROFILE%` (or equivalent). Future smoke uses in-repo fixture `InstallRoot` via `Resolve-InstallRoot` (see `scripts/_lib/`).

## SDD contracts (`Get-SddRoot`)

- Canonical core path: `core/sdd/` (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`).
- Public state file name: `manifest.json` only (RN04 — do not brand the public file with a version suffix).
- Shared helper for the InstallRoot state layout: `scripts/_lib/Initialize-SddRootLayout.ps1` (`Invoke-ToolkitGetSddRoot`).

### All adapters — SDD root

| Item | Value |
|------|-------|
| `Get-SddRoot` | Returns `<InstallRoot>/sdd` (`SddRoot`, `SessionsPath`, `ManifestPath`) |
| `Get-SddRoot -Prepare` | Creates `sdd/sessions/` if missing; seeds minimal `manifest.json` (`schema_version: 2`, empty `repositories`) only when the file is absent — **never overwrites** an existing manifest |
| Sync | `scripts/sync-agent.ps1` **always** calls `Get-SddRoot -Prepare` after `Publish-*` (every registered agent) |
| Uninstall | Keyed uninstall **must not** remove `sdd/sessions/` or `sdd/manifest.json` |
| Guard | Prepare writes respect `Resolve-InstallRoot` (`-AllowUserHome` required under USERPROFILE) |

Core contracts under `core/sdd/` remain the source of truth for contract text. `Get-SddRoot -Prepare` creates the **runtime state root** (sessions + manifest), not a full copy of contract markdown. Placeholders `{{TOOLKIT_ROOT}}` / `{{SDD_ROOT}}` / `{{GUARDRAILS_PATH}}` resolve in published skills, rules, and router files at the destination only (`core/` on disk keeps placeholders).

## Placeholders (publish-time)

Core content uses `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, and `{{GUARDRAILS_PATH}}` instead of IDE home hardcodes. Each adapter substitutes these when publishing into its `InstallRoot`. See `docs/ARCHITECTURE.md` and `scripts/validation/contracts/must-not-contain-ide.json`.

## Constraints

- Smoke must use in-repo fixture `InstallRoot` — never require a live user-profile sync for CI green.
- Do not reintroduce user-profile IDE literals into core product text.
- Content published to agents always comes from `core/` (skills, policy, router, sdd contracts).