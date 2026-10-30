# Refinar itens de backlog

Este guia descreve o fluxo de refinamento de backlog: como um item informal de produto vira um story pronto para o SDD, quais skills participam e onde cada uma grava.

## Fluxo

1. `refine-story` escreve o item: `STORY.md` com critérios BDD e uma nota de qualidade.
2. No passo 4a, `refine-story` chama `requirement-review` antes do handoff. `requirement-review` contesta o item, faz as perguntas em aberto e só grava após `sim`.
3. `split-story-checklist` quebra o story em um checklist de tarefas (backend, frontend, testes).
4. `sdd-plan` chama `split-story-checklist` por conta própria para feature de complexidade média ou complexa. Feature trivial não gera arquivo de tarefas.

`orchestrate-analyze` também usa a pesquisa de funcionalidade de `refine-story` internamente, no passo 8c. Por isso o orquestrado não precisa chamar `refine-story` antes.

Enquanto houver item **B** ou **I** em aberto, não faça handoff para `sdd-spec`. Veja a regra de pronto em [flow-selection.md](flow-selection.md).

## Onde grava

| Artefato | Caminho com story | Caminho sem story (atalho) |
|----------|-------------------|----------------------------|
| Story | `features/NNN-slug/USnn/STORY.md` (ou `TSnn`) | `docs/backlog/<slug>.md` |
| Revisão de requisito | `features/NNN-slug/USnn/REFINE/requirement-review-feature.md` (ou `-tech.md`) | `docs/backlog/<slug>-requirement-review-<modo>.md` |
| Histórico de Q&A | `features/NNN-slug/USnn/REFINE/qa-history.md` | `docs/backlog/<slug>-qa-history.md` |
| Checklist de tarefas | `features/NNN-slug/USnn/REFINE/tasks.md` | `docs/implementation-tasks/<slug>.md` |

Com texto colado no chat e sem caminho de arquivo, o relatório fica no chat. Nada é gravado até o operador indicar um caminho e confirmar.

## Skills

### refine-story

- **Lê:** o caminho ou o texto informado pelo operador. Procura PRDs em `features/**/PRD/`, não em uma pasta `PRD/` na raiz.
- **Grava:** `STORY.md` (ou `TSnn/STORY.md`) e `REFINE/qa-history.md`. Atalho: `docs/backlog/<slug>.md`, depois de pergunta sobre o idioma do documento.
- **Onde:** [core/skills/refine-story/SKILL.md](../../core/skills/refine-story/SKILL.md).
- **Quando usar:** item de produto (bug, user story ou história técnica) que ainda não é uma entrega de feature completa. O modo é obrigatório: `feature`, `tech` ou `split`. Sem modo, a skill pergunta.

### requirement-review

- **Lê:** `STORY.md`, `FEATURE.md`, `REFINE/refine.md` ao lado do story, ou texto colado. Antes de perguntar, lê `REFINE/qa-history.md` para não repetir uma pergunta já resolvida. No modo `--tech`, também lê o repositório.
- **Grava:** o relatório da revisão e o histórico de Q&A, após `sim`. Sem pasta de story, o relatório fica no chat, a menos que o operador indique uma pasta de story ou o atalho `docs/backlog/`.
- **Onde:** [core/skills/requirement-review/SKILL.md](../../core/skills/requirement-review/SKILL.md).
- **Quando usar:** conferir critérios de aceite (`--feature`) ou contratos e fluxos no código (`--tech`) antes do SDD. Exatamente um modo por execução. Sem modo, a skill pergunta.

### split-story-checklist

- **Lê:** `STORY.md` com a seção **Steps** preenchida (ou a **Suggested fix** em bug). Quando chamado pelo `sdd-plan`, lê o PRD e os `REQ` do story.
- **Grava:** `REFINE/tasks.md`. Atualiza esse arquivo se ele já existir e não cria `TASKS.md` duplicado. Atalho: `docs/implementation-tasks/<slug>.md`. Não cria pastas `USnn` ou `TSnn` novas.
- **Onde:** [core/skills/split-story-checklist/SKILL.md](../../core/skills/split-story-checklist/SKILL.md).
- **Quando usar:** feature de complexidade média ou complexa, ou quando o operador quer o checklist antes do plano. Para complexidade trivial, a skill não grava o arquivo.

## Veja também

- [flow-selection.md](flow-selection.md): escolha do fluxo.
- [../sessions/03-backlog-shape.md](../sessions/03-backlog-shape.md): regras de scorecard e de story dentro da análise.
- [../sessions/01-orchestrated-delivery.md](../sessions/01-orchestrated-delivery.md): o caminho completo de feature.
