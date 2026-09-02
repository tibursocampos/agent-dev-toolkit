---
name: help-skills
description: Present the installed static skills catalog (CATALOG.md + OPERATOR.md) without loading every SKILL.md. Use when listing skills or invoking help-skills (host: /help-skills, $help-skills, use skill help-skills, or OpenCode skill tool).
---


# Skill: help-skills

## Trigger

Invoke when the user asks for skill **`help-skills`** (host forms: `/help-skills`, `$help-skills`, `use skill help-skills`, OpenCode `skill({ name: "help-skills" })`), or phrases: `list skills`, `skill catalog`, `which skills`, `mapa de skills`, or operator expectations / confirmations for a skill.

## Outcome

User sees the **static** skill map and operator notes from the installed catalog files — **without** loading every `SKILL.md` and **without** re-analyzing or paraphrasing the catalog into a new essay.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Skills map (always for this skill) | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` |
| Operator notes / confirmations | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/OPERATOR.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/help-skills/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/help-skills/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, individual skill `SKILL.md` bodies, or guideline packs when answering catalog or operator questions. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Present catalog | `references/present-catalog.md` |
| Must not (full) | `references/must-not.md` |

## Paths (required)

| File | Path |
|------|------|
| Skills map | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` |
| Operator notes | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/OPERATOR.md` |
| Relative fallback | `_shared/skills-catalog/CATALOG.md` and `OPERATOR.md` (same skills tree) |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Present catalog
Follow `references/present-catalog.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: catalog-only; no inventing skills; no loading every `SKILL.md`.
