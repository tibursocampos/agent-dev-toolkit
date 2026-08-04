# Codex adapter (`codex`)

Publish surfaces for **Codex** (plugin + marketplace packaging). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `codex` |
| Purpose | Publish bundled plugin skills, hooks, rules, and router for Codex |
| Sync fixture | `scripts/validation/fixtures/codex` |
| `subagents` (registry) | `native` |
| Capabilities | `skills` / `rules` / `hooks` / `router` / `plugin` = true |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot .\scripts\validation\fixtures\codex
```

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Parallel **subagent** workflows (prompt / `AGENTS.md` / skill instructions); custom agents under `.codex/agents/` or `~/.codex/agents/` |
| Toolkit contract | Prefer spawn language in skills when `subagents=native`; SPAWN fallback if multi-agent tools disabled |

### Official references

- [Subagents](https://developers.openai.com/codex/subagents)
- [Subagents (concepts)](https://developers.openai.com/codex/concepts/subagents)
- [Skills](https://developers.openai.com/codex/skills) (discovery under `.agents/skills` / `~/.agents/skills`)
- [Config basic](https://developers.openai.com/codex/config-basic) (`~/.codex/config.toml`)
- [Hooks](https://developers.openai.com/codex/hooks)
- [Plugins](https://developers.openai.com/codex/plugins)
- [AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)

## Dual root (honesty)

Codex is **dual-root**. Do **not** resolve skill `_shared` under `InstallRoot/rules` — skills live under the plugin `TOOLKIT_ROOT`; rules live under InstallRoot only.

| Surface | Path |
|---------|------|
| Product / config home (live wizard) | `~/.codex` (`InstallRoot`) |
| Plugin skills `TOOLKIT_ROOT` | `InstallRoot/plugin` (`plugin/skills/…`, incl. CATALOG + OPERATOR via `help-skills`) |
| Rules (Publish-Policy) | `InstallRoot/rules/*.md` |
| USER skills discovery | `~/.agents/skills` |
| Default toolkit sync | **Plugin-only** under `InstallRoot/plugin/` (+ marketplace under `.agents/plugins`) |
| Optional USER mirror (fixture) | `Publish-Skills -UserScope` → `InstallRoot/.agents/skills` |
| Optional USER mirror (live `~/.codex` + `-AllowUserHome`) | `Publish-Skills -UserScope` → `$HOME/.agents/skills` |

### Publish-Router / AGENTS.md

`Publish-Router` materializes `InstallRoot/AGENTS.md` with **absolute** dual-root paths: no remaining `{{…}}` placeholders, and no live `docs/` links. Destination-aware: `{{TOOLKIT_ROOT}}/rules/` → InstallRoot rules tree first, then remaining `{{TOOLKIT_ROOT}}` → plugin root.

### Choosing UserScope

| Goal | Flags |
|------|-------|
| CI / fixture (default) | Omit `-UserScope` — plugin skills only |
| Fixture USER mirror | `-UserScope` on non-live InstallRoot → `InstallRoot/.agents/skills` |
| Live USER skills | `-InstallRoot ~/.codex -AllowUserHome -UserScope` → `$HOME/.agents/skills` |

Smoke/CI never require a live `~/.agents/skills` write. Trust plugin hooks with Codex `/hooks` **manually** after a real install.

## `.codex-plugin` extras (honesty)

On **Publish-Skills**, the adapter keeps only `plugin/.codex-plugin/plugin.json` in that directory. Any other files already present under `.codex-plugin` (alien extras) are **deleted** before rewriting the managed manifest. Do not store custom files there if you need them to survive sync.

Keyed **Uninstall-Toolkit** removes the managed `plugin.json` (and an empty `.codex-plugin` dir when applicable); it does **not** wipe `plugin/` or `.agents/` wholesale. Preserves `sdd/sessions` and `sdd/manifest.json`.

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
