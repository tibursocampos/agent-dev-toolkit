# Architecture

Architecture for **agent-dev-toolkit**: shared **core**, concrete **adapters**, CLI orchestrators, and in-repo validation / CI.

## Layout

```text
core/          # skills (kebab), policy, router, sdd contracts
adapters/      # per-agent modules + registry.json + _contract
scripts/       # toolkit.ps1, sync-agent, validate-agent, _lib, validation
docs/          # public documentation
.github/workflows/validate-toolkit.yml
```

## Layers

| Layer | Role |
|-------|------|
| Core | Agent Skills (`SKILL.md`), `_shared`, policy markdown, neutral router, SDD contracts |
| Adapters | Publish skills/policy/router/hooks into agent-specific layout; smoke via fixture `InstallRoot` |
| CLI | `scripts/toolkit.ps1` chooses agent for sync / validate / uninstall |
| CI | `validate-core` + keyed uninstall asserts + `Assert-SyncAllowUserHomeForward` + 8 agent smokes on push/PR — no live-home sync for green |

## Application architecture selection

How consumer apps pick a style (separate from the toolkit’s own core/adapters layout above). Guidelines pack: [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

| Mode | Flow |
|------|------|
| **Greenfield** | Roster specialist **architect** (`core/skills/_shared/agents/`) proposes via Layer A (`architecture-selection.md`) → ARCH **draft** → operator **sim** → ARCH approved. No silent default style. |
| **Brownfield** | **Discover-first:** mirror in-repo / approved ARCH style; skip re-selection unless the operator asks to change it. |

After confirm (or brownfield mirror): load **one** Layer B file under `principles/architecture/`, then the matching Layer C stack overlay. Never glob `architecture/**`. Forma C wires the confirm gate in `orchestrate-analyze` when nature is greenfield or `needs_domain` without an established style.

## Source policy

- Product content for agents lives under **`core/`** (file tree in this repo).
- Public SDD state file name: `manifest.json` (no version branding in the filename).
- `core/skills/` — 36 skills + `_shared`.
- `core/policy/` — rule bodies (`.md`; adapters may normalize to `.mdc` or instructions).
- `core/router/` — neutral router material (`AGENTS.md`).
- `core/sdd/` — portable contracts (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`) for adapters via `Get-SddRoot`.

## Core path placeholders

Product content under `core/` must not hardcode a single IDE user-profile install root. Adapters resolve placeholders at publish:

| Placeholder | Meaning |
|-------------|---------|
| `{{TOOLKIT_ROOT}}` | Agent toolkit install root (skills, rules/policy, router) |
| `{{SDD_ROOT}}` | SDD state root (`preferences.json`, `sessions/`, global features) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy file path for the target agent |

Prepared `mustNotContain` needles: `scripts/validation/contracts/must-not-contain-ide.json` (merged in skill contracts). Core suite entry: `scripts/validation/validate-core.ps1` (alias `validate-all.ps1`; no home deploy).

### Conscious exceptions

- Brand names (Cursor, Antigravity, …) in AI co-author / stealth rules (not filesystem home paths).
- Project-relative paths documenting third-party CLI output — not user-profile install roots.

## Entry points

- `scripts/toolkit.ps1`
- `scripts/sync-agent.ps1`
- `scripts/validate-agent.ps1`
- `scripts/validation/validate-core.ps1`
- `scripts/validation/Assert-SyncAllowUserHomeForward.ps1`
- `scripts/validation/Invoke-CursorCiSmoke.ps1`
- `scripts/validation/Invoke-AntigravityCiSmoke.ps1`
- `scripts/validation/Invoke-ClaudeCiSmoke.ps1`
- `scripts/validation/Invoke-CodexCiSmoke.ps1`
- `scripts/validation/Invoke-CopilotCiSmokeSuite.ps1`
- `scripts/validation/Invoke-OpenCodeCiSmoke.ps1`
- `scripts/validation/Invoke-GrokCiSmoke.ps1`
- `scripts/validation/Invoke-ZCodeCiSmoke.ps1`
- `.github/workflows/validate-toolkit.yml`

## Cursor install layout

InstallRoot models `~/.cursor`. Default publish/smoke targets:

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills from `core/skills/` (placeholders resolved) |
| `rules/*.mdc` | Policy from `core/policy/` (`.md` → `.mdc`) |
| `AGENTS.md` | Router from `core/router/AGENTS.md` |
| `hooks/*.ps1` | Hook scripts from `adapters/cursor/assets/hooks/` |
| `hooks.json` | Merge at InstallRoot root (user entries preserved by `command`) |
| `sdd/sessions/` | SDD sessions directory (`Get-SddRoot -Prepare`) |
| `sdd/manifest.json` | Minimal seed when absent; never overwrite existing |

Smoke/CI: fixture `scripts/validation/fixtures/cursor-install-root`; `Invoke-CursorCiSmoke.ps1` uses an ephemeral work copy. No Cursor hooks trust UI; no live `~/.cursor` in CI. See [ADAPTERS.md](ADAPTERS.md).

## Antigravity install layout

InstallRoot models `~/.gemini`. Official tree:

| Relative path | Role |
|---------------|------|
| `config/skills` | Kebab Agent Skills + `dev_persona` |
| `config/plugins` | Plugin surface (e.g. GUARDRAILS under managed plugin id) |
| `config/hooks` | Official hooks directory (`hooks=false` → Publish-Hooks no-op) |
| `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` | Discovery / managed markdown |

**Legacy bridge** `antigravity-ide/plugins` is documentation / opt-in only — **not** a CI or default-smoke gate.

**Out of scope:** live Knowledge Items (KI); IDE trust UI. CI covers Antigravity via `Invoke-AntigravityCiSmoke.ps1` (filesystem sync+validate on an ephemeral fixture copy — no live `~/.gemini`). Skills stay **kebab-case** under `config/skills`.

## Codex install layout

InstallRoot models Codex plugin + `.agents` surfaces ([plugins](https://developers.openai.com/codex/plugins), [skills](https://developers.openai.com/codex/skills), [hooks](https://developers.openai.com/codex/hooks)). Live product home is `~/.codex` (config/AGENTS); USER skills discovery is `~/.agents/skills` (dual-root).

| Relative path | Role |
|---------------|------|
| `plugin/.codex-plugin/plugin.json` | Plugin manifest (`skills: ./skills/`) |
| `plugin/skills/<kebab-id>/SKILL.md` | Plugin-bundled skills (default) |
| `.agents/plugins/marketplace.json` | Local marketplace entry |
| `AGENTS.md` | Router from `core/router/` |
| `plugin/hooks/hooks.json` | Plugin hooks files; `/hooks` trust is **manual** |
| `.agents/skills/` | Optional `-UserScope` stand-in for `~/.agents/skills` |

Fixture: `scripts/validation/fixtures/codex`. See [ADAPTERS.md](ADAPTERS.md).

## Claude Code install layout

InstallRoot models `~/.claude` / project `.claude`:

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills from `core/skills/` |
| `rules/*.md` | Policy from `core/policy/` (`.md`, not `.mdc`) |
| `CLAUDE.md` | Router from `core/router/AGENTS.md` |
| `hooks/*.ps1` | From `adapters/claude/assets/hooks/` |
| `settings.json` | Safe merge: hooks keyed upsert + additive `permissions.allow`; UTF-8 without BOM; backup `.bak` |

Smoke/CI: `scripts/validation/fixtures/claude`; `Invoke-ClaudeCiSmoke.ps1` ephemeral copy. No Claude trust UI; no live `~/.claude` in CI.

## OpenCode install layout

InstallRoot models `~/.config/opencode` ([docs](https://opencode.ai/docs/config/)):

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills |
| `AGENTS.md` | Router |
| `plugins/*.js` | OpenCode JS plugins (MVP marker plugin) |

Hooks are **plugin-only** (no shell/PS1 parity). CI smoke (`Invoke-OpenCodeCiSmoke.ps1`) is **filesystem-only** sync+validate against an ephemeral fixture — **not** an OpenCode product runtime.

## ZCode ADE install layout

InstallRoot models `~/.zcode` (ADE filesystem — **not** GLM Coding Plan):

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Kebab Agent Skills |
| `AGENTS.md` | Router surface |
| `cli/config.json` | Hooks config |
| `hooks/hooks.json` | User-level hooks merge |

Fixture: `scripts/validation/fixtures/zcode-install-root/`. CI: `Invoke-ZCodeCiSmoke.ps1`.

## GitHub Copilot install layout

`-Mode user|repo` is required. Relative tree is identical under either InstallRoot:

| Mode | InstallRoot models | Fixture |
|------|--------------------|---------|
| `user` | `~/.copilot` | `scripts/validation/fixtures/copilot/user` |
| `repo` | `.github` | `scripts/validation/fixtures/copilot/repo` |

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills |
| `instructions/*.instructions.md` | Policy |
| `copilot-instructions.md` | Always-on instructions from router source |
| `hooks/*` | Adapter hooks when `hooks=true` |

**Out of scope:** JetBrains and Eclipse Copilot IDE layouts. CI: `Invoke-CopilotCiSmokeSuite.ps1`.

## Grok Build install layout

InstallRoot models `~/.grok` / project `.grok` — **native** tree:

| Relative path | Role |
|---------------|------|
| `.grok/skills` | Kebab Agent Skills |
| `.grok/rules` | Policy markdown |
| `.grok/hooks` | Native hooks; `/hooks-trust` is **manual** |
| `AGENTS.md` | Router |

Claude/Cursor paths may be read by the product as compat; MVP **publish** targets `.grok`. Fixture: `scripts/validation/fixtures/grok`.

## CI

Workflow `.github/workflows/validate-toolkit.yml` on `windows-latest` (no USERPROFILE deploy for green):

1. `validate-core.ps1 -Quiet`
2. Keyed uninstall asserts (Claude, Copilot, Codex, OpenCode, Antigravity, Grok, Cursor, ZCode) — separate step; not inside validate-core
3. `Assert-SyncAllowUserHomeForward.ps1` (disposable USERPROFILE probe)
4. Eight agent CI smokes: Cursor, Antigravity, Claude, Codex, Copilot suite, OpenCode, Grok, ZCode

OpenCode and peer smokes assert published files on fixtures only — they do **not** launch product runtimes. Details: [VALIDATION.md](VALIDATION.md), [domains/validation-ci.md](domains/validation-ci.md).

See also [ADAPTERS.md](ADAPTERS.md), [overview.md](overview.md), and [domains/core.md](domains/core.md) § Code guidelines and architecture selection.
