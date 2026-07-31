# Project context

| Field | Value |
|-------|--------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-07-31T23:38:19Z (refresh) |
| **Primary stack signals** | PowerShell, Markdown Agent Skills |

## Purpose

Toolkit unificado: um **core** portável de skills/rules/router (catálogo Cursor/Antigravity, Formas A/B/C) e **adapters** que publicam esse core nos perfis de agentes (Cursor, Antigravity, Claude Code, Codex, Copilot, OpenCode, Grok Build, ZCode). Twins `cursor-dev-toolkit` e `antigravity-dev-toolkit` permanecem intactos.

## Actors / users

- Operador que roda `scripts/toolkit.ps1` para sync/validate/uninstall por agent
- Agentes de coding que consomem skills/rules/hooks após o publish

## Boundaries

- In scope: core kebab + adapters Tier 1 + smoke **in-repo** (fixtures, sem exigir install no perfil do usuário para CI)
- Out of scope (MVP): Tier 2 (Windsurf, Cline, Roo, Gemini CLI, Warp); Tier 3 thin/out; catálogos Athena/Supply

## Links

- README: `README.md`
- Public docs: `docs/` (index `docs/README.md`; spawn summary `docs/SPAWN.md`)

## Notes

Keep this file short. Details belong in `architecture.md` / `domain-knowledge.md`.
**No secrets** - env var names only.
