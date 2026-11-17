# FEATURE: {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | `{{NNN}}-{{slug}}` |
| **Path** | `features/{{NNN}}-{{slug}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/` (global; portable path — see `STORAGE.md` § Portable path) |
| **Scope (when known)** | backend \| frontend \| fullstack |
| **Nature (when known)** | greenfield \| brownfield \| operational |
| **Complexity (when useful)** | trivial \| medium \| complex |

## Problem

{{PROBLEM}}

Describe the user or business need when it helps explain the intended outcome. Do not use this document as a file checklist.

## Goals

- {{GOAL_1}}
- {{GOAL_2}}

Observable outcomes for the initiative. Include goals that clarify scope; omit this section when the outcome is already clear elsewhere.

## Non-goals

- {{NON_GOAL_1}}
- {{NON_GOAL_2}}

Use when explicit exclusions help prevent scope confusion; do not add placeholder non-goals.

## Macro acceptance criteria

Filled prose in this file follows the chat language (`LANGUAGE.md`). Ids and severity tokens stay English.

| Id (optional) | Observable result | Condition (when relevant) | Failure or boundary (when relevant) | Story or decision reference (when useful) |
|--------------|-------------------|--------------------------|-----------------------------------------|------------------------------------------|
| {{OPTIONAL_ID}} | {{OBSERVABLE_RESULT}} | {{CONDITION_OR_OMIT}} | {{FAILURE_OR_BOUNDARY_OR_OMIT}} | {{REFERENCE_OR_OMIT}} |

Use only for initiative-level outcomes that help divide or assess the work. Keep outcomes observable where possible; omit conditions or failure details that do not apply. Do not put a file checklist here.

Use links or stable IDs when they make a material behavior easier to trace. Keep decisions and unresolved material questions in their own sections; do not duplicate them here.

## Evidence (when useful)

| Campo | Valor |
|-------|--------|
| **Evidence** | {{EVIDENCE_PATH_OR_REDACTED_OR_OMITTED}} |

Prefer relevant portable paths or redacted snippets. Never invent quotes, metrics, or PII. See `skills/_shared/backlog-item-types/product-evidence-lite.md`.

For an external source that may be needed during O3, cite `external:<alias>/<relative-path>` (for example, `external:Demandas/brief/source.md`) without its root. This records a portable evidence reference; it does not authorize O3 access. The O3 coordinator authorizes the alias and provides the alias-to-root map separately to the runtime guard (`STORAGE.md` § External evidence references for O3; `RECEIPT.md`).

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

Keep stable IDs when they help refer to material decisions. Record only decisions that affect scope, behavior, acceptance, or implementation; a short decision note is sufficient. Preserve relevant decision history without requiring a fixed schema or repeated traceability fields.

## Open questions

| Id | Severity | Impact | Owner | Question |
|----|----------|--------|-------|----------|
| Q-001 | B \| I \| MINOR | {{IMPACT}} | Product \| Engineering \| UX | {{QUESTION}} |

Use this section for unresolved questions that may affect behavior, acceptance, scope, required access, or an implementation choice. Name the affected work and an owner when useful. A question blocks only the work that cannot proceed without its answer; minor questions and optional improvements remain visible without blocking unrelated work.

## Histórias

| Id (when assigned) | Tipo | Título | Rationale (when useful) | Product intent (US) | Outcome/decision references (when useful) |
|--------------------|------|--------|--------------------------|--------------------|------------------------------------------|
| {{STORY_ID}} | {{US_TS_OR_BUG}} | {{STORY_TITLE}} | {{WHY_SEPARATE_IF_NEEDED}} | {{WHO_JOB_OUTCOME_OR_N_A}} | {{REFERENCES_OR_OMIT}} |

`Product intent` = Who / Job / Outcome (or `n/a` for pure TS/Bug). See `skills/_shared/backlog-item-types/persona-context.md`. `Rationale` = why this story is separate (sizing / anti-task-shatter). Cap ≤4 US/TS unless rationale is explicit (`feature-altitude.md`).

Use references to show where a story came from when helpful. An unresolved question may be recorded while independent stories are prepared; do not treat a suggestion as approved scope.

Stories may be drafted while questions remain open. Keep affected scope clear and do not proceed with dependent implementation until a material decision is resolved.

## Investigation signals (optional)

Use only to identify a concrete question that may need specialist investigation. A flag or classification alone does not require an agent, folder, or sidecar.

| Flag | Valor |
|------|-------|
| needs_api | {{TRUE_IF_A_CONCRETE_QUESTION_EXISTS}} |
| needs_domain | {{TRUE_IF_A_CONCRETE_QUESTION_EXISTS}} |
| needs_database | {{TRUE_IF_A_CONCRETE_QUESTION_EXISTS}} |
| needs_frontend | {{TRUE_IF_A_CONCRETE_QUESTION_EXISTS}} |
| needs_security | {{TRUE_IF_A_CONCRETE_QUESTION_EXISTS}} |
| needs_devops | {{TRUE_IF_A_CONCRETE_QUESTION_EXISTS}} |

## Related

| Relação | Path portátil |
|---------|---------------|
| STORY | `features/{{NNN}}-{{slug}}/US01/STORY.md` (ajustar ids; omit if absent) |
| PRD / PLAN | story `PRD/` / `PLAN/` when on-disk (omit if absent) |

Title **must** be `## Related` (`STORAGE.md` § Navigation block; RN05). Portable paths only. Omit-if-absent — do not stub siblings only for links.

Norms: `skills/_shared/backlog-item-types/feature-altitude.md`, `product-evidence-lite.md`.

Existing `CONTINUITY.md`, `CHANGE.md`, and `TASKS` files may be consulted as optional context. New FEATURE work does not require creating, converting, synchronizing, or deleting them. For brownfield impact, record current behavior, intended change, and concrete risks in the PRD or PLAN when relevant.
