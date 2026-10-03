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

## Shell execution, sandbox, and approvals

Codex command execution has two separate controls: the **sandbox** limits filesystem and network access; the **approval policy** decides when Codex must pause before crossing those limits. A command can therefore fail even when the operator is signed in to a CLI such as `gh`: authentication does not grant the sandbox network access, and credentials visible to the host may not be available to the command process.

When PowerShell, `gh`, or another shell command fails:

1. Read the actual error and determine whether it points to command syntax/runtime, a missing executable or credential, a sandbox filesystem boundary, or blocked network access. Do not assume every failure is a sandbox failure.
2. Check which execution surface is active (native Windows, WSL, IDE/CLI, or managed remote environment); their shells, paths, credentials, and policies differ. On Windows, the native Codex sandbox has elevated and unelevated implementations; an enterprise policy may restrict which one can be used.
3. If the error indicates a sandbox boundary, explain the exact blocked operation and request the host's normal approval or the narrowest supported exception. For a repeatable command exception, prefer a narrowly scoped Codex rule; for an additional project path, prefer a specific writable root. Keep the project boundary and network restrictions otherwise intact.
4. If approval is denied, auto-review rejects the request, or policy disables escalation, stop that operation and report the blocker. Do not switch to an unapproved external shell, another tool, a broader permission profile, or a different network path to get the same effect.
5. Never change `config.toml`, turn on unrestricted network access, choose full access, or weaken sandbox settings during setup unless the operator explicitly asks. Explain the consequence and point to the host settings; the toolkit does not configure Codex permissions.

For `gh`, separately verify that `gh auth status` succeeds **inside the same command environment** and that the sandbox permits the required GitHub host. Do not print or forward tokens as a diagnostic. Prefer a single approved command or a narrow rule over a session-wide permission change.

### Official sandbox references

- [Codex sandboxing and approvals](https://learn.chatgpt.com/docs/sandboxing) — explains the difference between sandbox boundaries and approval policy, and describes narrow rules and writable roots.
- [Native Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox) — elevated/unelevated implementations, network boundary, and platform troubleshooting.
- [Codex rules](https://learn.chatgpt.com/docs/rules) — command-prefix rules for specific exceptions.
- [Codex configuration](https://learn.chatgpt.com/docs/configuration) — persistent sandbox and approval settings.

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


### Child assignment lifecycle

Batch related, bounded work before dispatch. Each dispatched task is one child assignment: once that child returns any result (complete, incomplete, blocked, or failed), treat the handle as closed and never follow up, reopen, resume, or reuse it. Any new task, review, or correction—including a lengthy correction to returned work—must use a fresh child handle; do not send returned work back to its former child. Clarifications are allowed only while the child is still running and must stay within its original assignment. Use the host's close/stop control when available; handle termination, retention, and context erasure are host-controlled, so do not promise that a returned child process or its context was killed or erased. Canonical policy: `core/skills/_shared/agents/SPAWN.md`.

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
