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

| Id | Observable result | Condition | Failure |
|----|-------------------|-----------|---------|
| AC-01 | {{OBSERVABLE_RESULT}} | {{CONDITION}} | {{FAILURE}} |

Each row needs an observable result, the condition under which it holds, and the failure when it does not. Do not leave a criterion that cannot be checked. Do not put a file checklist here.

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

| question_id | decision_id | Decision | Status |
|-------------|-------------|----------|--------|
| {{Q-001}} | {{D-001}} | {{DECISION_PROSE}} | resolved |

One row per closed question. `question_id` and `decision_id` stay stable. Do not delete a prior decision when the file is updated; append history. Status token: `resolved` only for an explicit user answer or a cited portable evidence path.

## Open questions

| Id | Severity | Impact | Owner | Question |
|----|----------|--------|-------|----------|
| Q-001 | B \| I \| MINOR | {{IMPACT}} | Product \| Engineering \| UX | {{QUESTION}} |

Severity tokens: `B`, `I`, `MINOR` (`readiness-severity.md` § Open-question gate). Owner: `Product`, `Engineering`, or `UX`. Any non-empty unanswered row blocks story folders (`open_question`). Silence does not close a row. "I do not know" leaves the row open.

## Histórias

| Id | Tipo | Título | Rationale | Product intent | Status |
|----|------|--------|-----------|----------------|--------|
| US01 | US | {{STORY_TITLE}} | {{WHY_THIS_STORY}} | {{WHO_JOB_OUTCOME_OR_N_A}} | draft |

`Product intent` = Who / Job / Outcome (or `n/a` for pure TS/Bug). See `skills/_shared/backlog-item-types/persona-context.md`. `Rationale` = why this story is separate (sizing / anti-task-shatter). Cap ≤4 US/TS unless rationale is explicit (`feature-altitude.md`).

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
