# CHANGE: {{NNN}}-{{slug}}

| Field | Value |
|-------|--------|
| **Feature** | `features/{{NNN}}-{{slug}}/` |
| **Nature** | brownfield |
| **Vs current** | Living domain specs under `memory-bank/` (e.g. `domain-knowledge.md`, `architecture.md`, `api-contracts.md`, `conventions.md`) — **not** `openspec/`, `.specs/`, or `.specify/` |
| **PRD** | `./USnn/PRD/NNN_*.md` (portable path) |
| **Status** | draft \| ready-for-plan |

## Purpose

Brownfield delta vs **current** product/domain knowledge. Written at O2 / `sdd-spec` close. Greenfield features **must not** invent an empty CHANGE stub.

## ADDED

- [ ] [What is new vs current — path or capability; cite current baseline path when useful]

## MODIFIED

- [ ] [What changes vs current — before → after; cite current baseline path]

## REMOVED

- [ ] [What is retired vs current — cite current baseline path]
- [ ] *(Use `None` if nothing is removed.)*

## Current baselines (selective)

List only the **named** current files this delta touches (no full memory-bank dump):

| Portable path | Role in this CHANGE |
|---------------|---------------------|
| `memory-bank/domain-knowledge.md` | [why cited] |

## TASKS policy

| FEATURE **Complexity** | TASKS |
|------------------------|-------|
| `trivial` (small) | **Do not** require `TASKS.md` / `REFINE/tasks.md` |
| `medium` or `complex` | **Require** a task checklist (`USnn/REFINE/tasks.md` default, or `USnn/TASKS.md` if explicitly requested) |

## Cross-artifact notes (O2)

- FEATURE `Nature` = brownfield ↔ this file required at `features/NNN-slug/CHANGE.md`
- PRD REQ/CA should align with ADDED \| MODIFIED \| REMOVED themes
- After Write: run `validate-change.ps1` before plan/develop handoff
