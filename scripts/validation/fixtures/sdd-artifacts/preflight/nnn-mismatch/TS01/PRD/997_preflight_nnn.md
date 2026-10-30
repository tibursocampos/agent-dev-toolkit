# PRD: Preflight nnn-mismatch fixture

| Campo | Valor |
|-------|--------|
| **Sequência** | 997 |
| **Status** | Pronto para planejamento |
| **Prioridade** | Média |
| **Complexidade** | Baixa |
| **Repositório** | fixture |
| **Stack** | Markdown de validação |
| **Track** | Classic SDD |

## Execution policy

| Field | Value |
|-------|--------|
| **Orchestrator mode** | `always` |
| **Parent role** | Orchestrator only |
| **Child validation** | build + tests |
| **Handoff** | Scoped paths per SPAWN.md |

## Related

| Relação | Path portátil |
|---------|---------------|
| PLAN | `scripts/validation/fixtures/sdd-artifacts/preflight/valid/TS01/PLAN/PLAN_998_preflight_valid.md` |

## 1. Visão geral

### 1.1 Contexto

PRD válido estruturalmente, com sequência divergente do PLAN.

### 1.2 Objetivo

Provar que a sequência 997 é rejeitada quando o PLAN indica 998, conforme CA1.

## 2. Critérios de aceite

### CA1 - Sequência divergente bloqueia

**Dado** PRD 997 e PLAN 998
**Quando** o preflight executa
**Então** o código de saída indica bloqueio por divergência de sequência

## 3. Escopo técnico (alto nível)

### 3.1 Componentes existentes

O fixture exercita o validador de preflight e o validador estrutural de PRD.

### 3.2 Novos componentes

Nenhum componente de produção é criado.

### 3.3 Reuso

O teste reutiliza os validadores existentes e seus contratos canônicos.

### 3.4 Fluxo de dados

O preflight lê os artefatos fixture e aceita o conjunto consistente.

## 4. Requisitos (REQ-IDs)

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| **REQ-001** | O fixture válido deve incluir um identificador REQ estável | CA1 |
| **additional behavior** | O segundo comportamento coberto permanece identificável | CA1 |

### 4.2 Não funcionais

O fixture deve ser portátil e determinístico.

### 4.3 Priorização MoSCoW

- **Must:** REQ-001 e additional behavior.

### 4.4 Regras de negócio

PRD e PLAN devem identificar a mesma sequência.

## 5. Fora de escopo (OOS) — explícito

| Item | Motivo |
|------|--------|
| Feature de produção | Fixture apenas |

## 8. Tratamento de erros

Estruturas ausentes devem ser rejeitadas por `validate-prd`.

## 9. Casos de uso

### CU01 - Validar fixture

1. O validador recebe PRD, PLAN e CHANGE consistentes.
2. O preflight aceita o conjunto.

## 10. Cenários de teste

| ID | Cenário | Resultado esperado |
|----|---------|--------------------|
| CT1 | Artefatos válidos e alinhados | Preflight passa |

## 11. Definição de pronto

- [x] O fixture satisfaz a estrutura requerida pelo validador canônico.
- [x] REQ-001 e additional behavior estão cobertos pelo PLAN fixture.

## 12. Próximos passos

Executar o verificador de preflight.

## 13. Referências

- `scripts/validation/Assert-PrdPlanChangePreflight.ps1`
- `scripts/validation/validate-prd.ps1`

## 14. Histórico de alterações

| Data | Versão | Alteração |
|------|--------|-----------|
| 2026-10-26 | 1.0 | Estrutura completa do fixture de divergência para os validadores canônicos |
