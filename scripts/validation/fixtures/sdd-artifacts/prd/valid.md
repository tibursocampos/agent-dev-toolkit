# PRD: Fixture estrutural válida

| Campo | Valor |
|-------|--------|
| **Sequência** | 999 |
| **Rastreamento** | TS01 |
| **Versão** | 1 |
| **Data** | 2026-10-12 |
| **Status** | Pronto para planejamento |
| **Prioridade** | Média |
| **Complexidade** | Baixa |
| **Repositório** | fixture |
| **Stack** | Markdown |
| **Track** | Classic SDD |

## Execution policy

| Field | Value |
|-------|--------|
| **Orchestrator mode** | `always` |
| **Parent role** | Orchestrator only |
| **Child validation** | Generic structural checks |
| **Handoff** | Scoped paths per SPAWN.md |
| **Artifact language** | Same as user chat |

## Related

No related artifacts are present in this fixture; omit sibling rows.

## 1. Visão geral

### 1.1 Contexto

Fixture mínima que demonstra aceitação da estrutura base do template PRD.

### 1.2 Objetivo

Validar que o validador aceita um PRD completo sem exigir seções condicionais quando não aplicáveis.

## 2. Critérios de aceite

### CA1 - Fixture válida passa

**Dado** um PRD com estrutura base, REQ e CA
**Quando** `validate-prd` é executado
**Então** o código de saída é zero.

## 3. Escopo técnico (alto nível)

### 3.1 Componentes a modificar

Nenhum componente de produção.

### 3.2 Novos componentes

Nenhum componente novo.

### 3.3 Reuso sem alteração

O validador de PRD existente.

### 3.4 Fluxo de dados

O script lê este arquivo e valida sua estrutura.

## 4. Requisitos (REQ-IDs)

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| **REQ-001** | O validador aceita a estrutura base descrita no template. | CA1 |

### 4.2 Não funcionais

Não há requisito não funcional aplicável.

### 4.3 MoSCoW

| Prioridade | Itens |
|------------|-------|
| **Must** | REQ-001 |
| **Should** | nenhum |
| **Could** | nenhum |
| **Won't** | nenhum |

### 4.4 Regras de negócio

- O validador verifica estrutura; não avalia qualidade semântica.

## 5. Fora de escopo (OOS) — explícito

| Item | Motivo |
|------|--------|
| Testes de comportamento de produto | A fixture cobre somente a estrutura do artefato. |

## 8. Tratamento de erros

### TE01 - Estrutura ausente

- **Situação**: uma seção obrigatória está ausente.
- **Tratamento**: o validador encerra com erro e identifica a lacuna.
- **Mensagem usuário/log**: caminho e seção ausente.

## 9. Casos de uso

### CU01 - Validar estrutura

**Ator:** validador automatizado.

**Fluxo:**

1. Lê a fixture.
2. Confirma as seções obrigatórias e os REQ/CA.

## 10. Cenários de teste

A fixture é estrutural; não define testes de comportamento de produto.

## 11. Definição de pronto

- [ ] Estrutura base presente.
- [ ] Seções condicionais ausentes quando não aplicáveis.

## 12. Próximos passos

Executar `Assert-ValidatePrdPlan.ps1`.

## 13. Referências

- `core/skills/_shared/templates/sdd/PRD.md`
- `scripts/validation/validate-prd.ps1`

## 14. Histórico de alterações

| Data | Versão | Autor | Descrição |
|------|--------|-------|-----------|
| 2026-10-12 | 1 | Toolkit | Fixture mínima alinhada ao contrato estrutural. |
