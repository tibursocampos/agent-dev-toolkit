# Publish spawn knobs honesty (006 REQ-003 / REQ-008 / 007 REQ-002 / CA1 / RNF-002)

Host-agnostic honesty for **depth / threads / inherit** on `Publish-*`. Caps
match `core/skills/_shared/agents/SPAWN.md` (developer **≤2**, orchestrate
**≤4**). Axis B/C: emit **inherit** (or omit model) — never pin child≠parent
(e.g. luna≠terra). Do **not** rewrite SPAWN Eixo A (spawn vs in-parent).

Shared helper: [`SpawnPublishKnobs.ps1`](SpawnPublishKnobs.ps1).

**Audit SoT:** rows below must stay parity with `adapters/registry.json`
`capabilities.subagents` (`native` | `none`) and `capabilities.agents`.

**REQ map (do not conflate feature numbers):** 006 REQ-003 = Publish inherit/omit honesty; marker **REQ-008** retained for the Related-template supply-chain pairing from contracts wave; 007 REQ-002 = Axis B densified agents stay inherit.

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

## Software supply-chain rule (SEC)

Publish may emit **only** depth, threads, and inherit honesty. Forbidden: pinning
an external/alternate child model slug at publish time. OpenHands must not gain a
spawn pin just because agents files are copied.

## Enriched roster honesty (Axis B)

Canonical `core/agents/*.md` keep frontmatter `model: inherit` (Markdown hosts) or
**omit** the `model` key (Codex TOML inherit-when-unset). Do **not** rewrite SPAWN
Eixo A. Task spawn policy remains omit-`model` by default — see
`core/skills/_shared/agents/SUBAGENT-MODEL.md` (A≠B≠C).

## Session pair choice (US01)

Source of options: `core/skills/_shared/agents/SUBAGENT-OPTIONS.md` and the adapter rows of the TS02 matrix; this file does not copy lists.

After the global capability-first check, discover current model/effort choices from the active host surface before asking. The initial question lists concrete complete pairs and `inherit`; if discovery yields no pair, offer `inherit` only and explain why. A schema or picker proves a candidate is exposed, not that runtime applied it; keep those evidence states separate.

| Adapter | Matrix row | Question mechanism (`QUESTIONS.md`) | Pair mapping and restrictions | Prompt rule vs host mechanism | Limitation |
|---------|------------|-------------------------------------|-------------------------------|------------------------------|------------|
| claude | ADP-CLAUDE | `AskUserQuestion` | Use the pair mapping from ADP-CLAUDE; per-invocation `model` and `effort` are documented, subject to version, model, fork, and environment restrictions. | Prompt rule (no physical containment): the child prompt omits preferences and options. Host mechanism: per-invocation model and effort are documented; actual application is not verified. | Installed version, accessible catalog, effective schema, and execution are UNKNOWN; environment or policy may override. |
| codex | ADP-CODEX | `none` (numbered text) | Use the pair mapping from ADP-CODEX; this session exposes `model`, `reasoning_effort`, and `fork_turns`, but an alternate pair is not proven at runtime. Do not change fork/history. | Prompt rule (no physical containment): the child prompt omits preferences and options. Host mechanism: session tool schema exposes the fields; account/runtime acceptance is unverified. | Account availability and alternate-pair runtime are UNKNOWN; do not infer support from this session schema. |
| cursor | ADP-CURSOR | `none` (numbered text until answer delivery is verified) | Use the pair mapping from ADP-CURSOR; the documented `id[effort=value]` format does not establish that the active spawn schema accepts it. | Prompt rule (no physical containment): the child prompt omits preferences and options. Host mechanism: model-plus-effort encoding is documented; current picker and spawn schema are unverified. | Effective picker, per-call schema, client surface, and runtime are UNKNOWN. |
| hermes | ADP-HERMES | `ask_user` | Use the pair mapping from ADP-HERMES only through a compatible existing `model_map` or `profile_routes`; no universal free-pair route is assumed. | Prompt rule (no physical containment): the child prompt omits preferences and options. Host mechanism: existing compatible profile routing may select an option; no route is configured or created here. | Installation, existing route compatibility, effort mapping, and execution are UNKNOWN. |
| copilot | ADP-COPILOT | `none` (numbered text) | Use the pair mapping from ADP-COPILOT; CLI model and `reasoningEffort` documentation is surface-specific and is not a verified per-call schema for IDE or cloud. | Prompt rule (no physical containment): the child prompt omits preferences and options. Host mechanism: documented CLI controls do not prove the current task tool's effective pair. | Account options, per-call schema, IDE/cloud support, and effective runtime values are UNKNOWN. |
