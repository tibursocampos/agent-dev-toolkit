# PRD: Navigation broken fixture

| Campo | Valor |
|-------|--------|
| **Sequência** | 999 |
| **Status** | Pronto para planejamento |
| **Track** | Classic SDD |

## Related

| Relação | Path portátil |
|---------|---------------|
| STORY | `features/999-nav-broken/US01/STORY.md` |

## 1. Visão geral

### 1.1 Contexto

PRD without PLAN citation under Related (CT4 fail path).

### 1.2 Objetivo

Assert-NavigationBlock must exit non-zero when both PRD and PLAN exist without mutual citation.

## 2. Critérios de aceite

### CA1 - Missing PLAN link

**Dado** PRD Related omits PLAN
**Quando** gate runs with sibling PLAN present
**Então** exit ≠ 0

## 4. Requisitos (REQ-IDs)

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| REQ-001 | Fail without mutual Related | CA1 |
