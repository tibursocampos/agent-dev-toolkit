# Using skills

How to invoke toolkit skills after a successful sync. Prefer **skill ids** (kebab-case under `core/skills/`). The **id** is stable across hosts; the prefix is host-specific (`/`, `$`, `use skill`, or the OpenCode `skill` tool). Compat on many hosts: `use skill <id>` or natural language matching the skill `description`.

After any agent sync, invoke **`help-skills`** for the installed static catalog (`CATALOG.md` + `OPERATOR.md`).

**Not skill invoke:** Codex `/hooks` and Grok `/hooks-trust` are **hooks trust UI**, not skill shortcuts. There is **no** Codex product flag `$skill --menu` — the `$` / `/skills` picker is the native skills menu.

## Canonical invoke matrix

| Host | Skills path (live, typical) | Explicit form | Example |
|------|-----------------------------|----------------|---------|
| Cursor | `~/.cursor/skills` | `/id` | `/help-skills` |
| Claude | `~/.claude/skills` | `/id` | `/sdd-spec` |
| Codex | `~/.codex/skills` (+ optional `~/.agents/skills`) | `$id` | `$help-skills` |
| Copilot | `~/.copilot/skills` or `<repo>/.github/skills` | `/id` (+ `/skills reload` after sync) | `/dotnet-developer` |
| OpenCode | `~/.config/opencode/skills` | `skill` tool | `skill({ name: "help-skills" })` |
| Antigravity | `~/.gemini/config/skills` | `use skill id` or `/id` | `use skill sdd-plan` |
| Grok | `~/.grok/skills` | `/id` | `/help-skills` |
| ZCode | `~/.zcode/skills` | `$id` | `$help-skills` |
| Hermes | `~/.hermes/skills` | `/id` | `/help-skills` |
| OpenHands | Project `.agents/skills` or `~/.agents/skills` | Agent Skills (product discovery; mention skill id) | `help-skills` |

## Parallel specialists (default)

After sync, the published router prefers **parallel specialist subagents** for planning, multi-facet execution, analysis, or non-trivial questions, keeping **this session as the parent**. **Thin trivial exception:** single-path Q&A or a one-file edit with no spread risk stays in-parent; if analysis spans multiple files, a one-file change might extend, or there is any doubt → spawn. Caps and fallback: [SPAWN.md](../SPAWN.md) and `core/skills/_shared/agents/SPAWN.md` (`*-developer` **≤ 2**, `orchestrate-*` **≤ 4**). Child prompts and agent receipts are **always en-US**; do not dump a full user-language PLAN — paths + excerpt (`LANGUAGE.md`).

- **`needs_*` → specialist:** O1 spawn map lives in `ROSTER.md` (`Flags (needs_*)`) — point there; do not paste the roster.
- **Task `model`:** omit by default (inherit parent); premium/alternate only with `SUBAGENT-MODEL.md` gate + user **sim**.
- **Orchestrate parents:** coordinate / receipts / synthesis — **must not** implement application code.

## Prerequisites

1. Synced at least one agent ([INSTALL.md](../INSTALL.md)).
2. Opened a **consumer** project in that agent.
3. Optional: ran `validate-agent.ps1` against a fixture or live InstallRoot.

## Cursor

Skills sync to `~/.cursor/skills/<id>/SKILL.md`.

| Action | Example |
|--------|---------|
| Slash menu | `/sdd-spec` |
| With args | `/sdd-plan - path/to/PRD.md` |
| Stack router | `/developer` |
| Catalog | `/help-skills` |
| Orchestrated Delivery Step 0 | `/memory-bank-init` |

Also: Customize → Skills (picker / auto). Rules land as `~/.cursor/rules/*.mdc`. Router: `~/.cursor/AGENTS.md`. If hooks were published, complete Cursor’s hooks trust UI once (outside CI).

## Claude Code

Skills sync to `~/.claude/skills/` (or project `.claude/`). Router file is `CLAUDE.md`. Rules stay `.md` under `rules/`.

Invoke with `/id` (e.g. `/sdd-spec`, `/help-skills`). Review `settings.json` merge and trust hooks in Claude’s UI if required.

Module notes: [adapters/claude/README.md](../../adapters/claude/README.md).

## GitHub Copilot

Requires sync with `-Mode user` or `-Mode repo`:

| Mode | Skills / instructions live under |
|------|----------------------------------|
| `user` | `~/.copilot/skills`, `instructions/`, `copilot-instructions.md` |
| `repo` | `<repo>/.github/skills`, … |

Invoke with `/id` (e.g. `/dotnet-developer`, `/help-skills`). After sync, run **`/skills reload`** so the CLI picks up new skills. JetBrains/Eclipse Copilot paths are out of scope.

## Codex

Codex is **dual-root** for packaging vs rules — do not treat skills and rules as one shared `TOOLKIT_ROOT`:

| Surface | Location |
|---------|----------|
| Plugin skills + CATALOG + OPERATOR (plugin packaging) | Under `InstallRoot/plugin` (bundled skills tree) |
| **`$` discovery** (InstallRoot skills mirror) | Live `~/.codex/skills` (after sync that mirrors for `$`) |
| Rules / guardrails (Publish-Policy) | `InstallRoot/rules/*.md` |
| Product / AGENTS / hooks parent | `InstallRoot` (live `~/.codex`) |
| Optional UserScope (opt-in) | Fixture: `InstallRoot/.agents/skills` · Live: `~/.agents/skills` (duplicates `$` if used with home skills) |

- **Plugin path alone does not feed `$`.** Plugin/marketplace packaging stays separate; `$id` discovery uses the InstallRoot `skills/` mirror (and UserScope `~/.agents/skills` when enabled).
- Invoke skills with **`$id`** (e.g. `$help-skills`, `$sdd-spec`). The native `$` or `/skills` picker is the product skills menu — **not** a `--menu` CLI flag.
- After sync, invoke **`help-skills`** for the installed catalog — do **not** load every `SKILL.md` to list skills. The same skill id works on **all** adapters.
- Trust plugin hooks with Codex `/hooks` **manually** after a real install — that is trust UI, not skill invoke. Smoke never requires it.

Details: [ADAPTERS.md](../ADAPTERS.md) § Codex · [adapters/codex/README.md](../../adapters/codex/README.md).

## OpenCode

Skills sync to `~/.config/opencode/skills`. Invoke via the **`skill` tool** (not slash-first):

```text
skill({ name: "help-skills" })
```

JS behavior extensions live under `plugins/` (not PS1 hooks). Module: [adapters/opencode/README.md](../../adapters/opencode/README.md).

## Grok

Expected live skills path: **`~/.grok/skills`**. Invoke with `/id` (e.g. `/help-skills`). Native `.grok` layout; hooks trust via `/hooks-trust` if needed (trust UI, not skill invoke).

Module: [adapters/grok/README.md](../../adapters/grok/README.md).

## ZCode

Skills sync to `~/.zcode/skills`. Invoke with **`$id`** (e.g. `$help-skills`). ADE filesystem — not GLM Coding Plan. After sync, refresh skills in Settings → Skills if the product requires it.

Module: [adapters/zcode/README.md](../../adapters/zcode/README.md).

## Hermes

Skills sync to **`~/.hermes/skills`** (directly under that home — not `~/.hermes/.hermes/skills`). Invoke with `/id` (e.g. `/help-skills`). Policy is folded into `AGENTS.md` (no `rules/` tree). `MEMORY.md` is seeded only if missing; `SOUL.md` is never written. Hooks / plugin / agents roster are not published. Subagents: host **`delegate_task`**.

Module: [adapters/hermes/README.md](../../adapters/hermes/README.md).

## OpenHands

**Project** sync writes Agent Skills to `<InstallRoot>/.agents/skills/` (not legacy microagents). **User** skills home: `~/.agents/skills` with `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome`. Invoke via product Agent Skills discovery (mention the skill id). Router + folded policy: `AGENTS.md`. Hooks: `.openhands/hooks.json` + `.openhands/hooks/*.sh` (shell, not `.ps1`). Plugin metadata: `.plugin/plugin.json` (skills still work without the plugin). Roster markdown under `.agents/agents/` is not native spawn (`subagents=none` — SPAWN fallback in-parent).

Module: [adapters/openhands/README.md](../../adapters/openhands/README.md).

## Antigravity

Skills sync to `~/.gemini/config/skills`. Invoke with **`use skill <id>`** or `/id` (e.g. `use skill sdd-plan`, `/help-skills`). Official `config/*` layout.

Module: [adapters/antigravity/README.md](../../adapters/antigravity/README.md).

## Common workflows

Flow examples below use **skill ids**. Prefix with your host form from the matrix (`/`, `$`, `use skill`, OpenCode `skill` tool, or OpenHands product discovery).

### Classic SDD *(formerly Forma A)*

```text
sdd-spec
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step N
```

One develop session = **one** PLAN step. Internal contracts (REQ, validate, CHANGE when brownfield, EVD/STATE, TRACE) run inside the same skill ids — no new slash skills.

### Orchestrated Delivery *(formerly Forma C)* — architecture confirm (greenfield / `needs_domain`)

```text
memory-bank-init
orchestrate-analyze
```

When analyze sets greenfield or `needs_domain` and no established ARCH style exists, it runs the **architect** specialist (roster prompt — not a skill id): ARCH **draft** → you answer **sim** → ARCH approved. Brownfield with an existing style is discover-first (mirror; no re-pick). Other O1 specialists follow `needs_*` in `ROSTER.md`. Parent stays coordinator (no app code); Task `model` omitted unless gated + **sim** ([SPAWN.md](../SPAWN.md)).

Later `orchestrate-develop` or `sdd-develop` (and stack `*-developer` skills) load **one** architecture style file plus the matching stack overlay — never the whole `architecture/**` tree.

### Small stack change

```text
developer
```

or `dotnet-developer`, `react-developer`, `python-developer`, …

### After implementation

```text
code-review
commit
push
open-github-pr   # optional, when opening a PR
```

Feature PRs: current `feature/*` (or `feat/*`) → `develop`. Release mode: `develop` → `master`/`main`. Prefer `open-github-pr` when `gh` is available. Deep dive: [domains/git-ops.md](../domains/git-ops.md).

## Catalog and decision tree

- Installed map (agents): `help-skills` → `_shared/skills-catalog/CATALOG.md` + `OPERATOR.md` (**38** skills; all adapters)
- Human mirror: [SKILLS.md](../SKILLS.md)
- Caveman: [07-caveman-mode.md](07-caveman-mode.md)
- Credits: [CREDITS.md](../CREDITS.md)
- Which work track: [guides/README.md](README.md)
- First-time path: [01-getting-started.md](01-getting-started.md)

## Re-sync when skills feel stale

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Managed files are overwritten; alien files in the agent home are preserved.
