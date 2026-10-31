---
name: blip-plugin-developer
description: Scaffold a new Blip React plugin (create-blip-extension), config:plugin, and SDD handoff to react-developer. Use for new Blip plugins or when invoking /blip-plugin-developer.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: blip-plugin-developer

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

- User asks for `/blip-plugin-developer`, `blip plugin`, or a **new** Blip React extension
- User wants scaffold + documentation setup before implementation

For **existing** Blip plugin repos ( `blip-ds` in `package.json` ), use `/react-developer` instead.

## Outcome

A correctly scaffolded Blip plugin repo with `config:plugin` applied, profile documented, SDD path chosen, and clear handoff to implementation skills.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Integration overview | `docs/blip-plugin-integration.md` (in target or toolkit repo) |
| Architecture | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/plugin-architecture.md` |
| Structure / quality (when coding) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| Design system | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/design-system.md` |
| Iframe messages | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/blip-iframe-messages.md` |
| Auth (Full profile) | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/auth-and-permissions.md` |
| External API | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/external-api-integration.md` |
| Deploy / CI | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/deploy-and-ci.md` |
| React guidelines | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/` — only files needed for scaffold UI |
| Frontend practices | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Design guidance | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Branch / commit | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/blip-plugin-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/blip-plugin-developer/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`. do not preload the full `blip-guidelines/` pack or all `react-guidelines/`. Load architecture + design-system for scaffold; fan-out to auth/iframe/API/deploy only when that profile step runs. Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

**Progressive load:** integration overview / architecture first; then the Blip row for the active scaffold step.

## Reference routing

| Situation | Path |
|-----------|------|
| Working rule | `references/working-rule.md` |
| Scaffold | `references/scaffold.md` |
| Documentation flow | `references/documentation-flow.md` |
| Implementation handoff | `references/handoff-impl.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### 0. Working rule
Follow `references/working-rule.md`.

### 1. Scaffold
Follow `references/scaffold.md`.

### 2. Documentation flow
Follow `references/documentation-flow.md`.

### 3. Handoff
Follow `references/handoff-impl.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no unofficial scaffold defaults; no guideline dumps; no mixing backend into plugin scaffold session.

## Handoff

| Situation | Next |
|-----------|------|
| Implement UI/features | `/react-developer` |
| Design new screens | Create a project-specific `docs/DESIGN-BRIEF.md` with `target_stack: react` and Blip/BDS notes in section 9; use the shared frontend design guidance. |
| Backend API | `/dotnet-developer` (separate repo) |
| Full SDD feature | `/sdd-spec` |
| Commit (after implementation) | `/commit` |
