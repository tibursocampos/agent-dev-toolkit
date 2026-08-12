# STORY: {{STORY_ID}} - {{TITLE}}

| Campo | Valor |
|-------|--------|
| **Id** | {{STORY_ID}} |
| **Tipo** | US \| TS \| Bug |
| **Feature** | `features/{{NNN}}-{{slug}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/` (global; portable path) |
| **Path** | `features/{{NNN}}-{{slug}}/{{STORY_ID}}/` (repository) or `sdd/<repo-id>/features/{{NNN}}-{{slug}}/{{STORY_ID}}/` (global) |
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
