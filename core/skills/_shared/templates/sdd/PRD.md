# PRD: [Nome da feature]

| Campo | Valor |
|-------|--------|
| **Sequência** | NNN |
| **Rastreamento** | [US0N / TS0N / issue / slug] |
| **Versão** | 1 |
| **Data** | AAAA-MM-DD |
| **Status** | Pronto para planejamento |
| **Aprovação do conteúdo** | [preencher somente após confirmação explícita: operador e data] |
| **Prioridade** | Alta / Média / Baixa |
| **Complexidade** | Baixa / Média / Alta |
| **Repositório** | [nome na raiz do git] |
| **Stack** | [.NET / Angular / outro] |
| **Track** | Classic SDD / Backlog Refine / Orchestrated Delivery |

## Execution policy

| Field | Value |
|-------|--------|
| **Orchestrator mode** | `always` / `adaptive` (from `{{SDD_ROOT}}/preferences.json`; default `adaptive`) |
| **Parent role** | Orchestrator only — delegate implementation to specialists |
| **Child validation** | After file changes: child runs build + tests; reports `{ build, tests, summary }` |
| **Handoff** | Scoped paths + receipt per `SPAWN.md` — no full PRD dump into child prompts |
| **Artifact language** | Same as user chat (`LANGUAGE.md`); override via `preferences.json` `artifact_language` or manifest |

## Related

| Relação | Path portátil |
|---------|---------------|
| PLAN | `features/NNN-slug/USnn/PLAN/PLAN_NNN_….md` (omit row if PLAN absent) |
| STORY | `features/NNN-slug/USnn/STORY.md` (omit if absent) |
| FEATURE | `features/NNN-slug/FEATURE.md` (omit if absent) |
| CONTINUITY | `features/NNN-slug/CONTINUITY.md` (omit if absent) |

Title **must** be `## Related` (`STORAGE.md` § Navigation block; RN05). Paths portable only. Omit-if-absent — do not stub siblings only for links.

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

Quando um CA concretiza uma decisão vigente, o texto normativo deve refletir essa decisão; ID ou link válido, por si só, não prova concordância. Preserve decisões substituídas como histórico, não como regra ativa. Contradição não resolvida torna o REQ/CA afetado insuficiente até reconciliação pelo dono existente. Inclua apenas comportamentos aplicáveis; aceite genérico ou comportamento material desconhecido deve virar pergunta em §5.1, não preenchimento presumido.

### CA1 - [Nome descritivo]

**Dado** [contexto inicial]
**Quando** [ação]
**Então** [resultado observável]

### 2.1 DoR de implementação

O DoR de implementação registra se os artefatos permitem iniciar com segurança; ele
é distinto do `READY` de esclarecimento definido em
`skills/_shared/sdd-artifacts/readiness-severity.md`. Antes do primeiro passo,
confirme e registre evidência para cada item aplicável:

- Todos os REQ funcionais estão mapeados para pelo menos um CA verificável; cada CA
  tem cenário de validação identificado em §10.
- Escopo, exclusões e critérios obrigatórios estão explícitos em §3–§5.
- Dependências, decisões e perguntas que possam mudar a solução ou o aceite estão
  resolvidas; perguntas restantes têm responsável e não bloqueiam a execução.
- O PLAN canônico aprovado cobre cada REQ/CA em passos com aceite verificável,
  dependências e validações previstas.

Se um item aplicável estiver ausente ou sem evidência, o DoR não está satisfeito e o
início da implementação deve aguardar. `READY` continua indicando somente que não há
perguntas B, I ou MINOR sem resposta; ele não aprova o PLAN nem autoriza implementação.
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

IDs estáveis `REQ-NNN` (três dígitos). Todo REQ mapeia para ≥1 CA. Não renumerar após handoff para PLAN. Para cada REQ baseado em fonte ou decisão material, cite o caminho portátil/seção e a decisão vigente quando aplicável; essa referência dá rastreabilidade, não substitui a comparação do texto.

### 4.1 Funcionais

| ID | Requisito | CA | Fonte/decisão vigente (quando aplicável) |
|----|-----------|-----|-----------------------------------------|
| **REQ-001** | [Comportamento verificável] | CA1 | [caminho portátil + seção; decisão atual, se houver] |
| **REQ-002** | [Comportamento verificável] | CA2 | [caminho portátil + seção; decisão atual, se houver] |

Confronte a redação efetiva dos REQ/CA com a fonte vigente. Registre regras, falhas, compatibilidade/preservação e limites de evidência que sejam materiais ao escopo; não exija categorias irrelevantes por formulário. Lacuna que possa mudar o comportamento fica em §5.1 com responsável e severidade, sem virar requisito `agreed` por inferência.

### 4.2 Não funcionais

| ID | Requisito |
|----|-----------|
| **RNF-001** | [Performance, segurança, observabilidade, etc.] |

Inclua somente requisitos não funcionais e limitações de evidência aplicáveis. Limite material ainda desconhecido deve ser uma pergunta em §5.1, não uma exigência inventada.

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

Confira se a exclusão aprovada não contradiz REQ/CA vigentes. Exclusão sugerida sem base confirmada permanece `invented`; conflito não resolvido fica com o dono da decisão em §5.1.

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

### 7.3 Contrato observável de API (quando houver endpoint)

Antes de liberar este PRD para `sdd-plan`, cada endpoint deve declarar aqui ou
referenciar um contrato canônico portátil:

| Campo | Contrato |
|-------|----------|
| Método e rota | [ex.: `POST /orders`] |
| Request | [schema, tipos e obrigatoriedade] |
| Response | [schema, tipos e obrigatoriedade] |
| Validações | [regras e resposta para entrada inválida] |
| Status e erros | [status, código e payload de erro] |
| Exemplos | [request/response representativos] |
| Fonte canônica | [path portátil, se estiver fora do PRD] |

Lacuna em qualquer campo comportamental é uma pergunta `blocker`: não avance
para o PLAN até completar o contrato ou registrar a referência canônica.

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

Esta seção separa qualidade da especificação (DoR) de conclusão da implementação
(DoD). Marque os itens de DoD somente após verificar o resultado e registrar a
evidência correspondente no PLAN/EVD:

- [ ] **DoR da especificação:** todos os REQ estão cobertos por CA verificáveis e o
      OOS está explícito (pré-condições para planejamento, não prova de conclusão).
- [ ] **DoD da implementação:** implementação alinhada aos REQ e CA aceitos; cada
      passo concluído tem aceite atendido e validações previstas aprovadas.
- [ ] **DoD da implementação:** testes aplicáveis cobrem os critérios e resultados
      estão registrados; falhas e pendências obrigatórias foram resolvidas.
- [ ] **DoD da implementação:** build/validação estrutural aplicável passou e a
      revisão do PLAN não encontrou lacunas obrigatórias abertas.

O estado `READY` não satisfaz nenhum item de DoR de implementação ou DoD por si só.

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
