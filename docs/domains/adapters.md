# Domain: Adapters

Adapters map `core/` into each agent’s install layout and expose a stable PowerShell surface for sync, validate, smoke, and uninstall.

**Authoritative per-agent detail:** [ADAPTERS.md](../ADAPTERS.md). This page is the RAG-friendly summary.

## Registry

File: `adapters/registry.json`

| Field | Meaning |
|-------|---------|
| `id` | CLI `-Agent` token |
| `displayName` | Human label |
| `module` | Path under `adapters/` to dot-source |
| `capabilities` | Boolean publish flags + string `subagents` enum (`native` \| `none`) |

List agents:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
```

## Registered agents

| id | Module | Typical live root |
|----|--------|-------------------|
| `cursor` | `cursor/CursorAdapter.ps1` | `~/.cursor` |
| `antigravity` | `antigravity/AntigravityAdapter.ps1` | `~/.gemini` |
| `claude` | `claude/ClaudeAdapter.ps1` | `~/.claude` |
| `codex` | `codex/CodexAdapter.ps1` | `~/.codex` (dual-root: plugin skills + `rules/` + optional `~/.agents/skills`) |
| `copilot` | `copilot/CopilotAdapter.ps1` | `~/.copilot` or `.github` |
| `opencode` | `opencode/OpenCodeAdapter.ps1` | `~/.config/opencode` |
| `grok` | `grok/GrokAdapter.ps1` | `~/.grok` |
| `zcode` | `zcode/ZCodeAdapter.ps1` | `~/.zcode` |
| `hermes` | `hermes/HermesAdapter.ps1` | `~/.hermes` (skills + `AGENTS.md` at that root) |
| `openhands` | `openhands/OpenHandsAdapter.ps1` | Project tree; user skills `~/.agents/skills` |

Contract stubs / shared helpers: `adapters/_contract/AdapterContract.ps1`.

## Public commands

| Command | Intent |
|---------|--------|
| `Get-Capabilities` | Capability flags (incl. `subagents`) |
| `Get-InstallRoots` | Official roots metadata |
| `Publish-Skills` / `Publish-Policy` / `Publish-Router` / `Publish-Hooks` | Publish into InstallRoot |
| `Get-SddRoot` | Resolve / prepare SDD state root |
| `Invoke-SmokeValidate` | Fixture filesystem smoke |
| `Uninstall-Toolkit` | Keyed removal of toolkit artifacts (all adapters; preserves SDD state) |

Orchestrators: `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`, `scripts/toolkit.ps1`. **Backup** (`-Action Backup`) is a CLI stub only — it does **not** call an adapter.

## Subagents / SPAWN

Capability `subagents` is the string enum `native` \| `none` (not boolean). Most adapters declare `native`. **OpenHands** declares `none` (Canvas/ACP is not parent→child; SPAWN fallback in-parent). **Antigravity** *effective* capability may differ (fail-closed version probe). Contract: [SPAWN.md](../SPAWN.md) and `core/skills/_shared/agents/SPAWN.md`. Language surfaces: `core/skills/_shared/agents/LANGUAGE.md` (chat + artifacts match user chat; spawn/receipts **en-US**). Per-host spawn mechanism: each adapter README **Spawn / subagents** section.

## Notable semantics

| Topic | Behavior |
|-------|----------|
| Home guard | USERPROFILE paths need `-AllowUserHome` |
| Copilot Mode | `-Mode user\|repo` required |
| OpenCode hooks | Plugin JS only (`HooksSemantics=plugin-only`); CI smoke = filesystem only |
| Codex dual-root | Plugin skills under `InstallRoot/plugin`; Publish-Policy → `InstallRoot/rules`; default sync plugin-only; `-UserScope` → fixture `.agents/skills` or live `~/.agents/skills` (+ `-AllowUserHome`) |
| Codex / Grok trust | Manual in the product UI; never required for CI green |
| ZCode vs GLM | `zcode` = ADE filesystem; GLM Coding Plan is out of scope |
| Hermes | Native `$HERMES_HOME`; policy folded into `AGENTS.md`; no `rules/`; `hooks=true` + `plugin=true` (path/secrets dual); `agents=false`; `delegate_task`; `memories/MEMORY.md` seed-if-missing; never SOUL.md / tokens / gateway |
| OpenHands | Project tree + optional `~/.agents/skills`; Agent Skills not microagents; shell `pre_tool_use` + `guard_pre_tool.sh` (fail-closed); `subagents=none` |
| Path/secrets guard | Shared `adapters/_shared/guard-rules.md` + `GuardCommon.ps1` — outside workspace deny; write without path deny; host wiring in [ADAPTERS.md](../ADAPTERS.md) |
| Antigravity legacy | `antigravity-ide/plugins` opt-in / docs only — not default smoke |
| Keyed uninstall | All registered adapters; preserves `sdd/sessions` + `sdd/manifest.json` |
| Sync prepare | Every sync runs `Get-SddRoot -Prepare` |

## Publish knobs honesty (depth / threads / inherit)

Contract: [`adapters/_shared/spawn-publish-honesty.md`](../../adapters/_shared/spawn-publish-honesty.md) + helper `SpawnPublishKnobs.ps1` (REQ-008 / CA8). Caps match [`SPAWN.md`](../SPAWN.md): developer **≤2**, orchestrate **≤4**.

Publish may emit **only** depth, threads, and model **inherit** honesty. Forbidden: pinning an alternate child model slug at publish time (e.g. child≠parent).

| Host | Agents surface | Model inherit | Depth / threads |
|------|----------------|---------------|-----------------|
| Cursor / Claude | `agents/*.md` frontmatter | `model: inherit` required | SPAWN caps in skills; not host YAML knobs |
| Codex | `agents/*.toml` | Honesty comments + **omit** `model` key | Comments `developer_threads=2`, `orchestrate_threads=4` |
| ZCode / OpenHands / Grok / Copilot (repo) | markdown when `agents=true` | `model: inherit` when published | SPAWN caps; host config not rewritten |
| Hermes / OpenCode / Antigravity | `agents=false` or no-op | — | Do **not** emit `delegation.max_spawn_depth` / host config knobs |

## TRACE emitter honesty

Contract: [`adapters/_shared/trace-emitter-honesty.md`](../../adapters/_shared/trace-emitter-honesty.md). Shared helper `TraceEmitCommon.ps1` (allowlist + fail-open + path policy). Core schema: [TRACE archive](core.md#trace-archive-living-loop).

| Host | Wired TRACE emitter? | Notes |
|------|----------------------|-------|
| **Cursor** | Yes — `assets/hooks/emit-trace.ps1` via `hooks.json` (`postToolUse`, `subagentStop`) | Prefer inherit; Explore Task may diverge |
| **Claude** | Yes — `emit-trace.ps1` (+ `plan-after-edit` on PostToolUse) | Merge/settings keyed upsert |
| **Codex** | Asset present; **Publish-Hooks still PreToolUse guard only** | Do **not** claim live PostToolUse TRACE wire yet |
| **OpenHands** | No | Shell `pre_tool_use` only; spawn `none` → in-parent |
| **OpenCode** | No | Plugin JS hooks (`HooksSemantics=plugin-only`) — not PS1 parity |
| Hermes / Grok / Copilot / Antigravity / ZCode | No | Guard PreToolUse (or equivalent) where present; TRACE emit not claimed this wave |

Fail-open: emitter exit **0** always; never append `tool_input` / bodies / secrets. CI probe: `TOOLKIT_TRACE_FORCE_FAIL=1` skips append, still exit 0. Assert: `Assert-TraceEmitterFailOpen.ps1`. Trusted-CI-only: `TOOLKIT_TRACE_FEATURE_ROOT` → in-repo fixture `features/NNN-slug` — never live `USERPROFILE`.

## Module READMEs

- [adapters/cursor/README.md](../../adapters/cursor/README.md) — hooks merge; keyed uninstall (preserves SDD)
- [adapters/antigravity/README.md](../../adapters/antigravity/README.md) — official `config/*`; spawn probe
- [adapters/claude/README.md](../../adapters/claude/README.md) — settings merge, narrow permissions, keyed uninstall
- [adapters/codex/README.md](../../adapters/codex/README.md) — dual-root plugin/rules; UserScope; keyed uninstall
- [adapters/copilot/README.md](../../adapters/copilot/README.md) — Mode user\|repo; keyed uninstall
- [adapters/opencode/README.md](../../adapters/opencode/README.md) — plugin-only hooks; keyed uninstall
- [adapters/grok/README.md](../../adapters/grok/README.md) — native `.grok`, trust note; keyed uninstall
- [adapters/zcode/README.md](../../adapters/zcode/README.md) — ADE filesystem; keyed uninstall (preserves SDD)
- [adapters/hermes/README.md](../../adapters/hermes/README.md) — native `~/.hermes`; folded policy; `delegate_task`; keyed uninstall
- [adapters/openhands/README.md](../../adapters/openhands/README.md) — project tree + user skills; not microagents; keyed uninstall

## Related

- [ADAPTERS.md](../ADAPTERS.md) — full contract
- [ARCHITECTURE.md](../ARCHITECTURE.md) — install layout tables
- [domains/cli-scripts.md](cli-scripts.md)
