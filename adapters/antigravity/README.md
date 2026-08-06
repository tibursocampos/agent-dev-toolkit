# Antigravity adapter (`antigravity`)

Publish surfaces for **Antigravity** (`~/.gemini` official `config/*`). Default InstallRoot is an in-repo sync fixture; live `USERPROFILE` roots require `-AllowUserHome`.

| Item | Value |
|------|-------|
| Agent id | `antigravity` |
| Purpose | Publish skills, plugins, and router into the official Antigravity config layout |
| Sync fixture | `scripts/validation/fixtures/antigravity-install-root` |
| `subagents` (registry) | `native` (declared product 2.0+) |

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity -InstallRoot .\scripts\validation\fixtures\antigravity-install-root
```

## How to invoke

| Item | Value |
|------|-------|
| Skills path (live) | `~/.gemini/config/skills` |
| Explicit form | `use skill id` or `/id` |
| Examples | `use skill sdd-plan`, `/help-skills` |

Canonical form is the skill **id**.

## Spawn / subagents (honesty)

Hierarchical subagents exist since **Antigravity 2.0** via `invoke_subagent` (async by default, nesting ≤10, optional git worktrees). Pré-2.0 Agent Manager ran parallel agents in separate conversations — not parent→child in-session delegation.

| Field | Value |
|-------|-------|
| Registry | `native` (Tier 1 assumes product line 2.0+) |
| Effective (`Get-Capabilities`) | **Probe fail-closed** — see below |
| Host mechanism | `invoke_subagent` / `define_subagent` / `/agents` |

### Probe policy (`Resolve-AntigravitySubagentsCapability`)

1. Override `ADT_ANTIGRAVITY_SUBAGENTS` ∈ {`native`,`none`} (CI/tests).
2. Optional product version via `ADT_ANTIGRAVITY_PRODUCT_VERSION` (`>= 2.0.0` → native; `< 2.0.0` → none).
3. Else `agy --version`: CLI parseável `>= 1.0.0` = proxy of shared 2.0 harness (**do not** gate on CLI major ≥ 2 — CLI is `1.x`).
4. Missing binary / parse failure / unknown → **`none`**.

SPAWN/skills must use **effective** capability, not registry alone. Contract: `core/skills/_shared/agents/SPAWN.md`. Matrix: [docs/SPAWN.md](../../docs/SPAWN.md).

### Official references

- [Subagents (Antigravity 2.0)](https://antigravity.google/docs/subagents)
- [CLI — Background tasks & subagents](https://antigravity.google/docs/cli/subagents)
- [Docs home](https://antigravity.google/docs/home)
- [Skills](https://antigravity.google/docs/skills)
- [Rules & workflows](https://antigravity.google/docs/rules-workflows)
- [Hooks](https://antigravity.google/docs/hooks)
- [Plugins](https://antigravity.google/docs/plugins)
- [Product](https://www.antigravity.google/)
- [I/O 2026 feature deep dive](https://antigravity.google/blog/google-io-2026-feature-deep-dive)

## Publish layout vs twin IDE steering

ADT InstallRoot models `~/.gemini` and publishes under `config/skills`, `config/skills.json`, `config/AGENTS.md`, and `config/plugins/…/GUARDRAILS.md`.

The single-agent twin (`antigravity-dev-toolkit`) steers the IDE by writing skill bodies under `antigravity-ide/plugins/<id>/skills/`, putting GUARDRAILS beside that plugin, and pointing `config/skills.json` `entries[].path` at the plugin skills directory (plus a managed block in `config/AGENTS.md`). That twin layout is **not** ADT’s default publish path; document it so operators know where live IDE discovery often looks.

Public contract: [docs/ADAPTERS.md](../../docs/ADAPTERS.md).
