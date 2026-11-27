# Using skills

How to invoke toolkit skills after a successful sync. Prefer **skill ids** (kebab-case under `core/skills/`). The **id** is stable across hosts; the prefix is host-specific (`/`, `$`, `use skill`, or the OpenCode `skill` tool). Compat on many hosts: `use skill <id>` or natural language matching the skill `description`.

After any agent sync, invoke **`adt-help-skills`** for the installed static catalog (`CATALOG.md` + `OPERATOR.md`).

**Not skill invoke:** Codex `/hooks` and Grok `/hooks-trust` are **hooks trust UI**, not skill shortcuts. There is **no** Codex product flag `$skill --menu` — the `$` / `/skills` picker is the native skills menu.

## Canonical invoke matrix

| Host | Skills path (live, typical) | Explicit form | Example |
|------|-----------------------------|----------------|---------|
| Cursor | `~/.cursor/skills` | `/id` | `/adt-help-skills` |
| Claude | `~/.claude/skills` | `/id` | `/adt-sdd-spec` |
| Codex | `~/.codex/skills` and/or the Agent Dev Toolkit plugin (+ optional `~/.agents/skills`) | `$id` | `$adt-help-skills` |
| Copilot | `~/.copilot/skills` or `<repo>/.github/skills` | `/id` (+ `/skills reload` after sync) | `/adt-dotnet-developer` |
| OpenCode | `~/.config/opencode/skills` | `skill` tool | `skill({ name: "adt-help-skills" })` |
| Antigravity | `~/.gemini/config/skills` | `use skill id` or `/id` | `use skill adt-sdd-plan` |
| Grok | `~/.grok/skills` | `/id` | `/adt-help-skills` |
| ZCode | `~/.zcode/skills` | `$id` | `$adt-help-skills` |
| Hermes | `~/.hermes/skills` | `/id` | `/adt-help-skills` |
| OpenHands | Project `.agents/skills` or `~/.agents/skills` | Agent Skills (product discovery; mention skill id) | `adt-help-skills` |

## Parallel specialists (default)

After sync, the published router (`core/router/AGENTS.md`) prefers parallel specialist subagents for planning, multi-facet execution, analysis, or non-trivial questions, keeping this session as the parent.

- **`needs_*` → specialist:** O1 spawn map lives in `ROSTER.md` (`Flags (needs_*)`) — point there; do not paste the roster.
- **Task `model`:** omit by default (inherit parent); the parent asks once per session whether subagents inherit or use one verified pair (`SUBAGENT-MODEL.md`).
- **Orchestrate parents:** coordinate / receipts / synthesis — **must not** implement application code.

## Internal contracts

REQ, EVD, STATE, TRACE, selective retrieval, navigation `## Related`, and clarification readiness (B, I, MINOR) are artifact or workflow concepts, not universal authorization gates. Optional `validate-*` diagnostics remain separate from skill authorization. SESSION helpers apply only to consumers whose contracts explicitly require them; Classic SDD and Orchestrated Delivery use the approved PLAN. These concepts add no new slash skills and no second toolkit. SQLite/FTS is out of scope as a deliverable. How the skills call each other: [sessions/README.md](../sessions/README.md).

## Prerequisites

1. Synced at least one agent ([INSTALL.md](../INSTALL.md)).
2. Opened a **consumer** project in that agent.
3. Optional: ran `validate-agent.ps1` against a fixture or live InstallRoot.

## Cursor

Skills sync to `~/.cursor/skills/<id>/SKILL.md`.

| Action | Example |
|--------|---------|
| Slash menu | `/adt-sdd-spec` |
| With args | `/adt-sdd-plan - path/to/PRD.md` |
| Stack router | `/adt-developer` |
| Catalog | `/adt-help-skills` |
| Orchestrated Delivery Step 0 | `/adt-memory-bank` |

Also: Customize → Skills (picker / auto). Rules land as `~/.cursor/rules/*.mdc`. Router: `~/.cursor/AGENTS.md`. If hooks were published, complete Cursor’s hooks trust UI once (outside CI).

## Claude Code

Skills sync to `~/.claude/skills/` (or project `.claude/`). Router file is `CLAUDE.md`. Rules stay `.md` under `rules/`.

Invoke with `/id` (e.g. `/adt-sdd-spec`, `/adt-help-skills`). Review `settings.json` merge and trust hooks in Claude’s UI if required.

Module notes: [adapters/claude/README.md](../../adapters/claude/README.md).

## GitHub Copilot

Requires sync with `-Mode user` or `-Mode repo`:

| Mode | Skills / instructions live under |
|------|----------------------------------|
| `user` | `~/.copilot/skills`, `instructions/`, `copilot-instructions.md` |
| `repo` | `<repo>/.github/skills`, … |

Invoke with `/id` (e.g. `/adt-dotnet-developer`, `/adt-help-skills`). After sync, run **`/skills reload`** so the CLI picks up new skills. JetBrains/Eclipse Copilot paths are out of scope.

## Codex

Codex is **dual-root** for packaging vs rules — do not treat skills and rules as one shared `TOOLKIT_ROOT`:

| Surface | Location |
|---------|----------|
| Plugin skills + CATALOG + OPERATOR | Package source under `InstallRoot/plugins/agent-dev-toolkit`; published for `Both` (default) or `Plugin` |
| Codex-installed plugin copy | `InstallRoot/plugins/cache/<marketplace>/<plugin>/<version>`; managed by Codex, not by toolkit sync |
| Local-file skills | Live `~/.codex/skills`; published for `Both` (default) or `Local` |
| Rules / guardrails (Publish-Policy) | `InstallRoot/rules/*.md` |
| Product / AGENTS / hooks parent | `InstallRoot` (live `~/.codex`) |
| Optional UserScope (opt-in) | Fixture: `InstallRoot/.agents/skills` · Live: `~/.agents/skills` (duplicates `$` if used with home skills) |

- When the same skill is installed locally and in the plugin, both appear as separate entries in the `$` picker. The guided Sync offers `Both`, `Local`, and `Plugin`; direct commands accept `-CodexSkillDistribution` and default to `Both`.
- Changing the distribution does not delete prior copies, so switching from `Both` may leave earlier entries visible until those copies are removed manually.
- The former singular `InstallRoot/plugin` package source is left untouched by sync for manual cleanup.
- Invoke skills with **`$id`** (e.g. `$adt-help-skills`, `$adt-sdd-spec`). The native `$` or `/skills` picker is the product skills menu — **not** a `--menu` CLI flag.
- After sync, invoke **`adt-help-skills`** for the installed catalog — do **not** load every `SKILL.md` to list skills. The same skill id works on **all** adapters.
- Trust plugin hooks with Codex `/hooks` **manually** after a real install — that is trust UI, not skill invoke. Smoke never requires it.

Details: [ADAPTERS.md](../ADAPTERS.md) § Codex · [adapters/codex/README.md](../../adapters/codex/README.md).

## OpenCode

Skills sync to `~/.config/opencode/skills`. Invoke via the **`skill` tool** (not slash-first):

```text
skill({ name: "adt-help-skills" })
```

JS behavior extensions live under `plugins/` (not PS1 hooks). The marker plugin installs no interception hook. `Publish-Agents` → `InstallRoot/agents/`. Module: [adapters/opencode/README.md](../../adapters/opencode/README.md).

## Grok

Expected live skills path: **`~/.grok/skills`**. Invoke with `/id` (e.g. `/adt-help-skills`). Native `.grok` layout; PreToolUse guard shim; `Publish-Agents` → `InstallRoot/agents/`. Hooks trust via `/hooks-trust` if needed (trust UI, not skill invoke).

Module: [adapters/grok/README.md](../../adapters/grok/README.md).

## ZCode

Skills sync to `~/.zcode/skills`. Invoke with **`$id`** (e.g. `$adt-help-skills`). ADE filesystem — not GLM Coding Plan. PreToolUse guard shim. After sync, refresh skills in Settings → Skills if the product requires it.

Module: [adapters/zcode/README.md](../../adapters/zcode/README.md).

## Hermes

Skills sync to **`~/.hermes/skills`** (directly under that home — not `~/.hermes/.hermes/skills`). Invoke with `/id` (e.g. `/adt-help-skills`). Policy is folded into `AGENTS.md` (no `rules/` tree). `memories/MEMORY.md` is seeded only if missing; `SOUL.md` is never written. Hooks: the plugin `agent-dev-toolkit-guard` registers no hook (`HookActivation` `unavailable`); keyed `config.yaml` only `plugins.enabled` — never SOUL/tokens/gateway. An unsupported `config.yaml` format blocks the hook step and leaves the file unchanged. `Publish-Agents` is a no-op (`agents=false`). Subagents: host **`delegate_task`**.

Module: [adapters/hermes/README.md](../../adapters/hermes/README.md).

## OpenHands

**Project** sync writes Agent Skills to `<InstallRoot>/.agents/skills/` (not legacy microagents). **User** skills home: `~/.agents/skills` with `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome`. Invoke via product Agent Skills discovery (mention the skill id). Router + folded policy: `AGENTS.md`. Hooks: `.openhands/hooks.json` + `.openhands/hooks/*.sh` including `guard_pre_tool.sh` for `pre_tool_use` guard shim (fail-closed; shell, not `.ps1`). Plugin metadata: `.plugin/plugin.json` (skills still work without the plugin). Roster markdown under `.agents/agents/` is not native spawn (`subagents=none` — SPAWN fallback in-parent).

Module: [adapters/openhands/README.md](../../adapters/openhands/README.md).

## Antigravity

Skills sync to `~/.gemini/config/skills`. Invoke with **`use skill <id>`** or `/id` (e.g. `use skill adt-sdd-plan`, `/adt-help-skills`). Official `config/*` layout.

Module: [adapters/antigravity/README.md](../../adapters/antigravity/README.md).

## Common workflows

Flow examples below use **skill ids**. Prefix with your host form from the matrix (`/`, `$`, `use skill`, OpenCode `skill` tool, or OpenHands product discovery). Mechanics: [sessions/README.md](../sessions/README.md).

### Orchestrated Delivery

```text
adt-orchestrate-analyze
adt-orchestrate-prepare - features/NNN-slug/
adt-orchestrate-implement - features/NNN-slug/
```

O1 investigates concrete questions, then drafts the feature and its justified stories. O2 runs `adt-sdd-spec` and `adt-sdd-plan` for each eligible story and reconciles the resulting contracts across the set. It presents the complete set for one approval before implementation. O3 hands one PLAN step to each `adt-sdd-develop` child and reconciles its evidence before the next dispatch. [Orchestrated Delivery](../sessions/01-orchestrated-delivery.md)

Specialists answer questions where their expertise can change the outcome. The coordinator records evidence and material decisions in the canonical artifacts. A separate architecture or security note is useful when the investigation warrants one. [Specialist dispatch](../SPAWN.md)

Only unresolved material questions pause dependent work. Record them with the affected scope and continue any independent stories. [Questions and approval](../sessions/01-orchestrated-delivery.md#approval-and-open-questions)

Classic and Orchestrated Delivery use the approved PLAN, its scope, dependencies, acceptance, required validation, and selected cadence to guide implementation. SESSION flags and PLAN claims are not execution prerequisites for these flows. Stack `adt-*-developer` skills still follow the current [toolkit guardrails](../../core/policy/guardrails.md), including explicit task authorization, path safety, and the host's ordinary Shell authorization; a skill reference does not grant broad Shell access.

### Classic SDD contracts (direct)

Use when one story is already clear. O2 reuses spec and plan. O3 delegates individual implementation steps to develop.

```text
adt-sdd-spec
adt-sdd-plan - <prd-path>
adt-sdd-develop - <plan-path> - Step N
adt-read-sdd-artifact - <portable-features-path>   # optional: normalize → source_context
```

Use `step_by_step` to pause after one step or `continuous` to advance through eligible steps. [Classic SDD](../sessions/02-classic-sdd.md)

### One product item (`adt-refine-story`)

Invoke this when shaping a single backlog item. O1 handles feature-level discovery.

```text
adt-refine-story - feature    # User Story / Bug
adt-refine-story - tech       # Technical Story (TSnn)
adt-refine-story - split      # reshape steps → ready for checklist
adt-split-story-checklist - <story-or-backlog-path>
```

Mode is **mandatory** (`feature` \| `tech` \| `split`). Omit it and the skill asks once. It does not assume `feature`. Detail: [sessions/03-backlog-shape.md](../sessions/03-backlog-shape.md).

### Challenge a requirement (`adt-requirement-review`)

Run it before SDD when a feature or story has open questions. Mode is mandatory: `--feature` (functional gaps and acceptance criteria) or `--tech` (contracts and flows checked against the repository). Output: a report with `Status: READY` or `Status: NEEDS_CLARIFICATION`, and Q&A entries under `REFINE/`. Detail: [sessions/03-backlog-shape.md](../sessions/03-backlog-shape.md).

```text
adt-requirement-review --feature - features/NNN-slug/US01/STORY.md
adt-requirement-review --tech - features/NNN-slug/US01/STORY.md
```

### API standards vs typed clients

```text
adt-api-standards                 # agnostic REST / versioning / errors / naming / security hygiene
adt-api-standards - versioning    # optional focus: rest | versioning | errors | naming | security
adt-api-integrate - <openapi>     # OpenAPI → typed clients / DTOs (out of scope for adt-api-standards)
```

Use **`adt-api-standards`** for design review and packing-only conventions (no company contracts). Use **`adt-api-integrate`** when you already have (or will produce) OpenAPI and need generated clients. Handoff is the same call flow — not a second toolkit. Catalog: [SKILLS.md](../SKILLS.md) § Operational.

### Small stack change

```text
adt-developer
```

or `adt-dotnet-developer`, `adt-react-developer`, `adt-python-developer`, …

### After implementation

```text
adt-code-review          # optional; asks single vs multi-angle when omitted; after the report, fix / re-review only (confirm/skip)
adt-code-explain  # describe the change; not a mode of adt-code-review
adt-commit           # message confirmation only; no memory-bank or docs question
adt-push
adt-open-github-pr       # optional, when opening a PR
```

Feature PRs: current `feature/*` (or `feat/*`) → `develop` (**`--squash`** on merge). Release mode: `develop` → `master`/`main` (**`--rebase`**). Prefer `adt-open-github-pr` when `gh` is available; always ask auto-merge. Deep dive: [domains/git-ops.md](../domains/git-ops.md).

### Documentation (RAG)

```text
adt-document-plan        # Kind new | update | refactor; fewer larger steps
adt-document-implement   # one plan step; update may coalesce existing docs
```

Prefer **Kind: update** as one coalesced step when refreshing existing docs after a feature — not one baby-step per file.

## Catalog and decision tree

- Installed map (agents): `adt-help-skills` → `_shared/skills-catalog/CATALOG.md` + `OPERATOR.md` (**52** skills; all adapters)
- Human mirror: [SKILLS.md](../SKILLS.md)
- Language, orchestrator, optional compression: [session-behavior.md](session-behavior.md)
- Caveman may shorten conversational framing but never required specialist analysis, evidence, artifact content, or receipt fields: [ENFORCEMENT.md](../ENFORCEMENT.md) and [SPAWN.md](../SPAWN.md)
- Credits: [CREDITS.md](../CREDITS.md)
- Which skill: [guides/README.md](README.md) and [sessions/README.md](../sessions/README.md)
- First-time path: [01-getting-started.md](01-getting-started.md)

## Re-sync when skills feel stale

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Managed files are overwritten; alien files in the agent home are preserved.
