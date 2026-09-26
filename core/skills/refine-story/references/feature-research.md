# Feature research cycle

Load when `invocation_context=orchestrated` and refine mode is `feature`. Direct invocation uses the mode playbook in `feature.md` and does not start this cycle unless the parent already set the mode.

Skill prose in this file is English. Questions shown to the user, and prose written into `FEATURE.md`, follow the chat language (`LANGUAGE.md`). Tokens stay English.

Do not create a separate clarification artifact. Section updates land on `FEATURE.md` (macro acceptance, decisions, open questions). When a story folder already exists, decision history for that story stays in `references/qa-history.md`.

Companion: `finding-format.md`, `readiness-severity.md` § Open-question gate, `spawn-map.md`, `persona-context.md`.

## Fixed order

1. Read `FEATURE.md`. Read `memory-bank/` only when that bank exists. Do not dump the bank (`SELECTIVE-RETRIEVAL.md`).
2. Call specialists only as `orchestrate-analyze/references/spawn-map.md` maps `needs_*`. Do not invent extra roles. Take specialist returns in the parent. Do not create story folders in this cycle.
3. First findings pass. Record each finding with `finding-format.md`.
4. Second pass, isolated from the first. When a Task tool is available, the two passes do not see each other's notes until both finish. When Task is unavailable, finish pass one, then run pass two in the same context and say that the passes were not isolated.
5. Close a finding only when it has a portable evidence path or an explicit user answer. `no-evidence` stays open.
6. Ask every remaining open question in one batch. Include `MINOR`. Do not ask only `B` and `I`.
7. Stop when no open question remains, or after two critique rounds, whichever comes first. If any question is still unanswered when the round ceiling is hit, stop with `open_question`. That is not a clean finish.

A critique round is one pair of isolated passes plus the single question batch that follows. Do not invent a finding to force another round. Two rounds is the ceiling.

## Inspection list

Check the FEATURE for:

- Actor
- Goal
- Scope
- Precondition
- Main flow
- Error flow
- Permission
- Data owner
- Integration
- Acceptance criterion with an observable condition and a failure
- Undefined term
- Empty behavior

Severity, impact, and owner (`Product`, `Engineering`, `UX`) follow `finding-format.md` and the Open questions table on `FEATURE.md`.

## What to ask

Ask product decisions the FEATURE does not already answer.

Do not ask for a class path, file path, or route when that is a technical follow-up the repository can answer. Record that follow-up for the specialist or later spec. It does not close a functional question, and it does not replace one.

## Persona pass

The persona pass applies only to a User Story or a Bug. Load `persona-context.md` only. Use role and job. Do not invent a person's name. Do not run the persona pass for a Technical Story.

## History

Research before asking. One batch of questions per round. Repeat until no open question remains, or the two-round ceiling is hit. A ceiling hit with an unanswered question is `open_question`, not approval to create story folders.

Updating `FEATURE.md` preserves decisions already recorded (`question_id`, `decision_id`). Do not delete a prior decision to make the file shorter. A later story's Q&A history, once that story exists, stays in `qa-history.md`.
