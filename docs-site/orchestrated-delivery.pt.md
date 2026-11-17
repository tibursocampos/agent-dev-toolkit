---
title: Entrega orquestrada
---

# Entrega orquestrada

Use Orchestrated Delivery quando a análise entre stories, perguntas para especialistas ou execução coordenada forem úteis. SDD clássico também pode começar diretamente para uma feature clara. Cada skill `orchestrate-*` define seu procedimento detalhado; [Usando skills](using-skills.pt.md) explica como invocá-las.

## Fluxo

| Fase | Skill | Resultado |
|---|---|---|
| O1 — Análise | `orchestrate-analyze` | Investigação proporcional e stories justificadas. Especialistas e notas de análise entram apenas para perguntas concretas. |
| O2 — Entrega | `orchestrate-deliver` | PRD e PLAN executável para cada story selecionada. Escrever rascunhos faz parte da preparação. |
| O3 — Implementação (opcional) | `orchestrate-develop` | Fila serial de passos do PLAN; um filho por passo, com reconciliação antes do próximo despacho. |

Antes da implementação, O2 apresenta o PLAN completo ou um conjunto de PLANs explicitamente listado para uma única aprovação. Nova decisão só é necessária quando comportamento, aceite, escopo, acesso ou escolha de implementação mudarem materialmente. Uma questão material bloqueia apenas o trabalho afetado; dúvidas menores ficam visíveis e stories independentes podem avançar.

## Contexto e artefatos

Memory Bank, CONTINUITY, CHANGE, TASKS e arquivos auxiliares de especialistas são contexto opcional. Trabalho novo não exige criá-los; retomadas não exigem conversão, sincronização ou exclusão. A classificação brownfield, sozinha, não exige espelhamento de arquitetura. Registre decisões materiais em FEATURE/STORY/PRD/PLAN ou crie uma análise separada quando ela trouxer evidência útil.

O PLAN é a única fonte persistida de progresso da implementação. O1, O2 e O3 são donos de uma tabela contextual no chat cada. Chamadas internas de spec/plan/develop não exibem uma tabela concorrente. O [guia de arquitetura](architecture.pt.md) descreve os contratos compartilhados do toolkit e suas relações.

O3 usa ritmo `step_by_step` ou `continuous`, mas a implementação continua serial: um passo do PLAN por filho. Confira o resultado e atualize o PLAN antes do próximo despacho. Flags de SESSION e claims não são pré-requisitos. Na retomada, use o PLAN persistido e inspecione trabalho parcial; não repita passo concluído apenas por falta de recibo ou flag de sessão.

## Fechamento

Execute as validações exigidas pelo PLAN aprovado e uma revisão substantiva. Reutilize evidência atual quando ela cobrir a mesma stack, comando e working tree sem mudanças. Depois de correção dentro do escopo, rode novamente apenas as verificações invalidadas. Commit, push, PR, instalação e publicação são ações separadas e precisam de autorização própria.

Veja [Usando skills](using-skills.pt.md) para invocação e comportamento da sessão.
