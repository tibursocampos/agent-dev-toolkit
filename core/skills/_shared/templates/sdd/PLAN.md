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

## Objetivo e limites

- **Resultado:** [o que será observavelmente diferente ao concluir]
- **Incluído:** [capacidades, áreas ou comportamentos dentro do escopo]
- **Fora de escopo:** [limites importantes, quando houver]
- **Restrições / dependências:** [somente as que afetam a execução]

## Impacto brownfield (quando aplicável)

- **Comportamento atual:** [evidência relevante ou limite do que foi observado]
- **Mudança pretendida:** [comportamento após a implementação]
- **Riscos concretos:** [compatibilidade, dados, integração, operação ou outro risco]

## Aprovação do plano

Registrar em uma nota curta a aprovação explícita deste PLAN antes da implementação e os limites informados pelo operador. A aprovação vale apenas para o resultado, escopo e decisões apresentados neste documento. Reabrir a decisão somente se uma mudança material afetar esses elementos.

## Estratégia de validação

[Verificações relevantes para o resultado, incluindo comandos já existentes quando conhecidos. Distinguir o que será verificado, o que depende de ambiente e o que não pode ser observado localmente. Agrupar validações quando isso oferecer evidência suficiente.]

## Progresso da implementação

Esta é a única tabela canônica de execução. Atualizar a linha do passo conforme o trabalho avança; não repetir seu estado em outro campo ou artefato.

| ID e passo | Dependências | Estado | Evidência e validação | Bloqueio ou próxima ação |
|------------|--------------|--------|-----------------------|-------------------------|
| S1 — [resultado do passo] | — | PENDING | — | — |

Estados permitidos: `PENDING`, `IN_PROGRESS`, `BLOCKED`, `COMPLETED`. Derive contagens da tabela; não mantenha totalizadores, percentuais, checklists ou filas duplicadas.

## Detalhamento dos passos

Descreva cada passo executável abaixo. Esta descrição complementa a tabela; não repita dependências ou estado. Inclua objetivo, alterações previstas, limites, aceite verificável e validação necessária. Dê a cada passo um ID útil para referência, sem exigir um formato específico como condição de autorização.

### S1 — [resultado do passo]

- **Objetivo:** [resultado observável]
- **Alterações previstas:** [comportamentos/artefatos dentro do escopo e limites]
- **Aceite:** [resultado verificável e referência ao comportamento no PRD quando aplicável]
- **Validação:** [verificação necessária e evidência esperada; explicar se não houver teste específico]
- **Risco ou dependência externa (quando relevante):** [impacto e encaminhamento]

## Decisões abertas (quando houver)

Registrar apenas questões ainda capazes de mudar comportamento, aceite, escopo, acesso necessário ou implementação. Identificar qual trabalho depende da resposta. Questões menores e melhorias opcionais não bloqueiam trabalho independente.

## Referências (quando relevantes)

- [Caminho portátil e seção/símbolo lidos]
