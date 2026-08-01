# STORY: {{STORY_ID}} - {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | {{STORY_ID}} |
| **Tipo** | US \| TS \| Bug |
| **Feature** | `features/{{NNN}}-{{slug}}/` |
| **Path** | `features/{{NNN}}-{{slug}}/{{STORY_ID}}/` |
| **Status** | draft \| approved \| in-progress \| done |

## Descrição

{{DESCRIPTION}}

## Critérios de aceite (BDD)

```gherkin
Dado {{GIVEN}}
Quando {{WHEN}}
Então {{THEN}}
```

## Scorecard (resumo)

Rubric detail: `refine-story/reference.md` (scores **/100**). Map to this table as **1-5** (approx. `/20`, round nearest; floor 1 if score > 0).

| Critério | Nota (1-5) | Nota |
|----------|------------|------|
| Clareza | | |
| Testabilidade | | |
| Dependências | | |

## Dependências

- {{DEP_STORY_OR_NONE}}

## Subpastas esperadas

| Pasta | Uso |
|-------|-----|
| `REFINE/` | Refine / breakdown |
| `ANALYSIS/` | Impacto / risco |
| `ARCH/` | Arquitetura |
| `SEC/` | Segurança |
| `PRD/` | PRD canônico da história |
| `PLAN/` | PLAN canônico da história |

Não criar essas pastas na **raiz** do repositório.
