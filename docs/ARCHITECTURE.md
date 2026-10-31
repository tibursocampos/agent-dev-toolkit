# Architecture

Architecture for **agent-dev-toolkit**: shared **core**, concrete **adapters**, CLI orchestrators, and in-repo validation / CI.

## Layout

```text
core/          # skills (kebab), policy, router, sdd contracts
adapters/      # per-agent modules + registry.json + _contract
scripts/       # toolkit.ps1, sync-agent, validate-agent, _lib, validation
docs/          # public documentation
memory-bank/   # durable workspace map (Orchestrated Delivery Step 0)
.github/workflows/validate-toolkit.yml
.github/workflows/master-release-ci.yml
.github/workflows/enforce-release-source.yml
.github/workflows/release.yml
.github/workflows/publish-release-bootstrap.yml
README.md  CONTRIBUTING.md  SECURITY.md   # root entry and policy
```

## Layers

| Layer | Role |
|-------|------|
| Core | Agent Skills (`SKILL.md`), `_shared`, policy markdown, neutral router, SDD contracts |
| Adapters | Publish skills/policy/router/hooks into agent-specific layout; smoke via fixture `InstallRoot` |
| CLI | `scripts/toolkit.ps1` chooses agent for sync / validate / uninstall |
| Validation | In-repo fixtures and CI smokes; a green run needs no live home write |
| CI and release | `validate-toolkit.yml` on `pull_request` to `develop` runs core validation, adapter smokes and strict MkDocs, then emits aggregate checks `validate` and `ci-ok`. Release PRs to `master` / `main` also emit `ci-ok` from `master-release-ci.yml` and `release-source` from `enforce-release-source.yml`; they do not rerun the full suite. |

## Application architecture selection

How consumer apps pick a style (separate from the toolkit’s own core/adapters layout above). Guidelines pack: [domains/core.md](domains/core.md) § Code guidelines and architecture selection.

| Mode | Flow |
|------|------|
| **Greenfield** | Roster specialist **architect** (`core/skills/_shared/agents/`) proposes via Layer A (`architecture-selection.md`) → ARCH **draft** → operator `confirm` answer → ARCH approved. No silent default style. |
| **Brownfield** | **Discover-first:** mirror in-repo / approved ARCH style; skip re-selection unless the operator asks to change it. |

After confirm (or brownfield mirror): load **one** Layer B file under `principles/architecture/`, then the matching Layer C stack overlay. Never glob `architecture/**`. Orchestrated Delivery wires the confirm gate in `orchestrate-analyze` when nature is greenfield or `needs_domain` without an established style.

## Source policy

- Product content for agents lives under **`core/`** (file tree in this repo).
- Public SDD state file name: `manifest.json` (no version branding in the filename).
- `core/skills/` — 46 skills + `_shared` (agent SoT: `help-skills` → `skills-catalog/CATALOG.md` + `OPERATOR.md`).
- `core/policy/` — rule bodies (`.md`; adapters may normalize to `.mdc` or instructions).
- `core/router/` — neutral router material (`AGENTS.md`).
- `core/skills/_shared/sdd-artifacts/` — portable contracts (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`) for adapters via `Get-SddRoot`.

## Core path placeholders

Product content under `core/` must not hardcode a single IDE user-profile install root. Adapters resolve placeholders at publish:

| Placeholder | Meaning |
|-------------|---------|
| `{{TOOLKIT_ROOT}}` | Agent toolkit install root (skills / policy / router — **destination-aware**; Codex splits plugin skills vs InstallRoot rules) |
| `{{SDD_ROOT}}` | SDD state root (`preferences.json`, `sessions/`, `manifest.json`, optional global Classic tree) |
| `{{GUARDRAILS_PATH}}` | Guardrails policy file path for the target agent |

Adapters may bake absolute paths at publish; at **runtime** skills resolve SDD state via host-aware `effective_SDD_ROOT` ([STORAGE.md](../core/skills/_shared/sdd-artifacts/STORAGE.md)) so a foreign agent's baked `{{SDD_ROOT}}` never wins over the current host.

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
- `scripts/validation/Invoke-AdapterCiSmoke.ps1 -Adapter <id>` (ids from `adapters/registry.json`: cursor, antigravity, claude, codex, copilot, opencode, grok, zcode, hermes, openhands)
- `.github/workflows/validate-toolkit.yml`
- `.github/workflows/master-release-ci.yml`
- `.github/workflows/enforce-release-source.yml`
- `.github/workflows/release.yml`
- `.github/workflows/publish-release-bootstrap.yml`
- `.github/workflows/docs.yml`

## Cursor install layout

InstallRoot models `~/.cursor`. Default publish/smoke targets:

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills from `core/skills/` (placeholders resolved) |
| `rules/*.mdc` | Policy from `core/policy/` (`.md` → `.mdc`) |
| `AGENTS.md` | Router from `core/router/AGENTS.md` |
| `hooks/*.ps1` | Hook scripts from `adapters/cursor/assets/hooks/` (`emit-trace.ps1`, `context-before-prompt.ps1`, `plan-after-edit.ps1`, plus shared `_hook-common.ps1` and `TraceEmitCommon.ps1`) |
| `hooks.json` | Merge at InstallRoot root; path/secrets `preToolUse` + `beforeShellExecution` (`failClosed`) |
| `agents/*.md` | Roster from `core/agents/` when `agents=true` |
| `sdd/sessions/` | SDD sessions directory (`Get-SddRoot -Prepare`) |
| `sdd/manifest.json` | Minimal seed when absent; never overwrite existing |

Smoke/CI: fixture `scripts/validation/fixtures/cursor-install-root`; `Invoke-AdapterCiSmoke.ps1 -Adapter cursor` uses an ephemeral work copy. No Cursor hooks trust UI; no live `~/.cursor` in CI. See [ADAPTERS.md](ADAPTERS.md).

## Antigravity install layout

InstallRoot models `~/.gemini`. Official tree:

| Relative path | Role |
|---------------|------|
| `config/skills` | Kebab Agent Skills + `dev_persona` |
| `config/plugins` | Plugin surface (e.g. GUARDRAILS under managed plugin id) |
| `config/hooks` | Official hooks directory (`hooks=true` → PreToolUse path/secrets guard) |
| `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` | Discovery / managed markdown |

**Legacy bridge** `antigravity-ide/plugins` is documentation / opt-in only — **not** a CI or default-smoke gate.

**Out of scope:** live Knowledge Items (KI); IDE trust UI. CI covers Antigravity via `Invoke-AdapterCiSmoke.ps1 -Adapter antigravity` (filesystem sync+validate on an ephemeral fixture copy — no live `~/.gemini`). Skills stay **kebab-case** under `config/skills`.

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

Smoke/CI: `scripts/validation/fixtures/claude`; `Invoke-AdapterCiSmoke.ps1 -Adapter claude` ephemeral copy. No Claude trust UI; no live `~/.claude` in CI.

## OpenCode install layout

InstallRoot models `~/.config/opencode` ([docs](https://opencode.ai/docs/config/)):

| Relative path | Role |
|---------------|------|
| `skills/<kebab-id>/SKILL.md` | Agent Skills |
| `AGENTS.md` | Router |
| `agents/*.md` | `Publish-Agents` from `core/agents/` (`agents=true`) |
| `plugins/*.js` | OpenCode JS plugins (`tool.execute.before` path/secrets throw) |

Hooks are **plugin-only** (no shell/PS1 parity). CI smoke (`Invoke-AdapterCiSmoke.ps1 -Adapter opencode`) is **filesystem-only** sync+validate against an ephemeral fixture — **not** an OpenCode product runtime.

## ZCode ADE install layout

InstallRoot models `~/.zcode` (ADE filesystem — **not** GLM Coding Plan):

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Kebab Agent Skills |
| `AGENTS.md` | Router surface |
| `agents/*.md` | `Publish-Agents` (`agents=true`) |
| `cli/config.json` | Hooks config |
| `hooks/hooks.json` | User-level hooks merge (PreToolUse path/secrets) |

Fixture: `scripts/validation/fixtures/zcode-install-root/`. CI: `Invoke-AdapterCiSmoke.ps1 -Adapter zcode`.

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
| `copilot-instructions.md` | Always-on instructions with the router source embedded; Copilot has no dedicated router surface (`router=false`) |
| `hooks/*` | Adapter hooks when `hooks=true` (`version:1` `preToolUse` path/secrets) |

**Out of scope:** JetBrains and Eclipse Copilot IDE layouts. CI: `Invoke-AdapterCiSmoke.ps1 -Adapter copilot`.

## Grok Build install layout

InstallRoot **is** `~/.grok` (or project `.grok` passed as InstallRoot) — **native** tree (Claude-style; not nested `.grok/.grok`):

| Relative path | Role |
|---------------|------|
| `skills` | Kebab Agent Skills → live `~/.grok/skills` |
| `rules` | Policy markdown → live `~/.grok/rules` |
| `agents` | Roster from `core/agents/` (`agents=true`) |
| `hooks` | Native hooks incl. PreToolUse path/secrets; `/hooks-trust` is **manual** |
| `AGENTS.md` | Router |

Claude/Cursor paths may be read by the product as compat; MVP **publish** targets InstallRoot directly. Fixture: `scripts/validation/fixtures/grok` (models `~/.grok`).

## Hermes install layout

InstallRoot **is** `~/.hermes` (CI fixture models that home) — skills and `AGENTS.md` sit **directly under** that root (never `~/.hermes/.hermes/skills`):

| Relative path | Role |
|---------------|------|
| `skills/<id>/SKILL.md` | Agent Skills from `core/skills/` (live `$HERMES_HOME/skills`) |
| `AGENTS.md` | Router from `core/router` plus folded `core/policy` (no `rules/` tree) |
| `plugins/agent-dev-toolkit-guard` + `agent-hooks/` | Path/secrets dual hooks (`hooks=true`, `plugin=true`) |
| `memories/MEMORY.md` | Seeded once if missing; never overwritten |
| `SOUL.md` | **Never** created or overwritten |

`Publish-Hooks` installs plugin + shell hooks and keyed-merges only `plugins.enabled` / `hooks.pre_tool_call` — never SOUL / tokens / gateway. The merge keeps non-toolkit keys, including credential-shaped keys, and replaces the whole toolkit `pre_tool_call` item. `Publish-Agents` is a documented no-op (`agents=false`). Subagents: host **`delegate_task`**. Fixture: `scripts/validation/fixtures/hermes`. CI: `Invoke-AdapterCiSmoke.ps1 -Adapter hermes`.

## OpenHands install layout

**Project** InstallRoot (CI / typical sync) models a repository tree — not a nested user-home `.agents/.agents`:

| Relative path | Role |
|---------------|------|
| `.agents/skills/<id>/SKILL.md` | Agent Skills from `core/skills/` (**not** legacy microagents) |
| `.agents/agents/*.md` | Roster from `core/agents/` (SDK/plugin; not Canvas Profile; not native spawn) |
| `AGENTS.md` | Router + folded policy (no `rules/` tree) |
| `.openhands/hooks.json` + `.openhands/hooks/*.sh` | Shell hooks incl. `guard_pre_tool.sh` for `pre_tool_use` path/secrets (never `.ps1`) |
| `.plugin/plugin.json` | Plugin metadata (skills still work without the plugin) |

**Live user skills:** `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` publishes `skills/` directly under that home. `AGENTS.md`, hooks, and plugin metadata stay project-scoped. Capability `subagents=none` — SPAWN fallback in-parent. Do not emit Automation Server, cron, GitHub webhooks, sandbox YAML, or LLM secrets. Fixture: `scripts/validation/fixtures/openhands`. CI: `Invoke-AdapterCiSmoke.ps1 -Adapter openhands`.

## Shared publish rules

Published PowerShell hook JSON readers use `[Console]::OpenStandardInput()` first and `[Console]::In` only when that read is empty. A missing `preferences.json` is created on first sync with `orchestrator_mode` `adaptive`. Copilot agent publish keeps one `nome.agent.md` per catalog agent. OpenCode allow and deny for relative paths lives in `adapters/opencode/assets/plugins/agent-dev-toolkit-marker.js`, not in `GuardCommon.ps1`.

## CI

`.github/workflows/validate-toolkit.yml` runs on `pull_request` to `develop` only. Its topology is `validate-core` (`windows-latest`, runs `validate-core.ps1` and `Assert-SyncAllowUserHomeForward.ps1`) -> `adapter-smoke` (`ubuntu-latest` matrix over the 10 registry adapters) and `adapter-smoke-windows` (one codex smoke for PowerShell path semantics); alongside them `docs-strict` (`ubuntu-latest`) builds MkDocs strictly. The `validate` aggregate depends on all validation jobs; `ci-ok` depends on those same jobs plus `validate`.

Adapter smoke is the generic `Invoke-AdapterCiSmoke.ps1 -Adapter <id>`: it seeds a throwaway root under `.adt-work/`, publishes once, validates with `-SkipCore`, and checks that unrelated operator files survive.

`master-release-ci.yml` emits `ci-ok` on pull requests to `master` or `main` after checking that the head is `develop`. `enforce-release-source.yml` emits `release-source`; it requires `develop` as the source, validates the release opt-in, SemVer version, and bullet-only highlights, and checks release-sync App credentials and permissions. These are separate from the full `develop` suite.

After an opted-in `develop` → `master`/`main` PR merges, `release.yml` preflights the release-sync App, serializes and revalidates the version, tags the promoted commit, creates release notes from `.github/RELEASE_TEMPLATE.md` plus PRs associated with commits in the actual previous-tag-to-promoted-commit range, and calls `publish-release-bootstrap.yml` as a reusable workflow so assets upload in the same run. After every merged release PR (including one that did not opt into a version), the workflow opens a normal reconciliation PR into `develop`: it uses an `ours` merge only when promoted and develop trees are identical; otherwise it performs a real content merge and lets conflicts fail for review. A repository-scoped GitHub App token with contents and pull-request write permissions is required to open that PR and request auto-merge; it does not need branch-rule bypass. Auto-merge waits for normal required checks. `develop` must allow merge commits and must not require linear history, because a rebase or squash would not record the promoted commit as an ancestor.

If publication succeeds but reconciliation fails, dispatch `release.yml` from the promoted `master`/`main` commit with `reconcile_only=true` and a blank version. This retries reconciliation without creating a tag or release. If asset upload alone fails, dispatch `publish-release-bootstrap.yml` with the existing tag. GitHub rulesets and branch protection are external configuration; as checked on 2026-10-29, `protect-develop` requires `validate`, legacy protection also requires `ci-ok`, and `protect-release` requires `release-source`.

`.github/workflows/docs.yml` builds on pushes to `master`, `main`, or `develop`, and on manual dispatch. It deploys GitHub Pages only from pushes to `master` or `main`; pull request documentation acceptance is owned by `docs-strict` in `validate-toolkit.yml`.

OpenCode and peer smokes assert published files on fixtures only — they do **not** launch product runtimes. CI detail: [docs/VALIDATION.md](VALIDATION.md).

See also [ADAPTERS.md](ADAPTERS.md), [overview.md](overview.md), and [domains/core.md](domains/core.md) § Code guidelines and architecture selection.
