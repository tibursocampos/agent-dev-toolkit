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

## Perguntas em aberto (leves)

| Pergunta | Severity |
|----------|----------|
| {{OPEN_QUESTION}} | blocker \| high \| medium \| low |

Few sharp questions only (`clarify-depth.md`). Omit section when none.

## Histórias

| Id | Tipo | Título | Rationale | Product intent | Status |
|----|------|--------|-----------|----------------|--------|
| US01 | US | {{STORY_TITLE}} | {{WHY_THIS_STORY}} | {{WHO_JOB_OUTCOME_OR_N_A}} | draft |

`Product intent` = Who / Job / Outcome (or `n/a` for pure TS/Bug). See `skills/_shared/backlog-item-types/persona-context.md`. `Rationale` = why this story is separate (sizing / anti-task-shatter). Cap ≤4 US/TS unless rationale is explicit (`feature-altitude.md`).

## Flags (`needs_*`)

| Flag | Valor |
|------|-------|
| needs_api | false |
| needs_domain | false |
| needs_database | false |
| needs_frontend | false |
| needs_security | false |
| needs_devops | false |

## Links

- CONTINUITY: `./CONTINUITY.md`
- CHANGE (brownfield vs current): `./CHANGE.md` — required when **Nature** = `brownfield`; greenfield must not force an empty stub (`CHANGE-CONTRACT.md`)
- Stories: `./US01/STORY.md` (ajustar ids)
- Norms: `skills/_shared/backlog-item-types/feature-altitude.md`, `product-evidence-lite.md`
