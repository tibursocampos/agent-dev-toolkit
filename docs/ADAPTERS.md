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
| `tier` | `1` for MVP agents |
| `module` | Path relative to `adapters/` (dot-source target) |
| `capabilities` | Capability map: boolean publish flags + string `subagents` enum (`native` \| `none`) |
| `publishSurface` | Optional whole-file router targets the adapter may publish (`wholeFileRouter`: relative paths under InstallRoot). Antigravity uses managed markdown blocks (`[]`); Copilot folds router into `copilot-instructions.md` via `Publish-Policy` (`[]`). Sync records sha256 in InstallRoot `.toolkit-managed-publish.json`; uninstall removes whole-file routers only when inventory hash matches. |

### Tier 1 agents

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

All Tier 1 agents have concrete modules with publish + in-repo smoke. See the per-agent sections below.

## Official install roots (contract)

Live Sync wizard **[1]** resolves `Get-InstallRoots` → `OfficialUserRootPath` (Enter = live home). CI and non-interactive defaults still use in-repo fixtures unless `-AllowUserHome` is set.

| Agent | Live InstallRoot | Skills / rules / hooks (summary) | Notes |
|-------|------------------|----------------------------------|-------|
| `cursor` | `~/.cursor` | `skills/`, `rules/*.mdc`, `hooks.json`, `AGENTS.md` | Also reads `~/.agents/skills` / project `.cursor/` |
| `antigravity` | `~/.gemini` | ADT publishes `config/skills`, `config/skills.json`, `config/AGENTS.md`, `config/plugins/…/GUARDRAILS.md` | Twin IDE steering often points skills/GUARDRAILS under `antigravity-ide/plugins/<id>/` via `skills.json` — see adapter README. AppData `agy\bin` = binary only |
| `claude` | `~/.claude` | `skills/`, `rules/`, `CLAUDE.md`, hooks in `settings.json` | Project scope also uses repo `.claude/` |
| `codex` | `~/.codex` | Dual: config/AGENTS/hooks/agents under `~/.codex`; USER skills discovery `~/.agents/skills`; default sync = **plugin** under InstallRoot | `-UserScope` mirrors skills under InstallRoot `.agents/skills` |
| `copilot` | `~/.copilot` or `.github` | `-Mode user\|repo`; `skills/`, `instructions/`, `copilot-instructions.md`, `hooks/` | Same relative tree both modes |
| `opencode` | `~/.config/opencode` | `skills/`, `AGENTS.md`, hooks = JS `plugins/` | Not `~/.opencode` |
| `grok` | `~/.grok` | Native `.grok/skills\|rules\|hooks`; `AGENTS.md` | Also reads Claude/Cursor layouts; adapter writes native |
| `zcode` | `~/.zcode` | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` | ADE filesystem — not GLM Coding Plan |

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
| `subagents` | String enum `native` \| `none` — host Task/equivalent for SPAWN (`core/skills/_shared/agents/SPAWN.md`). **Not** boolean. Stub/`Get-Capabilities` defaults must never mint `native`. Per-adapter evidence and host spawn mechanism: each `adapters/<id>/README.md` (**Spawn / subagents**). Tier-1 matrix: [SPAWN.md](SPAWN.md). |

Honesty matrix (Tier 1 **registry** publish surfaces — do not claim unsupported ones):

| Agent | skills | rules | hooks | router | plugin | Notes |
|-------|--------|-------|-------|--------|--------|-------|
| `cursor` | true | true | true | true | false | — |
| `antigravity` | true | true | false | true | true | No native shell-hook parity; `Publish-Hooks` no-op |
| `claude` | true | true | true | true | false | Hooks smoke = files only; trust UI out of scope |
| `codex` | true | false | true | true | true | `Publish-Policy` no-op; `/hooks` trust manual |
| `copilot` | true | true | true | false | false | `Publish-Router` no-op; router folds into `copilot-instructions.md` |
| `opencode` | true | false | true | true | true | `HooksSemantics=plugin-only` (JS plugins, not PS1) |
| `grok` | true | true | true | true | false | Native `.grok`; hooks trust UI out of smoke/CI |
| `zcode` | true | false | true | true | false | `Publish-Policy` no-op |

All eight agents declare `subagents: native` (host product docs), including **Antigravity**. **Antigravity** *effective* capability is fail-closed via `Get-Capabilities` probe (`ADT_ANTIGRAVITY_SUBAGENTS` / `agy` / product version) — pré-2.0 or unverifiable → `none`. `validate-core` checks registry, each module’s `Get-Capabilities` (Antigravity with CI override), orchestrate SPAWN/fallback text, and Antigravity probe cases. CI adapter smokes stay filesystem sync/validate — no duplicate spawn matrix there.
## Cursor (`cursor`) — publish + smoke

| Item | Value |
|------|-------|
| Agent id | `cursor` |
| Module | `adapters/cursor/CursorAdapter.ps1` |
| Official user root | `~/.cursor` (relative `.cursor` under USERPROFILE) |
| Official docs | [Rules + AGENTS.md](https://cursor.com/docs/rules), [Skills](https://cursor.com/docs/context/skills), [Hooks](https://cursor.com/docs/hooks), [Subagents](https://cursor.com/docs/context/subagents), [Agent best practices](https://cursor.com/blog/agent-best-practices) |
| Fixture | `scripts/validation/fixtures/cursor-install-root` (InstallRoot models the Cursor root; seed may include custom `hooks.json`) |
| Fixture override | `-InstallRoot <path>` (CI default: in-repo fixture; USERPROFILE paths require `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` = true; `plugin` = false |
| Key artifacts | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/*.ps1`, `hooks.json`, `sdd/sessions`, `sdd/manifest.json` |
| Content source | `core/` only |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent cursor` — **no** Cursor trust UI, **no** live `~/.cursor` writes in CI |

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved) |
| `rules/*.mdc` | `Publish-Policy` from `core/policy/` (`.md` → `.mdc`; no orphan `.md` rules) |
| `AGENTS.md` | `Publish-Router` from `core/router/AGENTS.md` |
| `hooks/*.ps1` | `Publish-Hooks` from `adapters/cursor/assets/hooks/` |
| `hooks.json` | Merge at InstallRoot root (user entries preserved by `command`; invalid JSON fail-closed) |
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
| Capabilities | `skills` / `rules` / `router` / `plugin` = true; `hooks` = false (no native shell-hook parity) |
| Key artifacts | kebab skills + `skills.json`, GUARDRAILS / `dev_persona` from core, managed `AGENTS.md` / `GEMINI.md` |
| `Publish-Hooks` | **No-op** while `hooks=false`: Success/Implemented, zero writes under `config/hooks` or `antigravity-ide/plugins`. Default smoke **ignores** hooks requirement and does **not** gate on the legacy bridge (opt-in / docs only). |
| `Invoke-SmokeValidate` | Filesystem-only under InstallRoot (kebab skills, `skills.json`, GUARDRAILS, `dev_persona`, managed AGENTS/GEMINI). Hooks/legacy bridge not gated. |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts only (core skill folders, `dev_persona`, managed plugin dir, managed `skills.json` entry, managed markdown blocks). Preserves alien skills / hooks / legacy bridge. Preserves `sdd/sessions` + `sdd/manifest.json`. |

Default smoke/CI targets the **official** `config/*` layout under InstallRoot (kebab skills only — no underscore rename). The path `antigravity-ide/plugins` remains a **legacy bridge** only — documentation / opt-in / **read-only** (not a CI or default-smoke gate).

**Out of scope:** live Knowledge Items (KI) injection; IDE trust UI / interactive prompts. CI covers Antigravity via `Invoke-AntigravityCiSmoke.ps1` (ephemeral fixture filesystem sync+validate — no live `~/.gemini`).

`Publish-Skills` / `Publish-Policy` / `Publish-Router` / `Publish-Hooks` (no-op) / `Invoke-SmokeValidate` / `Uninstall-Toolkit` are implemented. Operator E2E:

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
| Capabilities | `skills` / `rules` / `hooks` = true; `router` / `plugin` = false |
| Key artifacts (relative under InstallRoot) | `skills/<kebab-id>/SKILL.md`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/*` |
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
| `hooks/*` | `Publish-Hooks` from `adapters/copilot/assets/hooks/` when `hooks=true` |

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
| Capabilities | `skills` / `rules` / `hooks` / `router` = true; `plugin` = false |
| Key artifacts | `skills/`, `rules/*.md`, `hooks/*.ps1`, `CLAUDE.md`, merged `settings.json` |
| Content source | `core/` only (packaging layout may follow Claude / ai-prompts docs as **reference** — never copy Athena content) |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent claude` — **no** Claude trust UI, **no** live `~/.claude` writes in CI |

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved) |
| `rules/*.md` | `Publish-Policy` from `core/policy/` (keep `.md`; not Cursor `.mdc`) |
| `CLAUDE.md` | `Publish-Router` from `core/router/AGENTS.md` (`.mdc` refs rewritten to `.md`) |
| `hooks/*.ps1` | `Publish-Hooks` from `adapters/claude/assets/hooks/` |
| `settings.json` | Merge after hooks publish (see below) |

### settings.json merge (RN03–RN05 / RN08)

| Rule | Behavior |
|------|----------|
| Backup | Write `settings.json.bak` before overwrite |
| Hooks | Keyed upsert for managed events (`UserPromptSubmit`, `PreCompact`, `PostToolUse`); alien events preserved |
| `permissions.allow` | Additive **narrow** toolkit entries — one `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` per managed hook; no duplicates on re-sync; user allows preserved. Re-sync **strips** legacy broad `Bash(pwsh *)` / `Bash(powershell *)` unless `-AllowBroadShellPermissions` |
| Other keys | Preserved as-is (no wholesale replace) |
| Encoding | UTF-8 **without BOM** |
| Invalid JSON | Abort; do not overwrite (TE01) |
| Backup failure | Abort; no write (TE02) |

Hook **trust UI** is out of smoke/CI scope — green means files + merge completeness only.

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
| Official marketplace | `.agents/plugins/marketplace.json` (fixture models local `source.path` `./plugin`) |
| Official docs | [Codex](https://developers.openai.com/codex), [plugins](https://developers.openai.com/codex/plugins), [skills](https://developers.openai.com/codex/skills), [hooks](https://developers.openai.com/codex/hooks), [config basic](https://developers.openai.com/codex/config-basic), [AGENTS.md](https://developers.openai.com/codex/guides/agents-md/) |
| Fixture | `scripts/validation/fixtures/codex` (pass `-InstallRoot`; USERPROFILE requires `-AllowUserHome`) |
| Capabilities | `skills` / `hooks` / `router` / `plugin` = true; `rules` = false |
| Key artifacts | `plugin/.codex-plugin/plugin.json`, `plugin/skills/<id>/SKILL.md`, `.agents/plugins/marketplace.json`, `AGENTS.md`, `plugin/hooks/hooks.json` (+ `session_start.ps1`) |
| Hooks trust | Codex `/hooks` UI is **manual**; smoke/CI never invoke or require trust (RN03) |

### Plugin skills vs `~/.agents/skills`

| Scope | Path under InstallRoot | When written |
|-------|------------------------|--------------|
| Plugin-bundled (default) | `plugin/skills/<kebab-id>/SKILL.md` | Default `Publish-Skills` |
| USER mirror (opt-in) | `.agents/skills/<kebab-id>/SKILL.md` | `Publish-Skills -UserScope` only (fixture stand-in for `~/.agents/skills`) |

Default sync is **plugin-only**. Real `$HOME/.agents/skills` is never touched without `-AllowUserHome` and an InstallRoot under USERPROFILE.

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `plugin/.codex-plugin/plugin.json` | Plugin manifest (`skills: ./skills/`) |
| `plugin/skills/<kebab-id>/SKILL.md` | Bundled skills from `core/skills/` |
| `.agents/plugins/marketplace.json` | Local marketplace entry (`source.path` `./plugin`) |
| `AGENTS.md` | `Publish-Router` from `core/router/AGENTS.md` |
| `plugin/hooks/hooks.json` | `Publish-Hooks` (filesystem only; trust `/hooks` out of smoke) |
| `.agents/skills/` | Optional `-UserScope` mirror of `core/skills` |

`Publish-Policy` is a documented **no-op** (`rules=false`).

### Smoke / sync (filesystem only — no `/hooks` trust)

| Command | Behavior |
|---------|----------|
| `Publish-Skills` | Plugin manifest + skills + marketplace; optional `-UserScope` USER mirror |
| `Publish-Router` | Writes `AGENTS.md` |
| `Publish-Hooks` | Writes hooks **files** under `plugin/hooks/` |
| `Invoke-SmokeValidate` | Asserts plugin, marketplace, `AGENTS.md`, hooks files (TE01–TE04); `RequiresHooksTrust=false` |
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
| Capabilities | `skills` / `hooks` / `router` / `plugin` = true; `rules` = false |
| Hooks semantics | `HooksSemantics=plugin-only` — OpenCode uses **JavaScript plugins**, not shell/PS1 hooks (unlike Cursor/Claude). Smoke never requires `.ps1` hooks |
| MVP hooks (Decision A) | `Publish-Hooks` copies `plugins/agent-dev-toolkit-marker.js` from `adapters/opencode/assets/plugins/` |
| Key artifacts | `skills/<kebab-id>/SKILL.md`, `AGENTS.md`, `plugins/agent-dev-toolkit-marker.js` |
| `Publish-Policy` | Documented **no-op** (`rules=false`; no dedicated OpenCode policy surface) |
| Smoke | Filesystem-only via `Invoke-SmokeValidate` / `validate-agent -Agent opencode` / `Invoke-OpenCodeCiSmoke.ps1` — **no** OpenCode product runtime, **no** real `~/.config/opencode` writes in CI |
| Uninstall | Keyed removal of toolkit skills, `AGENTS.md`, and the marker plugin only (RN07 — no wholesale wipe). Preserves `sdd/sessions` + `sdd/manifest.json` |

### Publish layout (under InstallRoot)

| Relative path | Source / role |
|---------------|---------------|
| `skills/<kebab-id>/SKILL.md` | `Publish-Skills` from `core/skills/` (placeholders resolved; kebab ids preserved) |
| `AGENTS.md` | `Publish-Router` from `core/router/AGENTS.md` |
| `plugins/agent-dev-toolkit-marker.js` | `Publish-Hooks` Decision A marker (auto-loaded OpenCode plugin surface) |

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
| Capabilities | `skills` / `hooks` / `router` = true; `rules` / `plugin` = false |
| Key artifacts under InstallRoot | `skills/<id>/SKILL.md`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json`, `sdd/sessions/`, `sdd/manifest.json` |

### Install layout (relative to InstallRoot / `~/.zcode`)

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills from `core/skills/` |
| `AGENTS.md` | Router surface from `core/router/AGENTS.md` (no Cursor `rules/*.mdc` tree) |
| `cli/config.json` | Hooks config (`hooks.enabled: true` when applicable) |
| `hooks/hooks.json` | User-level hooks merge (non-destructive; preserves custom entries) |
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

**GLM Coding Plan** (Z.ai endpoint / Base URL / MCP only — skills stay on the host) is **not** this adapter and remains **Tier 3 / out of scope**. Do not use agent id `zcode` for endpoint-only GLM setup.

This module covers **ZCode (Z.ai ADE)** filesystem surfaces only: skills, `AGENTS.md`, and hooks/config under `.zcode`. Use the ZCode ADE adapter here, or the host agent’s own adapter, when you need skill/hooks publish — not GLM Coding Plan.

## Grok Build (`grok`) — native `.grok`

| Item | Value |
|------|-------|
| Agent id | `grok` |
| Module | `adapters/grok/GrokAdapter.ps1` |
| Official user root | `~/.grok` (relative `.grok` under USERPROFILE) |
| Official project scope | `.grok/` under the repository / InstallRoot |
| Fixture | `scripts/validation/fixtures/grok` (pass `-InstallRoot`; USERPROFILE requires `-AllowUserHome`) |
| Capabilities | `skills` / `rules` / `hooks` / `router` = true; `plugin` = false |
| Native layout | `.grok/skills/<id>/SKILL.md`, `.grok/rules/*.md`, `.grok/hooks/*.json` (+ `session_start.ps1`) |
| Router | `AGENTS.md` at InstallRoot (from `core/router`) |
| Hooks trust | `/hooks-trust` or `--trust` is **manual**; smoke/CI never write `trusted_folders.toml` |

### Native write vs Claude/Cursor compat (RN02)

Grok Build can also **read** Claude/Cursor artifacts (`CLAUDE.md`, `.claude/`, `.cursor/`). This adapter **must publish natively** under `.grok/*` — it is not enough to mirror only Claude/Cursor layouts and rely on compat. `Invoke-SmokeValidate` fails (TE04) when compat paths exist without the required native `.grok` artifacts.

### Publish + smoke (filesystem only)

| Command | Behavior |
|---------|----------|
| `Publish-Skills` | Copies `core/skills` → `.grok/skills` with placeholder resolve |
| `Publish-Policy` | Copies `core/policy` → `.grok/rules/*.md` |
| `Publish-Router` | Writes `AGENTS.md`; rewrites `.mdc` → `.md` refs |
| `Publish-Hooks` | Writes native SessionStart JSON + script under `.grok/hooks` |
| `Invoke-SmokeValidate` | Asserts `.grok` layout (TE01–TE05); **does not** invoke trust UI |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts only (no wipe of `.grok` / `config.toml`). Preserves `sdd/sessions` + `sdd/manifest.json` |
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

## Public commands (contract)

Module: `adapters/_contract/AdapterContract.ps1` (shared stub). Concrete modules: `adapters/cursor/CursorAdapter.ps1`, `adapters/antigravity/AntigravityAdapter.ps1`, `adapters/claude/ClaudeAdapter.ps1`, `adapters/codex/CodexAdapter.ps1`, `adapters/copilot/CopilotAdapter.ps1`, `adapters/opencode/OpenCodeAdapter.ps1`, `adapters/grok/GrokAdapter.ps1`, `adapters/zcode/ZCodeAdapter.ps1`.

| Command | Intent | Contract stub (unused modules) |
|---------|--------|--------------------|
| `Get-Capabilities` | Report capability flags | Returns all flags `false`, `Implemented = false` |
| `Get-InstallRoots` | Resolve official install roots | Not-implemented result object; **no** path writes |
| `Publish-Skills` | Publish skills into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Publish-Policy` | Publish policy into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Publish-Router` | Publish router into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Publish-Hooks` | Publish hooks into `InstallRoot` | Not-implemented result; **no** filesystem writes |
| `Get-SddRoot` | Resolve / prepare `<InstallRoot>/sdd` runtime root | Contract stub returns not-implemented; concrete adapters implement; source of truth for contracts remains `core/sdd/` |
| `Invoke-SmokeValidate` | Smoke against fixture `InstallRoot` | Not-implemented result; must not require live user-profile sync |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts | Contract stub returns not-implemented; all Tier-1 adapters implement keyed uninstall (preserves `sdd/sessions` + `sdd/manifest.json`; **no** InstallRoot wipe) |

Helpers (not part of the publish surface, used by tests/docs):

- `Get-AdapterContractCommandNames`
- `Get-AdapterCapabilityNames`

### Module READMEs (all eight)

- [adapters/cursor/README.md](../adapters/cursor/README.md)
- [adapters/antigravity/README.md](../adapters/antigravity/README.md)
- [adapters/claude/README.md](../adapters/claude/README.md)
- [adapters/codex/README.md](../adapters/codex/README.md)
- [adapters/copilot/README.md](../adapters/copilot/README.md)
- [adapters/opencode/README.md](../adapters/opencode/README.md)
- [adapters/grok/README.md](../adapters/grok/README.md)
- [adapters/zcode/README.md](../adapters/zcode/README.md)

Spawn / subagents honesty: [SPAWN.md](SPAWN.md) + each README **Spawn / subagents** section.

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

### All Tier-1 agents — SDD root

| Item | Value |
|------|-------|
| `Get-SddRoot` | Returns `<InstallRoot>/sdd` (`SddRoot`, `SessionsPath`, `ManifestPath`) |
| `Get-SddRoot -Prepare` | Creates `sdd/sessions/` if missing; seeds minimal `manifest.json` (`schema_version: 2`, empty `repositories`) only when the file is absent — **never overwrites** an existing manifest |
| Sync | `scripts/sync-agent.ps1` **always** calls `Get-SddRoot -Prepare` after `Publish-*` (every Tier-1 agent) |
| Uninstall | Keyed uninstall **must not** remove `sdd/sessions/` or `sdd/manifest.json` |
| Guard | Prepare writes respect `Resolve-InstallRoot` (`-AllowUserHome` required under USERPROFILE) |

Core contracts under `core/sdd/` remain the source of truth for contract text. `Get-SddRoot -Prepare` creates the **runtime state root** (sessions + manifest), not a full copy of contract markdown. Placeholders `{{TOOLKIT_ROOT}}` / `{{SDD_ROOT}}` / `{{GUARDRAILS_PATH}}` resolve in published skills, rules, and router files at the destination only (`core/` on disk keeps placeholders).

## Placeholders (publish-time)

Core content uses `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}`, and `{{GUARDRAILS_PATH}}` instead of IDE home hardcodes. Each adapter substitutes these when publishing into its `InstallRoot`. See `docs/ARCHITECTURE.md` and `scripts/validation/contracts/must-not-contain-ide.json`.

## Constraints

- Smoke must use in-repo fixture `InstallRoot` — never require a live user-profile sync for CI green.
- Do not reintroduce user-profile IDE literals into core product text.
- Content published to agents always comes from `core/` (skills, policy, router, sdd contracts).