---
name: help-skills
description: Present the installed static skills catalog (CATALOG.md + OPERATOR.md) without loading every SKILL.md. Use when listing skills or invoking help-skills (host: /help-skills, $help-skills, use skill help-skills, or OpenCode skill tool).
---

# Skill: help-skills

## Trigger

Invoke when the user asks for skill **`help-skills`** (host forms: `/help-skills`, `$help-skills`, `use skill help-skills`, OpenCode `skill({ name: "help-skills" })`), or phrases: `list skills`, `skill catalog`, `which skills`, `mapa de skills`, or operator expectations / confirmations for a skill.

## Outcome

User sees the **static** skill map and operator notes from the installed catalog files — **without** loading every `SKILL.md` and **without** re-analyzing or paraphrasing the catalog into a new essay.

## Paths (required)

| File | Path |
|------|------|
| Skills map | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` |
| Operator notes | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/OPERATOR.md` |
| Relative fallback | `_shared/skills-catalog/CATALOG.md` and `OPERATOR.md` (same skills tree) |

## Process

### Caveman Mode
**NEVER** — This skill ignores `caveman_mode`. Present the catalog in clear prose (pt-BR for the user). Do not load `CAVEMAN.md` for chat compression.

### 0. No mutating gates

This skill is **read-only**. Do **not** require guardrails/SESSION/`sim` to show the catalog. Do not invent skill names.

### 1. Read static files (required)

1. **Read** `CATALOG.md` (path table above).
2. **Read** `OPERATOR.md` when the user asks about confirmations, options, quirks, Caveman, or “what will I be asked?” — or when presenting a full help response that should include operator expectations. For a bare “list skills”, CATALOG alone is enough; still mention that `OPERATOR.md` exists for nuances.
3. If either required file for the answer is missing, **STOP** and tell the user (pt-BR) the catalog is not installed — suggest re-running agent sync. Do **not** invent a skill list from memory.

### 2. Present (do not rewrite)

- Show groupings, skill ids, invoke phrases, and short purposes **from the file text**.
- Prefer tables or short grouped lists already in the static files.
- Point the user to invoke a specific skill next by **id** (host prefix from OPERATOR invoke matrix); do not load that skill body unless they ask to run it.
- Do **not** summarize by inventing new wording that replaces the static guide.

## Must not

- Invent skills that are not in `CATALOG.md`
- Load every `SKILL.md` to answer a catalog or operator-notes question
- Require `sim` / SESSION gates for read-only catalog presentation
- Write application code, commit, push, or open PRs
- Treat `_shared/` packs or architect spawn as invocable skills
