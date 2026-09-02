# PLAN: Preflight orphan-req fixture

| Campo | Valor |
|-------|--------|
| **PRD** | scripts/validation/fixtures/sdd-artifacts/preflight/orphan-req/TS01/PRD/998_preflight_orphan.md |
| **Total de passos** | 3 |
| **Progresso** | 0/3 |
| **Status** | draft |

## Execution policy

| Field | Value |
|-------|--------|
| **Orchestrator mode** | `always` |
| **Parent role** | Orchestrator only |
| **Child validation** | build + tests |
| **Handoff** | Scoped paths per SPAWN.md |

## Objetivos

- [ ] O1: Include orphan REQ on purpose

## Mapa REQ → passo

| REQ | Passo |
|-----|-------|
| REQ-001 | PASSO 1 |
| REQ-002 | PASSO 2 |
| REQ-999 | PASSO 3 |

---

### ⏳ PASSO 1: First

**Status:** Pendente | **Deps:** nenhuma

**Aceite:**

- [ ] REQ-001

---

### ⏳ PASSO 2: Second

**Status:** Pendente | **Deps:** 1

**Aceite:**

- [ ] REQ-002

---

### ⏳ PASSO 3: Orphan

**Status:** Pendente | **Deps:** 2

**Aceite:**

- [ ] REQ-999
