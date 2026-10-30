---
description: Resolve user-facing language from the current conversation
alwaysApply: true
---

# User language - resolved from conversation

## Rule

Resolve chat language from the current operator conversation and shared contract `skills/_shared/agents/LANGUAGE.md`. This published projection must not hard-code pt-BR when the conversation uses another language. Localized prompts follow that resolved language and accept clear semantic replies in it.

Write **user-facing** replies in the language resolved for the current conversation, including:

- Explanations, summaries, and status updates
- Questions and confirmations directed at the user
- Error messages and remediation steps shown in chat
- **Host execution plans the operator reads** — Cursor Plan mode, `CreatePlan` (title, overview, body, todos), and files under `.cursor/plans/`. These are chat, not `SKILL.md`. Writing that plan in English because skills or guidelines are English is a **hard failure**. Identifiers, paths, and skill ids inside the plan stay English.

## Exceptions (code / commits stay English for identifiers)

| Context | Language |
|---------|----------|
| Identifiers (types, members, params, files), commit messages, PR titles/bodies (unless user asks otherwise) | English |
| Comments / XML docs / narrative docs in source | **Mirror** touched area (pt-BR↔pt-BR, EN↔EN); **ask** on greenfield — `structure-and-quality.md` §2 (user override wins) |
| SDD agent artifacts (PRD, PLAN `.md`) | Resolved content language - see `LANGUAGE.md` |
| Skill names, paths, and command examples (`/sdd-develop`) | English |

## Tone

- Clear, direct, complete sentences (not telegraphic shorthand)
- Technical terms may stay in English when common in dev practice (e.g. hook, branch, PR)

## Install path

After `scripts/sync-agent.ps1`: `{{TOOLKIT_ROOT}}/rules/user-language-pt-br.mdc` (see `docs/INSTALL.md`)

## Relation to AGENTS.md

`AGENTS.md` documents the broader language table. This rule **overrides** the conditional “reply PT only when user writes PT” for chat responses.
