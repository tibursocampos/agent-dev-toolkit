## Report template

Use when writing the final report for the `code-review` skill. Keep the report in **Brazilian Portuguese (pt-BR)** (technical terms may stay in English). Replace bracketed placeholders.

---

```markdown
# Code review - [Nome da feature]

## Resumo executivo

**Decisão:** Aprovado | Aprovado com ressalvas | Alterações necessárias

| Métrica | Valor |
|---------|-------|
| Aderência ao PRD | [ex.: 4/4 critérios] |
| Status do PLAN | [ex.: 6/6 passos concluídos] |
| SDD | [PRD/PLAN encontrados - caminhos] ou **Limitação SDD** (busca completa sem artefatos) |
| Arquivos revisados | [N] |
| Build / testes | [Passou / Falhou / Não executado] |
| Cobertura (código novo) | [X% - Passou ≥ 80% / Abaixo / Não aplicável] |
| Críticos | [0] |
| Importantes | [N] |
| Nice-to-have | [N] |

[Um parágrafo: escopo, principais achados, recomendação.]

---

## Verificação do PLAN (SDD)

_Omitir esta seção somente se step 0.5 registrou **Limitação SDD**._

**PLAN:** [caminho completo]

- Progresso: [X/N] - [consistente | inconsistências listadas]
- Passos concluídos: [lista]
- Pendente / desvio: [lista ou Nenhum]

---

## Aderência ao PRD (SDD)

_Omitir esta seção somente se step 0.5 registrou **Limitação SDD**._

**PRD:** [caminho completo]

### Critérios de aceite

| Critério | Status | Evidência |
|----------|--------|-----------|
| [CA1] | Atendido / Parcial / Ausente | [arquivo, teste] |

### Regras de negócio

| Regra | Status | Local |
|-------|--------|-------|
| [RN01] | Atendida / Ausente | [tipo.método] |

---

## Arquivos revisados

- [caminho] - [nota breve]

---

## Pontos positivos

- [Boas práticas observadas]

---

## Problemas críticos (bloqueantes)

### [Título]

- **Arquivo:** `caminho:linha`
- **Categoria:** Segurança | Bug | Breaking change
- **Problema:** [o que está errado]
- **Impacto:** [por que bloqueia merge]
- **Correção sugerida:** [passos concretos]

---

## Problemas importantes (não bloqueantes)

### [Título]

- **Arquivo:** `caminho:linha`
- **Problema:** [o que melhorar]
- **Sugestão:** [como]

---

## Nice-to-have

- [Melhorias opcionais]

---

## Testes

- **Unitários:** [passou/falhou, escopo]
- **Integração:** [passou/falhou, escopo]
- **Lacunas:** [cenários não cobertos]
- **Cobertura (código novo / arquivos alterados):** [X% - Passou ≥ [threshold]% / Abaixo do target / Não executado]
- **Cobertura geral (branch):** [Y% - informativo]
- **Meta:** 100% (mínimo aceitável: [80]% quando target aplicável)
- **Fonte:** `/test-coverage` - [colar bloco do relatório ou N/A]

---

## Segurança

- [ ] Sem secrets hardcoded
- [ ] Validação de entrada em dados externos
- [ ] Sem dados sensíveis em logs
- [ ] Acesso a dados parametrizado (sem concatenação SQL)

Problemas: [Nenhum | listados]

---

## Performance

- [ ] Sem N+1 óbvio no código alterado
- [ ] Async em trabalho I/O-bound
- [ ] Sem loops/alocações ilimitados em hot paths

Problemas: [Nenhum | listados]

---

## Oportunidades de refatoração (opcional)

| Prioridade | Área | Benefício |
|------------|------|-----------|
| Média | [método/classe] | [legibilidade / testabilidade] |

---

## Recomendação final

**Decisão:** [Aprovado | Aprovado com ressalvas | Alterações necessárias]

**Obrigatório antes do merge:**

1. [Ação ou Nenhuma]

**Recomendado após o merge:**

1. [Ação ou Nenhuma]

**Próximos passos do autor:**

- [ ]
```

---
