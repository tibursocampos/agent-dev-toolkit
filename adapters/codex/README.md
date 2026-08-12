# Codex adapter (`codex`)

Publish surfaces for **Codex** (plugin + marketplace + home `$` skills). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `codex` |
| Purpose | Publish bundled plugin skills, home `$` skills, hooks, rules, and router for Codex |
| Sync fixture | `scripts/validation/fixtures/codex` |
| `subagents` (registry) | `native` |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `plugin` = true |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot .\scripts\validation\fixtures\codex
```

## How to invoke

Use **`$<skill-id>`** (example: `$help-skills`). Plugin-only paths do **not** feed `$` discovery — sync always mirrors `core/skills` to `InstallRoot/skills` (`~/.codex/skills` when live).

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Parallel **subagent** workflows (prompt / `AGENTS.md` / skill instructions); custom agents under `.codex/agents/` or `~/.codex/agents/` |
| Toolkit contract | Prefer spawn language in skills when `subagents=native`; SPAWN fallback if multi-agent tools disabled |
| Published files | `Publish-Agents` copies `core/agents/` → `InstallRoot/agents/` (live `~/.codex/agents/`). Distinct from USER skills `.agents/skills`. |

### Official references

- [Subagents](https://developers.openai.com/codex/subagents)
- [Subagents (concepts)](https://developers.openai.com/codex/concepts/subagents)
- [Skills](https://developers.openai.com/codex/skills) (discovery under `.codex/skills`, `.agents/skills` / `~/.agents/skills`)
- [Config basic](https://developers.openai.com/codex/config-basic) (`~/.codex/config.toml`)
- [Hooks](https://developers.openai.com/codex/hooks)
- [Plugins](https://developers.openai.com/codex/plugins)
- [AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)

## Dual root (honesty)

Codex is **dual-root**. Do **not** resolve skill `_shared` under `InstallRoot/rules` — home skills use `TOOLKIT_ROOT = InstallRoot`; plugin skills use `TOOLKIT_ROOT = InstallRoot/plugin`; rules live under InstallRoot only.

| Surface | Path |
|---------|------|
| Product / config home (live wizard) | `~/.codex` (`InstallRoot`) |
| Home skills `$` discovery | `InstallRoot/skills` (live `~/.codex/skills`) — **always** published |
| Plugin skills `TOOLKIT_ROOT` | `InstallRoot/plugin` (`plugin/skills/…`, incl. CATALOG + OPERATOR via `help-skills`) |
| Rules (Publish-Policy) | `InstallRoot/rules/*.md` |
| USER skills discovery | `~/.agents/skills` |
| Default toolkit sync | Plugin + marketplace + **home skills** under `InstallRoot/skills` |
| Optional USER mirror (fixture) | `Publish-Skills -UserScope` → `InstallRoot/.agents/skills` |
| Optional USER mirror (live `~/.codex` + `-AllowUserHome`) | `Publish-Skills -UserScope` → `$HOME/.agents/skills` (**opt-in only** — duplicates `$` picks if combined with home skills) |

### Publish-Router / AGENTS.md

`Publish-Router` materializes `InstallRoot/AGENTS.md` with **absolute** dual-root paths: no remaining `{{…}}` placeholders, and no live `docs/` links. Destination-aware: `{{TOOLKIT_ROOT}}/rules/` → InstallRoot rules tree first, then remaining `{{TOOLKIT_ROOT}}` → plugin root. Callout includes home skills (`$` discovery) path.

### Choosing UserScope

| Goal | Flags |
|------|-------|
| CI / fixture (default) | Omit `-UserScope` — plugin + home `InstallRoot/skills` (no `.agents/skills` mirror) |
| Fixture USER mirror | `-UserScope` on non-live InstallRoot → `InstallRoot/.agents/skills` |
| Live `$` discovery | `-InstallRoot ~/.codex -AllowUserHome` → `~/.codex/skills` only (omit `-UserScope`) |
| Live `$` + extra USER mirror | Add explicit `-UserScope` → also `$HOME/.agents/skills` (**duplicates** Personal `$` picks) |

Smoke/CI: absent or empty USER skills root is OK without `-UserScope`. Home `InstallRoot/skills/help-skills` + CATALOG are always required. When UserScope mirrored, smoke asserts help-skills + CATALOG under the resolved USER root. Trust plugin hooks with Codex `/hooks` **manually** after a real install.

## `.codex-plugin` extras (honesty)

On **Publish-Skills**, the adapter keeps only `plugin/.codex-plugin/plugin.json` in that directory. Any other files already present under `.codex-plugin` (alien extras) are **deleted** before rewriting the managed manifest. Do not store custom files there if you need them to survive sync.

Keyed **Uninstall-Toolkit** removes managed `plugin.json`, plugin/home/USER skill ids, marketplace entry, hooks, rules, and owned `AGENTS.md`; it does **not** wipe `plugin/`, `skills/`, or `.agents/` wholesale. Preserves `sdd/sessions` and `sdd/manifest.json`.

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
