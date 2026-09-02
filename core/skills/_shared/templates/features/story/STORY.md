# STORY: {{STORY_ID}} - {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | {{STORY_ID}} |
| **Tipo** | US \| TS \| Bug |
| **Feature** | `features/{{NNN}}-{{slug}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/` (global; portable path) |
| **Path** | `features/{{NNN}}-{{slug}}/{{STORY_ID}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/{{STORY_ID}}/` (global) |
| **Status** | draft \| approved \| in-progress \| done |

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

## Critérios de aceite (AC budget)

Minimum budget (`gherkin-budget.md`): **happy** + **rule/edge** + **failure**, each with an **observable Then**. One stub alone is not enough.

### Happy

```gherkin
Dado {{HAPPY_GIVEN}}
Quando {{HAPPY_WHEN}}
Então {{HAPPY_THEN_OBSERVABLE}}
```

### Rule / edge

```gherkin
Dado {{RULE_GIVEN}}
Quando {{RULE_WHEN}}
Então {{RULE_THEN_OBSERVABLE}}
```

### Failure

```gherkin
Dado {{FAILURE_GIVEN}}
Quando {{FAILURE_WHEN}}
Então {{FAILURE_THEN_OBSERVABLE}}
```

## Scorecard (resumo)

Rubric detail: `refine-story/references/scorecard-rubric.md` (scores **/100**; Product depth criterion max **10**). Map **Product depth** from that criterion (/10 → 1–5 per rubric). Map other rows from overall bands when needed (80+ = 5, 60–79 = 4, 40–59 = 3, else ≤2).

| Critério | Nota (1-5) | Nota |
|----------|------------|------|
| Clareza | | |
| Testabilidade | | |
| Dependências | | |
| Product depth | | |

**Product depth** reflects Valuable + AC budget (happy/rule/failure) + Who/Job/Outcome when US. Honest Evidence omission is not by itself a Product-depth failure.

## Dependências

- {{DEP_STORY_OR_NONE}}

## Decisões em aberto

Quando `needs_database` / `needs_domain`: apontar para `ANALYSIS/` (ex. `open-decisions.md`) — não o corpo de CONTINUITY.

| Campo | Valor |
|-------|--------|
| **Open decisions** | `{{STORY_ID}}/ANALYSIS/` (ou N/A) |

## Subpastas esperadas

| Pasta | Uso |
|-------|-----|
| `REFINE/` | Refine / breakdown — **opcional / sob demanda** |
| `ANALYSIS/` | Impacto / risco — **obrigatória** se FEATURE `needs_api` ou nature brownfield |
| `ARCH/` | Arquitetura — **obrigatória** se FEATURE `needs_domain` / `needs_database` ou brownfield |
| `SEC/` | Segurança — **obrigatória** se FEATURE `needs_security` |
| `PRD/` | PRD canônico da história (O2) |
| `PLAN/` | PLAN canônico da história (O2) |

Não criar essas pastas na **raiz** do repositório.
Não escrever “sob demanda” / “on demand” para `SEC/` / `ARCH/` / `ANALYSIS/` se a flag correspondente em FEATURE for true.
