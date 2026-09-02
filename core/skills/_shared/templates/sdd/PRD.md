# PRD: [Nome da feature]

| Campo | Valor |
|-------|--------|
| **Sequência** | NNN |
| **Rastreamento** | [US0N / TS0N / issue / slug] |
| **Versão** | 1 |
| **Data** | AAAA-MM-DD |
| **Status** | Pronto para planejamento |
| **Prioridade** | Alta / Média / Baixa |
| **Complexidade** | Baixa / Média / Alta |
| **Repositório** | [nome na raiz do git] |
| **Stack** | [.NET / Angular / outro] |
| **Track** | Classic SDD / Backlog Refine / Orchestrated Delivery |

## Execution policy

| Field | Value |
|-------|--------|
| **Orchestrator mode** | `always` / `adaptive` (from `{{SDD_ROOT}}/preferences.json`; default `always`) |
| **Parent role** | Orchestrator only — delegate implementation to specialists |
| **Child validation** | After file changes: child runs build + tests; reports `{ build, tests, summary }` |
| **Handoff** | Scoped paths + receipt per `SPAWN.md` — no full PRD dump into child prompts |
| **Artifact language** | Same as user chat (`LANGUAGE.md`); override via `preferences.json` `artifact_language` or manifest |

## 1. Visão geral

### 1.1 Contexto

[Por que é necessário? Situação atual e problema.]

### 1.2 Objetivo

[Resultado desejado após a implementação — mensurável, sem jargão vago.]

### 1.3 Métricas de sucesso

| Métrica | Baseline | Alvo | Como medir |
|---------|----------|------|------------|
| [Nome] | [Valor ou `omitted — none yet`] | [Valor alvo] | [Sinal observável] |

Mandatory clarify depth for PRD (ARCH / REQ-002). Prefer real signals; **omit > fabricate** — never invent baselines (`skills/_shared/backlog-item-types/product-evidence-lite.md`).

### 1.4 Blast radius (quando aplicável)

[Áreas/módulos impactados; o que **não** muda; risco de regressão.]

## 2. Critérios de aceite

Use BDD: **Dado** / **Quando** / **Então** / **E**. Cada CA deve ser **verificável** (teste, script, checklist ou observação objetiva). Proibido: "funciona corretamente", "como esperado", "de forma adequada".

### CA1 - [Nome descritivo]

**Dado** [contexto inicial]
**Quando** [ação]
**Então** [resultado observável]
**E** [condição extra opcional]

### CA2 - [Nome descritivo]

**Dado** [contexto inicial]
**Quando** [ação]
**Então** [resultado observável]

## 3. Escopo técnico (alto nível)

### 3.1 Componentes a modificar

[Listar módulos, serviços ou áreas - sem código.]

### 3.2 Novos componentes

[Listar módulos, endpoints ou artefatos - sem código.]

### 3.3 Reuso sem alteração

[Peças existentes reutilizadas como estão.]

### 3.4 Fluxo de dados

[Fluxo textual entre componentes.]

## 4. Requisitos (REQ-IDs)

IDs estáveis `REQ-NNN` (três dígitos). Todo REQ mapeia para ≥1 CA. Não renumerar após handoff para PLAN.

### 4.1 Funcionais

| ID | Requisito | CA |
|----|-----------|-----|
| **REQ-001** | [Comportamento verificável] | CA1 |
| **REQ-002** | [Comportamento verificável] | CA2 |

### 4.2 Não funcionais

| ID | Requisito |
|----|-----------|
| **RNF-001** | [Performance, segurança, observabilidade, etc.] |

### 4.3 MoSCoW

| Prioridade | Itens (REQ-IDs ou capacidades) |
|------------|--------------------------------|
| **Must** | [REQ-… / capacidade obrigatória] |
| **Should** | [Importante, não bloqueante] |
| **Could** | [Desejável se couber] |
| **Won't** (agora) | [Explicitamente adiado] |

Mandatory PRD clarify field (ARCH / REQ-002). Align Must with in-scope CA; Won't must not contradict §5 OOS without rationale.

### 4.4 Regras de negócio

- **RN01**: [Regra]
- **RN02**: [Regra]

### 4.5 EARS (híbrido — opcional, não universal)

Usar EARS (**While** / **When** / **If** / **The system shall**) só quando requisitos event-driven ou condicionais ganharem clareza. Não forçar EARS em todo REQ. Se omitido, deixar esta subseção fora do documento.

## 5. Fora de escopo (OOS) — explícito

| Item | Motivo |
|------|--------|
| [Item] | [Por que fica de fora] |

## 5.1 Perguntas em aberto

| Pergunta | Severity | Owner | Notas |
|----------|----------|-------|-------|
| [Pergunta afiada] | blocker \| high \| medium \| low | [papel] | [opções / impacto] |

Mandatory when unknowns remain (`clarify-depth.md`). Every listed question **must** carry **Severity**. Omit the subsection only when zero open questions.

## 6. Migrações de banco (se aplicável)

**Migração necessária?** Sim / Não

Se sim: tabelas/colunas afetadas, impacto em dados existentes, reversibilidade.

## 7. Integrações (se aplicável)

### 7.1 Sistemas externos

[Listar APIs, filas, terceiros.]

### 7.2 Mudanças de contrato

[Alterações de payload ou API; breaking change Sim/Não com justificativa.]

## 8. Tratamento de erros

### TE01 - [Nome do cenário]

- **Situação**: [Quando ocorre]
- **Tratamento**: [Comportamento esperado]
- **Mensagem usuário/log**: [Intenção da mensagem]

## 9. Casos de uso

### CU01 - [Caso de uso principal]

**Ator:** [Usuário / sistema / serviço]

**Fluxo:**

1. [Passo]
2. [Resultado esperado]

## 10. Cenários de teste

Espelhar CA; incluir borda e falha. Preferir ligação a REQ/CA.

### CT1 - [Caminho feliz]

**Dado** … **Quando** … **Então** …

### CT2 - [Validação / borda]

**Dado** … **Quando** … **Então** …

## 11. Definição de pronto

- [ ] Todos os REQ-IDs cobertos por CA verificáveis
- [ ] OOS explícito
- [ ] Implementação alinhada a este PRD
- [ ] Testes unitários/integração para o novo comportamento
- [ ] Build passa local/CI

## 12. Próximos passos

```
/sdd-plan - <caminho-portátil-do-prd>
```

## 13. Referências

- [Docs do projeto em `docs/`]
- [PRDs relacionados]

## 14. Histórico de alterações

| Data | Versão | Autor | Descrição |
|------|---------|--------|-------------|
| AAAA-MM-DD | 1 | [Nome] | Versão inicial |
