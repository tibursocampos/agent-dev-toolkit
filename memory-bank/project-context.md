# Project context

| Field | Value |
|-------|--------|
| **Repo** | agent-dev-toolkit |
| **Inventory at** | 2026-09-24T20:52:26Z (refresh) |
| **Primary stack signals** | PowerShell, Markdown Agent Skills (41 kebab) |

## Purpose

Toolkit unificado: um **core** portável de skills/rules/router (catálogo; tracks **Classic SDD** / **Backlog Refine** / **Orchestrated Delivery**, alias só nesta release) e **adapters** que publicam esse core nos perfis de agentes (Cursor, Antigravity, Claude Code, Codex, Copilot, OpenCode, Grok Build, ZCode, Hermes, OpenHands). Twins `cursor-dev-toolkit` e `antigravity-dev-toolkit` permanecem intactos.

**Frase-guia SDD:** mesmo fluxo de chamada das skills; gates e artefatos a mais (REQ, validate, CHANGE, EVD, STATE, TRACE, retrieval seletivo) — sem segundo toolkit nem pastas `openspec/` / `.specs/` / `.specify/`. SQLite/FTS fora do escopo atual (OOS).

## Actors / users

- Operador que roda `scripts/toolkit.ps1` (clone / Smart Manager) ou `scripts/bootstrap/*` (Release HTTPS + SHA256 → sync)
- Operador opt-in de authorship git-notes via `Invoke-AuthorshipGitNotes.ps1` (default off)
- Agentes de coding que consomem skills/rules/hooks após o publish (`help-skills` → CATALOG **41**)

## Boundaries

- In scope: core kebab + registry adapters + smoke **in-repo** (fixtures, sem exigir install no perfil do usuário para CI); Release bootstrap entrypoints; opt-in authorship notes parallel to TRACE
- Out of scope: produtos que não estão em `adapters/registry.json`; git-notes como SoT de TRACE; skill ids com major pin (`dotnet10-upgrade`, etc.)

## Links

- README: `README.md`
- Public docs: `docs/` (index `docs/README.md`; spawn summary `docs/SPAWN.md`)

## Notes

Keep this file short. Details belong in `architecture.md` / `domain-knowledge.md`.
**No secrets** - env var names only.
