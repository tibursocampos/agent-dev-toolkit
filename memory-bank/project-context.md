# Project context

| Field | Value |
|-------|--------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-07-31T23:38:19Z (refresh) |
| **Primary stack signals** | PowerShell, Markdown Agent Skills |

## Purpose

Toolkit unificado: um **core** portável de skills/rules/router (catálogo; tracks **Classic SDD** / **Backlog Refine** / **Orchestrated Delivery**, alias *(formerly Forma A|B|C)* só nesta release) e **adapters** que publicam esse core nos perfis de agentes (Cursor, Antigravity, Claude Code, Codex, Copilot, OpenCode, Grok Build, ZCode, Hermes, OpenHands). Twins `cursor-dev-toolkit` e `antigravity-dev-toolkit` permanecem intactos.

**Frase-guia SDD:** mesmo fluxo de chamada das skills; gates e artefatos a mais (REQ, validate, CHANGE, EVD, STATE, TRACE, retrieval seletivo) — sem segundo toolkit nem pastas `openspec/` / `.specs/` / `.specify/`. SQLite/FTS fora do escopo atual (OOS).

## Actors / users

- Operador que roda `scripts/toolkit.ps1` para sync/validate/uninstall por agent
- Agentes de coding que consomem skills/rules/hooks após o publish

## Boundaries

- In scope: core kebab + registry adapters + smoke **in-repo** (fixtures, sem exigir install no perfil do usuário para CI)
- Out of scope: produtos que não estão em `adapters/registry.json`

## Links

- README: `README.md`
- Public docs: `docs/` (index `docs/README.md`; spawn summary `docs/SPAWN.md`)

## Notes

Keep this file short. Details belong in `architecture.md` / `domain-knowledge.md`.
**No secrets** - env var names only.
