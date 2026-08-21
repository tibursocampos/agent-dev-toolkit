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
| CI | `validate-core` + keyed uninstall asserts + `Assert-SyncAllowUserHomeForward` + 10 agent smokes on push/PR (Copilot is a suite) — no live-home sync for green |

## Application architecture selection

How consumer apps pick a style (separate from the toolkit’s own core/adapters layout above). Guidelines pack: [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

| Mode | Flow |
|------|------|
| **Greenfield** | Roster specialist **architect** (`core/skills/_shared/agents/`) proposes via Layer A (`architecture-selection.md`) → ARCH **draft** → operator **sim** → ARCH approved. No silent default style. |
| **Brownfield** | **Discover-first:** mirror in-repo / approved ARCH style; skip re-selection unless the operator asks to change it. |

After confirm (or brownfield mirror): load **one** Layer B file under `principles/architecture/`, then the matching Layer C stack overlay. Never glob `architecture/**`. Orchestrated Delivery *(formerly Forma C)* wires the confirm gate in `orchestrate-analyze` when nature is greenfield or `needs_domain` without an established style.

## Source policy

- Product content for agents lives under **`core/`** (file tree in this repo).
- Public SDD state file name: `manifest.json` (no version branding in the filename).
- `core/skills/` — 38 skills + `_shared` (agent SoT: `help-skills` → `skills-catalog/CATALOG.md` + `OPERATOR.md`).
- `core/policy/` — rule bodies (`.md`; adapters may normalize to `.mdc` or instructions).
- `core/router/` — neutral router material (`AGENTS.md`).
- `core/sdd/` — portable contracts (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`) for adapters via `Get-SddRoot`.

## Core path placeholders

Product content under `core/` must not hardcode a single IDE user-profile install root. Adapters resolve placeholders at publish:

| Placeholder | Meaning |
|-------------|---------|
| `{{TOOLKIT_ROOT}}` | Agent toolkit install root (skills / policy / router — **destination-aware**; Codex splits plugin skills vs InstallRoot rules) |
| `{{SDD_ROOT}}` | SDD state root (`preferences.json`, `sessions/`, `manifest.json`, optional global Classic tree) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy file path for the target agent |

Adapters may bake absolute paths at publish; at **runtime** skills resolve SDD state via host-aware `effective_SDD_ROOT` ([STORAGE.md](../core/sdd/STORAGE.md)) so a foreign agent's baked `{{SDD_ROOT}}` never wins over the current host.

**SDD_ROOT vs cwd artifacts:** `effective_SDD_ROOT` (`{{SDD_ROOT}}` in docs) holds global sessions, preferences, and `manifest.json` (schema v2), plus optional **global** Classic `features/` + `memory-bank/` when `classic.storage_mode` is `global`. **Repository** mode keeps those trees under the consumer `$Cwd` instead. Deep dive: [domains/core.md](domains/core.md) § SDD — do not paste the full STORAGE contract here.

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
- `scripts/validation/Invoke-HermesCiSmoke.ps1`
- `scripts/validation/Invoke-OpenHandsCiSmoke.ps1`
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

InstallRoot models Codex plugin + `.agents` surfaces ([plugins](https://developers.openai.com/codex/plugins), [skills](https://developers.openai.com/codex/skills), [hooks](https://developers.openai.com/codex/hooks)). Live product home is `~/.codex` (config/AGENTS/rules); USER skills discovery is `~/.agents/skills` (dual-root). **Do not** treat plugin skills and InstallRoot rules as one shared `TOOLKIT_ROOT`.

| Relative path | Role |
|---------------|------|
| `plugin/.codex-plugin/plugin.json` | Plugin manifest (`skills: ./skills/`) |
| `plugin/skills/<kebab-id>/SKILL.md` | Plugin-bundled skills (default); `TOOLKIT_ROOT` for skills paths |
| `plugin/skills/_shared/skills-catalog/CATALOG.md` (+ `OPERATOR.md`) | Agent skill map + operator notes via `help-skills` |
| `rules/*.md` | Publish-Policy from `core/policy/` (`rules=true`) |
| `.agents/plugins/marketplace.json` | Local marketplace entry |
| `AGENTS.md` | Publish-Router: materialized dual-root **absolute** paths (no `{{…}}`; no live `docs/` links) |
| `plugin/hooks/hooks.json` | Plugin hooks files; `/hooks` trust is **manual** |
| `.agents/skills/` | Optional `-UserScope` stand-in for `~/.agents/skills` (live: `$HOME/.agents/skills` + `-AllowUserHome`) |

Default sync is **plugin-only**. Fixture: `scripts/validation/fixtures/codex`. See [ADAPTERS.md](ADAPTERS.md).

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

InstallRoot **is** `~/.grok` (or project `.grok` passed as InstallRoot) — **native** tree (Claude-style; not nested `.grok/.grok`):

| Relative path | Role |
|---------------|------|
| `skills` | Kebab Agent Skills → live `~/.grok/skills` |
| `rules` | Policy markdown → live `~/.grok/rules` |
| `hooks` | Native hooks; `/hooks-trust` is **manual** |
| `AGENTS.md` | Router |

Claude/Cursor paths may be read by the product as compat; MVP **publish** targets InstallRoot directly. Fixture: `scripts/validation/fixtures/grok` (models `~/.grok`).

## Hermes install layout

InstallRoot **is** `~/.hermes` (CI fixture models that home) — skills and `AGENTS.md` sit **directly under** that root (never `~/.hermes/.hermes/skills`):

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Agent Skills from `core/skills/` (live `~/.hermes/skills`) |
| `AGENTS.md` | Router from `core/router` plus folded `core/policy` (no `rules/` tree) |
| `MEMORY.md` | Seeded once if missing; never overwritten |
| `SOUL.md` | **Never** created or overwritten |

`Publish-Hooks` / `Publish-Agents` are documented no-ops (`hooks=false`, `agents=false`). Subagents: host **`delegate_task`**. Do not emit gateway tokens, `config.yaml` secrets, cron, or `delegation.*` YAML. Fixture: `scripts/validation/fixtures/hermes`. CI: `Invoke-HermesCiSmoke.ps1`.

## OpenHands install layout

**Project** InstallRoot (CI / typical sync) models a repository tree — not a nested user-home `.agents/.agents`:

| Relative path | Role |
|---------------|------|
| `.agents/skills/<id>/SKILL.md` | Agent Skills from `core/skills/` (**not** legacy microagents) |
| `.agents/agents/*.md` | Roster from `core/agents/` (SDK/plugin; not Canvas Profile; not native spawn) |
| `AGENTS.md` | Router + folded policy (no `rules/` tree) |
| `.openhands/hooks.json` + `.openhands/hooks/*.sh` | Shell hooks (never `.ps1`) |
| `.plugin/plugin.json` | Plugin metadata (skills still work without the plugin) |

**Live user skills:** `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` publishes `skills/` directly under that home. `AGENTS.md`, hooks, and plugin metadata stay project-scoped. Capability `subagents=none` — SPAWN fallback in-parent. Do not emit Automation Server, cron, GitHub webhooks, sandbox YAML, or LLM secrets. Fixture: `scripts/validation/fixtures/openhands`. CI: `Invoke-OpenHandsCiSmoke.ps1`.

## CI

Workflow `.github/workflows/validate-toolkit.yml` on `windows-latest` (no USERPROFILE deploy for green):

1. `validate-core.ps1 -Quiet`
2. Keyed uninstall asserts (Claude, Copilot, Codex, OpenCode, Antigravity, Grok, Cursor, ZCode, Hermes, OpenHands) — separate step; not inside validate-core
3. `Assert-SyncAllowUserHomeForward.ps1` (disposable USERPROFILE probe)
4. Ten agent CI smokes (Copilot is a suite): Cursor, Antigravity, Claude, Codex, Copilot suite, OpenCode, Grok, ZCode, Hermes, OpenHands

OpenCode and peer smokes assert published files on fixtures only — they do **not** launch product runtimes. Details: [VALIDATION.md](VALIDATION.md), [domains/validation-ci.md](domains/validation-ci.md).

See also [ADAPTERS.md](ADAPTERS.md), [overview.md](overview.md), and [domains/core.md](domains/core.md) § Code guidelines and architecture selection.
