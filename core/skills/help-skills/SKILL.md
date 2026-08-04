---
name: help-skills
description: Present the installed skills catalog (map + slash/compat phrases) without loading every SKILL.md. Use when listing skills or invoking /help-skills.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-opcodes/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: help-skills

## Trigger

Invoke when the user asks for: `/help-skills`, `list skills`, `skill catalog`, `which skills`, or `mapa de skills`.

## Outcome

User sees the **skill map** (groupings, slash forms, short purpose) from the installed catalog — **without** loading every `SKILL.md`.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Skills catalog (required) | `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` |
| Relative fallback (same install tree) | `_shared/skills-catalog/CATALOG.md` |

## Process

### Caveman Mode
**NEVER** - This skill ignores `caveman_mode`. Present the catalog in clear prose (pt-BR for the user). Do not load `CAVEMAN.md` for chat compression.

### 0. Confirm gates

If gates are missing, ask (pt-BR) before continuing. This skill is read-only for the catalog; do not invent skill names.

### 1. Read catalog (required)

1. **Read** `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` (or `_shared/skills-catalog/CATALOG.md` when the skill is already under the skills root).
2. If the file is missing, **STOP** and tell the user (pt-BR) that the catalog is not installed — suggest re-running agent sync. Do **not** invent a skill list from memory.

### 2. Present to user (pt-BR)

Summarize the catalog for the user:

- Total count and how to invoke (`/<name>`; compat: `use skill <name>` when the host supports it)
- Formas A / B / C with entry skills
- Stack router (`developer`) and notable ops (`commit`, `push`, `open-github-pr`, …)
- Point users to invoke a specific skill next; do not load that skill body unless they ask

Keep the reply lean: tables or short grouped lists are fine; do not paste full skill bodies.

## Must not

- Invent skills that are not in `CATALOG.md`
- Load every `SKILL.md` to answer a catalog question
- Write application code, commit, push, or open PRs
- Treat `_shared/` packs or architect spawn as slash skills
