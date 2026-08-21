# PRD: Fixture valid structural sample

| Campo | Valor |
|-------|--------|
| **Sequência** | 999 |
| **Status** | Pronto para planejamento |
| **Track** | Classic SDD *(formerly Forma A)* |

## 1. Visão geral

### 1.1 Contexto

Fixture used by Assert-ValidatePrdPlan only.

### 1.2 Objetivo

Prove validate-prd accepts REQ + CA.

## 2. Critérios de aceite

### CA1 - Valid fixture passes

**Dado** um PRD com REQ e CA
**Quando** validate-prd executa
**Então** exit code é 0

## 4. Requisitos (REQ-IDs)

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| **REQ-001** | Fixture must include a stable REQ id | CA1 |

## 5. Fora de escopo (OOS) — explícito

| Item | Motivo |
|------|--------|
| Production feature | Fixture only |
