# PRD: Preflight valid fixture

| Campo | Valor |
|-------|--------|
| **Sequência** | 998 |
| **Status** | Pronto para planejamento |
| **Track** | Classic SDD |

## Execution policy

| Field | Value |
|-------|--------|
| **Orchestrator mode** | `always` |
| **Parent role** | Orchestrator only |
| **Child validation** | build + tests |
| **Handoff** | Scoped paths per SPAWN.md |

## 1. Visão geral

### 1.1 Contexto

Valid PRD for Assert-PrdPlanChangePreflight allow path.

### 1.2 Objetivo

Prove preflight allows consistent PRD/PLAN/CHANGE.

## 2. Critérios de aceite

### CA1 - Consistent artifacts pass

**Dado** PRD PLAN CHANGE aligned
**Quando** preflight executa
**Então** exit code é 0

## 4. Requisitos (REQ-IDs)

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| **REQ-001** | Fixture must include a stable REQ id | CA1 |
| **REQ-002** | Second covered behavior | CA1 |

## 5. Fora de escopo (OOS) — explícito

| Item | Motivo |
|------|--------|
| Production feature | Fixture only |
