# Using skills

How to invoke toolkit skills after a successful sync. Slash syntax below is the **Cursor** convention; other agents may use a skill picker, `@`-mention, or “use skill …” phrasing — the skill **folder names** stay the same kebab-case ids from `core/skills/`.

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

Default publish is **plugin-bundled** skills under the fixture/plugin tree. Trust plugin hooks with Codex `/hooks` **manually** after a real install — smoke never requires it. See [ADAPTERS.md](../ADAPTERS.md) § Codex.

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
```

## Re-sync when skills feel stale

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

Managed files are overwritten; alien files in the agent home are preserved.

## Catalog and decision tree

- Full list: [SKILLS.md](../SKILLS.md)
- Which Forma: [guides/README.md](README.md)
- First-time path: [01-getting-started.md](01-getting-started.md)
