# Publish spawn knobs honesty (REQ-008 / CA8 / RNF-002)

Host-agnostic honesty for **depth / threads / inherit** on `Publish-*`. Caps
match `core/skills/_shared/agents/SPAWN.md` (developer **≤2**, orchestrate
**≤4**). Axis B/C: emit **inherit** (or omit model) — never pin child≠parent
(e.g. luna≠terra). Do **not** rewrite SPAWN Eixo A (spawn vs in-parent).

Shared helper: [`SpawnPublishKnobs.ps1`](SpawnPublishKnobs.ps1).

## Matrix

| Host | Agents publish surface | Model inherit | Depth / threads | Notes |
|------|------------------------|---------------|-----------------|-------|
| **Cursor** | `agents/*.md` frontmatter | `model: inherit` required | Caps enforced in SPAWN / skills (≤2/≤4); not host YAML knobs | Assert after Publish-Agents |
| **Claude** | `agents/*.md` frontmatter | `model: inherit` (+ host FORCE if operator sets) | Same SPAWN caps | Markdown copy via managed publish |
| **Codex** | `agents/*.toml` | **Emit parent inherit**: honesty comments + **omit** `model` key (product inherit-when-unset) | Honesty comments `developer_threads=2`, `orchestrate_threads=4` | Fix: no longer drop inherit without emit; never write divergent `model =` |
| **ZCode / OpenHands / Grok / Copilot (repo)** | markdown agents when `agents=true` | `model: inherit` when files published | SPAWN caps; host config not rewritten | OpenHands roster ≠ native spawn |
| **Hermes / OpenCode / Antigravity** | `agents=false` or no-op | — | **Honesty:** do not emit `delegation.max_spawn_depth` / host config.toml knobs | Operator configures host; toolkit stays SPAWN-aligned in skills |

## Supply-chain rule (SEC)

Publish may emit **only** depth, threads, and inherit honesty. Forbidden: pinning
an external/alternate child model slug at publish time.
