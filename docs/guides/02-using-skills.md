# Using skills

How to invoke toolkit skills after a successful sync. Prefer **skill ids** (kebab-case under `core/skills/`). Host UX varies: slash `/` when supported, skill picker, `@`-mention, or “use skill …”.

After any agent sync, invoke **`help-skills`** for the installed static catalog (`CATALOG.md` + `OPERATOR.md`).

## Parallel specialists (default)

After sync, the published router prefers **parallel specialist subagents** for planning, multi-facet execution, analysis, or non-trivial questions, keeping **this session as the parent**. Trivial / single-path work stays in-parent. Caps and fallback: [SPAWN.md](../SPAWN.md) and `core/skills/_shared/agents/SPAWN.md`.

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
| Forma C Step 0 | `/memory-bank-init` |

Rules land as `~/.cursor/rules/*.mdc`. Router: `~/.cursor/AGENTS.md`. If hooks were published, complete Cursor’s hooks trust UI once (outside CI).

## Claude Code

Skills sync to `~/.claude/skills/` (or project `.claude/`). Router file is `CLAUDE.md`. Rules stay `.md` under `rules/`.

Invoke skills via Claude’s skill / slash UX for custom skills (names match kebab ids, e.g. `sdd-spec`). Review `settings.json` merge and trust hooks in Claude’s UI if required.

Module notes: [adapters/claude/README.md](../../adapters/claude/README.md).

## GitHub Copilot

Requires sync with `-Mode user` or `-Mode repo`:

| Mode | Skills / instructions live under |
|------|----------------------------------|
| `user` | `~/.copilot/skills`, `instructions/`, `copilot-instructions.md` |
| `repo` | `<repo>/.github/skills`, … |

Use Copilot’s agent-skills / custom-instructions surfaces ([GitHub docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)). JetBrains/Eclipse Copilot paths are out of scope.

## Codex

Codex is **dual-root** — do not treat skills and rules as one shared `TOOLKIT_ROOT`:

| Surface | Location |
|---------|----------|
| Plugin skills + CATALOG + OPERATOR (`TOOLKIT_ROOT` for skills) | Under `InstallRoot/plugin` (bundled skills tree) |
| Rules / guardrails (Publish-Policy) | `InstallRoot/rules/*.md` |
| Product / AGENTS / hooks parent | `InstallRoot` (live `~/.codex`) |
| Optional USER skills mirror | Fixture: `InstallRoot/.agents/skills` · Live: `~/.agents/skills` with `-UserScope` + `-AllowUserHome` |

- **Default sync** is **plugin-only** (skills under `plugin/skills/`). Optional `-UserScope` mirrors skills for USER discovery; CI/fixtures use `InstallRoot/.agents/skills` and never require a live `~/.agents/skills` write.
- **Publish-Router** materializes `AGENTS.md` with **absolute** dual-root paths (no `{{…}}` placeholders; no live `docs/` links). Do not resolve skill `_shared` under `InstallRoot/rules`.
- After sync, invoke **`help-skills`** for the installed catalog (`plugin/skills/_shared/skills-catalog/CATALOG.md` + `OPERATOR.md`) — do **not** load every `SKILL.md` to list skills. The same skill id works on **all** adapters, not only Codex.
- Trust plugin hooks with Codex `/hooks` **manually** after a real install — smoke never requires it.

Details: [ADAPTERS.md](../ADAPTERS.md) § Codex · [adapters/codex/README.md](../../adapters/codex/README.md).

## OpenCode / Grok / ZCode / Antigravity

| Agent | Skills location (typical) | Invoke tip |
|-------|---------------------------|------------|
| OpenCode | `~/.config/opencode/skills` | JS plugins under `plugins/` (not PS1 hooks) |
| Grok | `~/.grok/skills` | Native `.grok`; trust via `/hooks-trust` if needed |
| ZCode | `~/.zcode/skills` | ADE filesystem; not GLM Coding Plan |
| Antigravity | `~/.gemini/config/skills` | Official `config/*` layout |

## Common workflows

### Forma A

```text
/sdd-spec
/sdd-plan - <prd-path>
/sdd-develop - <plan-path> - Step N
```

One develop session = **one** PLAN step.

### Forma C — architecture confirm (greenfield / `needs_domain`)

```text
/memory-bank-init
/orchestrate-analyze
```

When analyze sets greenfield or `needs_domain` and no established ARCH style exists, it runs the **architect** specialist (roster prompt — not a slash skill): ARCH **draft** → you answer **sim** → ARCH approved. Brownfield with an existing style is discover-first (mirror; no re-pick).

Later `/orchestrate-develop` or `/sdd-develop` (and stack `*-developer` skills) load **one** architecture style file plus the matching stack overlay — never the whole `architecture/**` tree.

### Small stack change

```text
/developer
```

or `/dotnet-developer`, `/react-developer`, `/python-developer`, …

### After implementation

```text
/code-review
/commit
/push
/open-github-pr   # optional, when opening a PR
```

Feature PRs: current `feature/*` (or `feat/*`) → `develop`. Release mode: `develop` → `master`/`main`. Prefer `/open-github-pr` when `gh` is available. Deep dive: [domains/git-ops.md](../domains/git-ops.md).

## Catalog and decision tree

- Installed map (agents): `help-skills` → `_shared/skills-catalog/CATALOG.md` + `OPERATOR.md` (**38** skills; all adapters)
- Human mirror: [SKILLS.md](../SKILLS.md)
- Caveman: [07-caveman-mode.md](07-caveman-mode.md)
- Credits: [CREDITS.md](../CREDITS.md)
- Which Forma: [guides/README.md](README.md)
- First-time path: [01-getting-started.md](01-getting-started.md)

## Re-sync when skills feel stale

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Managed files are overwritten; alien files in the agent home are preserved.
