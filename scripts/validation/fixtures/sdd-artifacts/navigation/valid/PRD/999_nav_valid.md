# PRD: Navigation valid fixture

| Campo | Valor |
|-------|--------|
| **Sequência** | 999 |
| **Status** | Pronto para planejamento |
| **Track** | Classic SDD |

## Related

| Relação | Path portátil |
|---------|---------------|
| PLAN | `features/999-nav-valid/US01/PLAN/PLAN_999_nav_valid.md` |

## 1. Visão geral

### 1.1 Contexto

Minimal PRD for Assert-NavigationBlock CT4 (mutual Related).

### 1.2 Objetivo

Prove PRD↔PLAN reciprocity under `## Related`.

## 2. Critérios de aceite

### CA1 - Mutual Related

**Dado** PRD e PLAN com Related
**Quando** Assert-NavigationBlock valida o par
**Então** exit 0

## 4. Requisitos (REQ-IDs)

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| REQ-001 | Mutual Related present | CA1 |
