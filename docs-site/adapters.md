# Adapters

Adapters publish the shared **core** (skills, policy, router, hooks where supported) into each agent’s install layout. Orchestrators (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolve an agent via `adapters/registry.json`, then call that entry’s PowerShell module.

For the product walkthrough, start at [Get started](../get-started/). Core vs adapters: [Architecture](../architecture/). After sync: [Using skills](../using-skills/).

## Supported agents

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

Closed implemented set: these 10 ids. Each has a concrete module with publish + in-repo smoke test.

## Codex note

Codex is **dual-root**: plugin skills live under `InstallRoot/plugin` (`rules=true` Publish-Policy → `InstallRoot/rules`); product/AGENTS/hooks parent is InstallRoot (live `~/.codex`). Default sync is **plugin-only**; optional `-UserScope` mirrors skills to fixture `InstallRoot/.agents/skills` or live `~/.agents/skills` (needs `-AllowUserHome`). Full contract: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) · operator guide: [Using skills](../using-skills/).

## Hermes note

Live InstallRoot is `$HERMES_HOME` (typical `~/.hermes`). Skills and `AGENTS.md` land **directly** under that root. Policy is folded into `AGENTS.md` (no `rules/` tree). Hooks **are** published: plugin `agent-dev-toolkit-guard` + shell `agent-hooks` path/secrets; keyed merge of `config.yaml` only for `plugins.enabled` / `hooks.pre_tool_call` — never SOUL / tokens / gateway. Invoke skills with `/id`. `Publish-Agents` is a no-op.

## OpenHands note

**Project** InstallRoot is the repo root: skills at `.agents/skills/`, roster at `.agents/agents/`, folded `AGENTS.md`, shell hooks under `.openhands/` (incl. `guard_pre_tool.sh` for `pre_tool_use` path/secrets, fail-closed), plugin metadata at `.plugin/plugin.json`. **Live user skills** use `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` so skills land at `~/.agents/skills`. Canvas is **not** subagent spawn (`subagents=none`; SPAWN fallback in-parent).

## Path/secrets (all capable hosts)

Shared rules: [`adapters/_shared/guard-rules.md`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/_shared/guard-rules.md) + `GuardCommon.ps1`. Outside-workspace and pathless writes are deny. Full host matrix: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md).

## Publish knobs honesty (depth / threads / inherit)

Publish may emit **only** SPAWN-aligned depth/threads honesty and model **inherit** (or omit model). Caps: `*-developer` **≤2**, `orchestrate-*` **≤4**. Never pin a child≠parent model slug at publish time. Hosts with `agents=false` / no-op (Hermes, OpenCode, Antigravity): do **not** emit host `delegation.max_spawn_depth` knobs. Contract: [`spawn-publish-honesty.md`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/_shared/spawn-publish-honesty.md) · [domains/adapters.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/adapters.md#publish-knobs-honesty-depth--threads--inherit).

## TRACE emitter honesty

Core trail SoT remains `features/NNN-slug/TRACE.jsonl` only. Emitters are fail-open (exit 0; never append secrets / `tool_input`). Claim only what is wired:

| Claim | Hosts |
|-------|--------|
| **Wired** fail-open `emit-trace.ps1` | Cursor (`hooks.json` postToolUse / subagentStop); Claude (PostToolUse / SubagentStop) |
| **Asset only** — not live PostToolUse wire | Codex (`Publish-Hooks` still PreToolUse guard) |
| **Not claimed** | OpenHands, OpenCode, Hermes, Grok, Copilot, Antigravity, ZCode |

Contract: [`trace-emitter-honesty.md`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/_shared/trace-emitter-honesty.md) · assert `Assert-TraceEmitterFailOpen.ps1`.

## How sync works

1. Prefer interactive `scripts/toolkit.ps1` (Smart Manager).
2. Resolve `-Agent <id>` in [`adapters/registry.json`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/registry.json).
3. Load the adapter module (`Publish-*`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`, …).
4. Default `InstallRoot` is an in-repo fixture; live USERPROFILE paths require explicit `-AllowUserHome`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
# or: -Agent cursor | copilot | hermes | openhands | …
```

## Source tree

Per-agent READMEs and modules live under the repository adapters directory:

- [adapters/ on GitHub](https://github.com/tibursocampos/agent-dev-toolkit/tree/master/adapters)
- Full contract and install-root tables: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md)

Next: [Get started](../get-started/) · [Using skills](../using-skills/) · [Architecture](../architecture/)
