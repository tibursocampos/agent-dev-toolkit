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

Use **`$<skill-id>`** (example: `$help-skills`). Plugin-only paths do **not** feed `$` discovery â€” sync always mirrors `core/skills` to `InstallRoot/skills` (`~/.codex/skills` when live).

## Spawn / subagents (honesty)

| Field | Value |
|-------|-------|
| Registry / `Get-Capabilities` | `native` |
| Host mechanism | Parallel **subagent** workflows (prompt / `AGENTS.md` / skill instructions); custom agents under `.codex/agents/` or `~/.codex/agents/` |
| Toolkit contract | Prefer spawn language in skills when `subagents=native`; SPAWN fallback if multi-agent tools disabled |
| Published files | `Publish-Agents` copies `core/agents/` â†’ `InstallRoot/agents/` (live `~/.codex/agents/`). Distinct from USER skills `.agents/skills`. |
| Model inherit (REQ-008) | Emit parent inherit: TOML honesty comments + **omit** `model` key (Codex inherits when unset). Reject divergent pins (luna≠terra). |
| Depth / threads | Honesty comments `developer_threads=2`, `orchestrate_threads=4` (SPAWN caps). Do not rewrite operator `config.toml`. |
| Matrix | [`adapters/_shared/spawn-publish-honesty.md`](../_shared/spawn-publish-honesty.md) |

### Official references

- [Subagents](https://developers.openai.com/codex/subagents)
- [Subagents (concepts)](https://developers.openai.com/codex/concepts/subagents)
- [Skills](https://developers.openai.com/codex/skills) (discovery under `.codex/skills`, `.agents/skills` / `~/.agents/skills`)
- [Config basic](https://developers.openai.com/codex/config-basic) (`~/.codex/config.toml`)
- [Hooks](https://developers.openai.com/codex/hooks)
- [Plugins](https://developers.openai.com/codex/plugins)
- [AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)

## Dual root (honesty)

Codex is **dual-root**. Do **not** resolve skill `_shared` under `InstallRoot/rules` â€” home skills use `TOOLKIT_ROOT = InstallRoot`; plugin skills use `TOOLKIT_ROOT = InstallRoot/plugin`; rules live under InstallRoot only.

| Surface | Path |
|---------|------|
| Product / config home (live wizard) | `~/.codex` (`InstallRoot`) |
| Home skills `$` discovery | `InstallRoot/skills` (live `~/.codex/skills`) â€” **always** published |
| Plugin skills `TOOLKIT_ROOT` | `InstallRoot/plugin` (`plugin/skills/â€¦`, incl. CATALOG + OPERATOR via `help-skills`) |
| Rules (Publish-Policy) | `InstallRoot/rules/*.md` |
| USER skills discovery | `~/.agents/skills` |
| Default toolkit sync | Plugin + marketplace + **home skills** under `InstallRoot/skills` |
| Optional USER mirror (fixture) | `Publish-Skills -UserScope` â†’ `InstallRoot/.agents/skills` |
| Optional USER mirror (live `~/.codex` + `-AllowUserHome`) | `Publish-Skills -UserScope` â†’ `$HOME/.agents/skills` (**opt-in only** â€” duplicates `$` picks if combined with home skills) |

### Publish-Router / AGENTS.md

`Publish-Router` materializes `InstallRoot/AGENTS.md` with **absolute** dual-root paths: no remaining `{{â€¦}}` placeholders, and no live `docs/` links. Destination-aware: `{{TOOLKIT_ROOT}}/rules/` â†’ InstallRoot rules tree first, then remaining `{{TOOLKIT_ROOT}}` â†’ plugin root. Callout includes home skills (`$` discovery) path.

### Choosing UserScope

| Goal | Flags |
|------|-------|
| CI / fixture (default) | Omit `-UserScope` â€” plugin + home `InstallRoot/skills` (no `.agents/skills` mirror) |
| Fixture USER mirror | `-UserScope` on non-live InstallRoot â†’ `InstallRoot/.agents/skills` |
| Live `$` discovery | `-InstallRoot ~/.codex -AllowUserHome` â†’ `~/.codex/skills` only (omit `-UserScope`) |
| Live `$` + extra USER mirror | Add explicit `-UserScope` â†’ also `$HOME/.agents/skills` (**duplicates** Personal `$` picks) |

Smoke/CI: absent or empty USER skills root is OK without `-UserScope`. Home `InstallRoot/skills/help-skills` + CATALOG are always required. When UserScope mirrored, smoke asserts help-skills + CATALOG under the resolved USER root. Trust plugin hooks with Codex `/hooks` **manually** after a real install.

## `.codex-plugin` extras (honesty)

On **Publish-Skills**, the adapter keeps only `plugin/.codex-plugin/plugin.json` in that directory. Any other files already present under `.codex-plugin` (alien extras) are **deleted** before rewriting the managed manifest. Do not store custom files there if you need them to survive sync.

Keyed **Uninstall-Toolkit** removes managed `plugin.json`, plugin/home/USER skill ids, marketplace entry, hooks, rules, and owned `AGENTS.md`; it does **not** wipe `plugin/`, `skills/`, or `.agents/` wholesale. Preserves `sdd/sessions` and `sdd/manifest.json`.

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
## TRACE emitters (honesty)

| Field | Value |
|-------|-------|
| Asset | `assets/hooks/emit-trace.ps1` (+ `TraceEmitCommon.ps1`) |
| Publish wire | **Not** claimed: Publish-Hooks remains PreToolUse guard-only this wave |
| Matrix | `adapters/_shared/trace-emitter-honesty.md` |
