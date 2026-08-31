# PRD: Fixture missing required sections

| Campo | Valor |
|-------|--------|
| **Sequência** | 998 |
| **Status** | Pronto para planejamento |

## 1. Visão geral

Fixture intentionally omits Execution policy, structured CA section, and OOS.

### CA1 - Should fail structural gate

**Dado** um PRD incompleto
**Quando** validate-prd executa
**Então** exit code é diferente de zero

**REQ-001** inline only — no ## 4. Requisitos section.
