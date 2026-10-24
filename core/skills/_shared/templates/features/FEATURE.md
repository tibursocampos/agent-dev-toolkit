# FEATURE: {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | `{{NNN}}-{{slug}}` |
| **Path** | `features/{{NNN}}-{{slug}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/` (global; portable path — see `STORAGE.md` § Portable path) |
| **Scope** | backend \| frontend \| fullstack |
| **Nature** | greenfield \| brownfield \| operational |
| **Complexity** | trivial \| medium \| complex |
| **Status** | draft \| approved \| in-progress \| done |

## Problem

{{PROBLEM}}

Mandatory for synthesis gates (ARCH / REQ-002). Describe the user or business pain — not a file checklist.

## Goals

- {{GOAL_1}}
- {{GOAL_2}}

Observable outcomes for the initiative. Empty Goals fail FEATURE quality gates.

## Non-goals

- {{NON_GOAL_1}}
- {{NON_GOAL_2}}

Explicit out-of-altitude items (what this FEATURE will **not** solve). Empty Non-goals fail FEATURE quality gates.

## Macro acceptance criteria

Filled prose in this file follows the chat language (`LANGUAGE.md`). Ids and severity tokens stay English.

| Id | Observable result | Condition | Failure | Disposição / destino |
|----|-------------------|-----------|---------|-----------------------|
| AC-01 | {{OBSERVABLE_RESULT}} | {{CONDITION}} | {{FAILURE}} | {{STORY_IDS_OR_EXISTING_DECISION_OR_QUESTION}} |

Each row needs an observable result, the condition under which it holds, and the failure when it does not. Do not leave a criterion that cannot be checked. Do not put a file checklist here.

For each material behavior, use the last column to reference the promoted story ID(s), an unchanged preservation, an explicitly approved exclusion by existing `decision_id`, or an unresolved existing `question_id`. Record the decision only in **Decisions** and the question only in **Open questions**; do not create a second decision list. Compare the current decision with the actual normative text it governs. A link or ID alone does not prove agreement, and a superseded row remains historical. State why a disposition is not applicable when that is the case.

## Evidence

| Campo | Valor |
|-------|--------|
| **Evidence** | {{EVIDENCE_PATH_OR_REDACTED_OR_OMITTED}} |

**Rule: omit > fabricate.** Prefer portable paths or redacted snippets. If no real signal exists, use `omitted — none yet` — never invent quotes, metrics, or PII. See `skills/_shared/backlog-item-types/product-evidence-lite.md`. Scorecard must not force inventing Evidence.

## Resumo

{{SUMMARY}}

Short narrative after Problem/Goals (not a substitute for those fields).

## Métricas leves (opcional)

| Métrica | Baseline | Alvo | Notas |
|---------|----------|------|-------|
| {{METRIC}} | {{BASELINE_OR_OMITTED}} | {{TARGET_OR_OMITTED}} | {{NOTE}} |

Omit the table when unknown — do not fabricate numbers (`product-evidence-lite.md`).

## Decisions

| question_id | decision_id | Decision | Affected normative artifact/section (REQ/CA) | Status | Superseded by |
|-------------|-------------|----------|---------------------------------------------|--------|--------------|
| {{Q-001}} | {{D-001}} | {{DECISION_PROSE}} | {{PORTABLE_PATH_AND_SECTION; REQ-### / CA# WHEN APPLICABLE}} | resolved | — |

One row per closed question. `question_id` and `decision_id` stay stable. Link each decision to the portable path and section it changes or governs, including applicable `REQ-###` and `CA#` ids; use `n/a` only when no normative artifact or section is affected yet. Status is `resolved` only for an explicit user answer or a cited portable evidence path, or `superseded` when a later decision replaces it. Keep superseded rows and their original targets; record the replacing `decision_id` in **Superseded by**. Append history instead of deleting or rewriting prior decisions. When carrying a decision into a material behavior, inspect the current normative destination; a valid link does not establish that its text agrees, and an older decision does not become current by recency.

## Open questions

| Id | Severity | Impact | Owner | Question |
|----|----------|--------|-------|----------|
| Q-001 | B \| I \| MINOR | {{IMPACT}} | Product \| Engineering \| UX | {{QUESTION}} |

Severity tokens: `B`, `I`, `MINOR` (`readiness-severity.md` § Open-question gate). Owner: `Product`, `Engineering`, or `UX`. Any non-empty unanswered row blocks story folders (`open_question`). Silence does not close a row. "I do not know" leaves the row open.

## Histórias

| Id | Tipo | Título | Rationale | Product intent | Macro AC / decision ids | Status |
|----|------|--------|-----------|----------------|------------------------|--------|
| US01 | US | {{STORY_TITLE}} | {{WHY_THIS_STORY}} | {{WHO_JOB_OUTCOME_OR_N_A}} | {{FEATURE_AC_AND_CURRENT_DECISION_IDS}} | draft |

`Product intent` = Who / Job / Outcome (or `n/a` for pure TS/Bug). See `skills/_shared/backlog-item-types/persona-context.md`. `Rationale` = why this story is separate (sizing / anti-task-shatter). Cap ≤4 US/TS unless rationale is explicit (`feature-altitude.md`).

List the existing macro-acceptance and applicable current decision ids carried by each story. The acceptance text in STORY must preserve the behavior those ids identify; the ids are a navigation aid, not proof of semantic agreement. Do not add story rows for an unresolved question or an unapproved exclusion.

The table may stay empty until the open-question gate passes. Do not add story rows while an open question remains on this FEATURE.

## Flags (`needs_*`)

| Flag | Valor |
|------|-------|
| needs_api | false |
| needs_domain | false |
| needs_database | false |
| needs_frontend | false |
| needs_security | false |
| needs_devops | false |

## Related

| Relação | Path portátil |
|---------|---------------|
| CONTINUITY | `features/{{NNN}}-{{slug}}/CONTINUITY.md` (omit if absent) |
| CHANGE | `features/{{NNN}}-{{slug}}/CHANGE.md` — required when **Nature** = `brownfield`; greenfield must not force an empty stub (`CHANGE-CONTRACT.md`) |
| STORY | `features/{{NNN}}-{{slug}}/US01/STORY.md` (ajustar ids; omit if absent) |
| PRD / PLAN | story `PRD/` / `PLAN/` when on-disk (omit if absent) |

Title **must** be `## Related` (`STORAGE.md` § Navigation block; RN05). Portable paths only. Omit-if-absent — do not stub siblings only for links.

Norms: `skills/_shared/backlog-item-types/feature-altitude.md`, `product-evidence-lite.md`.
