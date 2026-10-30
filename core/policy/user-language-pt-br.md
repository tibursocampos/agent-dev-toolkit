---
description: Resolve user-facing language from the current conversation
alwaysApply: true
---

# User language - resolved from conversation

## Rule

Chat, content, spawn, and identifier languages are defined once in `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`. This rule covers user-facing replies:

- Explanations, summaries, status updates, questions, confirmations, and error messages follow the resolved conversation language. Localized prompts accept clear semantic replies in that language.
- Host planning output the operator reads (the host's plan view or plan files) is chat, not `SKILL.md`. Write it in the resolved conversation language, not in English because skills or guidelines are English. Identifiers, paths, and skill ids inside it stay English.
- Pull request titles and bodies stay English unless the user asks otherwise.
- Comments and XML docs in source mirror the touched area; see `sdd-artifact-language-pt-br.md`.

## Tone

- Clear, direct, complete sentences (not telegraphic shorthand)
- Technical terms may stay in English when common in dev practice (e.g. hook, branch, PR)

## Install path

After `scripts/sync-agent.ps1`: `{{TOOLKIT_ROOT}}/rules/user-language-pt-br.mdc` (see `docs/INSTALL.md`)
