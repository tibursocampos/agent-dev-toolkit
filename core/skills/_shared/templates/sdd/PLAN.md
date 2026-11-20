# PLAN: [Nome da feature ou história]

Use the sections needed to make this work executable. Remove unused prompts. The PLAN is the single persisted source of implementation progress; do not copy its progress into CONTINUITY, CHANGE, TASKS, session state, or another table.

| Campo | Valor |
|-------|--------|
| **PRD** | [caminho portátil do PRD, quando houver] |
| **Repositório** | [quando relevante] |
| **Escopo aprovado** | [resultado e limites; preencher após a aprovação] |
| **Cadência** | [step_by_step / continuous, se definida; caso contrário, resolver no início da implementação] |

## Related

| Relação | Path portátil |
|---------|---------------|
| PRD | `features/NNN-slug/USnn/PRD/NNN_….md` (quando existir) |
| STORY | `features/NNN-slug/USnn/STORY.md` (quando existir) |
| FEATURE | `features/NNN-slug/FEATURE.md` (quando existir) |

Use `## Related` and portable paths. Omit absent siblings; do not create files only to satisfy a link. Existing CONTINUITY, CHANGE, and TASKS may be consulted as optional context.

## Objective and boundaries

- **Resultado:** [o que será observavelmente diferente ao concluir]
- **Incluído:** [capacidades, áreas ou comportamentos dentro do escopo]
- **Fora de escopo:** [limites importantes, quando houver]
- **Restrições / dependências:** [somente as que afetam a execução]

## Brownfield impact (when applicable)

- **Comportamento atual:** [evidência relevante ou limite do que foi observado]
- **Mudança pretendida:** [comportamento após a implementação]
- **Riscos concretos:** [compatibilidade, dados, integração, operação ou outro risco]

## Plan approval

Record explicit approval of this PLAN in a short note before implementation, including the limits stated by the operator. Approval applies only to the outcome, scope, and decisions presented in this document. Reopen approval only if a material change affects those elements.

## Technical design and decisions

[Changed contracts, components and entry points, dependencies, and grounded material choices. Where applicable, record the data model, transactions, states, concurrency, integration failures, guarantee limits, and security controls. Cite the canonical contract and specific evidence. See `skills/_shared/sdd-artifacts/AUTHORING-CONTENT.md`.]

## Validation strategy

[Verificações relevantes para o resultado, incluindo comandos já existentes quando conhecidos. Distinguir o que será verificado, o que depende de ambiente e o que não pode ser observado localmente. Agrupar validações quando isso oferecer evidência suficiente.]

## Implementation progress

Esta é a única tabela canônica de execução. Atualizar a linha do passo conforme o trabalho avança; não repetir seu estado em outro campo ou artefato.

| ID e passo | Dependências | Estado | Evidência e validação | Bloqueio ou próxima ação |
|------------|--------------|--------|-----------------------|-------------------------|
| S1 — [resultado do passo] | — | PENDING | — | — |

Allowed states: `PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`. Derive counts from the table; do not maintain duplicate totals, percentages, checklists, or queues.

## Step details

Describe each executable step below. This description complements the table; do not repeat dependencies or status. Include the objective, planned changes, limits, verifiable acceptance, and required validation. Give each step a useful reference ID without requiring a specific format as an authorization condition.

### S1 — [step outcome]

- **Objetivo:** [resultado observável]
- **Pré-condições:** [entradas ou condições necessárias além das dependências da tabela, quando relevantes]
- **Pontos de entrada:** [caminhos portáteis e símbolos existentes ou a criar]
- **Alterações previstas:** [comportamentos e artefatos dentro do escopo, com limites explícitos]
- **Erros e casos de borda:** [tratamento previsto quando afeta o passo]
- **Aceite:** [resultado verificável e referência ao comportamento no PRD quando aplicável]
- **Validação:** [verificação necessária e evidência esperada; explicar se não houver teste específico]
- **Risco ou dependência externa (quando relevante):** [impacto e encaminhamento]

## Open decisions (when applicable)

Record only questions that could still change behavior, acceptance, scope, required access, or implementation. Record the question, useful options, affected work, and, after an observable answer, the decision and its source. Minor questions and optional improvements do not block independent work.

## Referências (quando relevantes)

- [Caminho portátil e seção/símbolo lidos]
