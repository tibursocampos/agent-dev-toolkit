# STORY: {{STORY_ID}} - {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | {{STORY_ID}} |
| **Tipo** | US \| TS \| Bug |
| **Feature** | `features/{{NNN}}-{{slug}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/` (global; portable path) |
| **Path** | `features/{{NNN}}-{{slug}}/{{STORY_ID}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/{{STORY_ID}}/` (global) |

`Tipo` identifies the kind of story. Keep it here when useful; no separate implementation status is needed because execution progress belongs in the PLAN.

## Related

| Relação | Path portátil |
|---------|---------------|
| FEATURE | `features/{{NNN}}-{{slug}}/FEATURE.md` |
| PRD | `features/{{NNN}}-{{slug}}/{{STORY_ID}}/PRD/…` (omit if absent) |
| PLAN | `features/{{NNN}}-{{slug}}/{{STORY_ID}}/PLAN/…` (omit if absent) |
| ANALYSIS / ARCH / SEC | `./ANALYSIS/`, `./ARCH/`, `./SEC/` when on-disk (omit if absent) |

Title **must** be `## Related` (`STORAGE.md` § Navigation block; RN05). Portable paths only. Omit-if-absent — do not stub siblings only for links.

## Objective

{{OBJECTIVE}}

One verifiable outcome. Title and Objective must be outcome-shaped — not verb+file/class/script (`anti-task-shatter.md`).

## Who / Job / Outcome (US)

Required when **Tipo** = `US`. For pure TS/Bug, set each field to `n/a`.

| Campo | Valor |
|-------|--------|
| **Who** | {{WHO}} |
| **Job** | {{JOB}} |
| **Outcome** | {{OUTCOME}} |

See `skills/_shared/backlog-item-types/persona-context.md`. Optional Evidence under persona follows **omit > fabricate** (`product-evidence-lite.md`).

## Descrição

{{DESCRIPTION}}

Supporting narrative; does not replace Objective or Who/Job/Outcome.

## Fora de escopo (OOS)

| Item | Motivo |
|------|--------|
| {{OOS_ITEM}} | {{OOS_REASON}} |

Explicit exclusions for this story. Use `N/A` / empty table only when truly none known — prefer naming known non-goals.

## Critérios de aceite

Describe the observable outcomes that define this story. Include edge or failure behavior when relevant to the outcome and risk; do not require a fixed number or category of scenarios.

**FEATURE macro-acceptance ids:** {{FEATURE_MACRO_AC_IDS}}

Reference related FEATURE outcomes or decisions when useful. The acceptance text states the behavior directly; links and IDs are navigation aids.

### Outcome (add scenarios as useful)

```gherkin
Dado {{HAPPY_GIVEN}}
Quando {{HAPPY_WHEN}}
Então {{HAPPY_THEN_OBSERVABLE}}
```

```gherkin
Dado {{CONTEXT_WHEN_RELEVANT}}
Quando {{ACTION_OR_EVENT}}
Então {{OBSERVABLE_OUTCOME}}
```

Add another scenario only for a distinct outcome, boundary, or failure that matters to this story.

## Dependências (quando houver)

- {{DEP_STORY_AND_REASON}}

## Decisão em aberto (quando material)

Record a concrete unresolved decision here only when it affects this story's behavior, acceptance, scope, required access, or implementation choice. Use a separate analysis note only when the evidence or decision needs its own record.

## Artefatos da história (conforme necessidade)

| Pasta | Uso |
|-------|-----|
| `REFINE/` | Refine / breakdown — **opcional / sob demanda** |
| `ANALYSIS/` | Evidência de investigação separada quando útil |
| `ARCH/` | Decisão de arquitetura separada quando útil |
| `SEC/` | Análise de segurança separada quando útil; riscos e controles continuam registrados onde apropriado |
| `PRD/` | PRD canônico da história (O2) |
| `PLAN/` | PLAN canônico da história (O2) |

Create only artifacts needed for the approved scope. Brownfield impact belongs in the PRD or PLAN when relevant: current behavior, intended change, and concrete risks. Do not create a sidecar solely because a flag or classification is present. Do not create these folders at the repository root.
