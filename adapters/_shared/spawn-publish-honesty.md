# Publish spawn knobs honesty (REQ-003 / REQ-008 / CA8 / RNF-002)

Host-agnostic honesty for **depth / threads / inherit** on `Publish-*`. Caps
match `core/skills/_shared/agents/SPAWN.md` (developer **≤2**, orchestrate
**≤4**). Axis B/C: emit **inherit** (or omit model) — never pin child≠parent
(e.g. luna≠terra). Do **not** rewrite SPAWN Eixo A (spawn vs in-parent).

Shared helper: [`SpawnPublishKnobs.ps1`](SpawnPublishKnobs.ps1).

**Audit SoT:** rows below must stay parity with `adapters/registry.json`
`capabilities.subagents` (`native` | `none`) and `capabilities.agents`.

## Matrix (registry parity)

| Host | registry `subagents` | `agents` | Agents publish surface | Model inherit | Depth / threads | Notes |
|------|----------------------|----------|------------------------|---------------|-----------------|-------|
| **Cursor** | native | true | `agents/*.md` frontmatter | `model: inherit` required; Publish asserts | Caps in SPAWN / skills (≤2/≤4); not host YAML knobs | Assert after Publish-Agents |
| **Claude** | native | true | `agents/*.md` frontmatter | `model: inherit` (+ host FORCE if operator sets) | Same SPAWN caps | Markdown copy via managed publish |
| **Codex** | native | true | `agents/*.toml` | **Emit parent inherit**: honesty comments + **omit** `model` key (product inherit-when-unset) | Honesty comments `developer_threads=2`, `orchestrate_threads=4` | Never write divergent `model =` |
| **Copilot** | native | true | markdown agents when Mode=repo (`agents=true`) | `model: inherit` when files published; Mode=user Publish-Agents no-op | SPAWN caps; host config not rewritten | Repo `.github/agents` only |
| **Grok** | native | true | `agents/*.md` | `model: inherit` when files published | SPAWN caps; host config not rewritten | Publish asserts after copy |
| **ZCode** | native | true | `agents/*.md` | `model: inherit` when files published | SPAWN caps; host config not rewritten | Publish asserts after copy |
| **OpenCode** | native | true | `agents/*.md` | `model: inherit` when files published | SPAWN caps; **do not** emit `delegation.max_spawn_depth` / host config.toml knobs | Agents=true in registry (not no-op) |
| **Hermes** | native | false | Publish-Agents no-op | — | **Honesty:** do not emit `delegation.max_spawn_depth` / host config.toml knobs | Native spawn via host; no agents roster rewrite |
| **Antigravity** | native | false | Publish-Agents no-op | — | **Honesty:** do not emit host max-depth knobs | Host `invoke_subagent` only |
| **OpenHands** | **none** | true | SDK/plugin roster copy only | Roster may carry `model: inherit` from `core/agents` (supply-chain) | **Honesty-only:** no spawn pin; do not invent spawn depth/threads knobs | `subagents=none` — roster ≠ host spawn |

## Supply-chain rule (SEC)

Publish may emit **only** depth, threads, and inherit honesty. Forbidden: pinning
an external/alternate child model slug at publish time. OpenHands must not gain a
spawn pin just because agents files are copied.
