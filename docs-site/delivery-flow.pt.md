---
title: Escolher um fluxo de entrega
---

# Escolher um fluxo de entrega

O toolkit oferece três fluxos para entregar features. Eles são caminhos independentes, não etapas obrigatórias de uma única esteira. Escolha conforme o formato da demanda e o modelo de artefatos desejado.

| Fluxo | Quando escolher | Artefatos principais | Aprovação antes de implementar |
|-------|----------------|----------------------|--------------------------------|
| [Classic SDD](#classic-sdd) | Uma feature tem direção clara e pode ser planejada diretamente. | PRD e PLAN dentro da pasta da story em `features/NNN-slug/`. | Aprovar o PLAN completo uma vez. |
| [Orchestrated Delivery](#orchestrated-delivery) | A feature precisa de análise entre várias stories, investigação brownfield ou coordenação de especialistas. | Contexto FEATURE/STORY, depois um PRD e PLAN para cada story selecionada. | Aprovar uma vez o conjunto completo e explicitamente listado de PLANs. |
| [ADT Delivery](#adt-delivery) | Você quer um fluxo ponta a ponta que refine e planeje a feature em um plano evolutivo. | Um único `features/NNN-slug/PLAN.md` durante refinamento, planejamento e implementação. | Aprovar uma vez o plano completo. |

Refinamento de backlog e revisão de requisitos podem preparar ou questionar um item antes do fluxo de feature, mas não são etapas obrigatórias. Para uma mudança pequena e isolada, `adt-developer` ou uma skill de stack é um atalho separado.

## Classic SDD

Comece com `adt-sdd-spec` → `adt-sdd-plan` → `adt-sdd-develop`. Classic SDD é um caminho direto para uma feature com direção clara; não exige O1, Memory Bank, arquivos FEATURE/STORY, checklist ou arquivos auxiliares de especialistas. A pasta canônica da story contém seu PRD e PLAN. O planejamento pode derivar passos diretamente de uma demanda suficientemente especificada, e o checklist é opcional.

A implementação segue o ritmo `step_by_step` ou `continuous` do PLAN aprovado. O PLAN é a fonte persistida de progresso da implementação. No fechamento, execute as validações exigidas pelo PLAN e uma revisão substantiva; reutilize evidências atuais e rode novamente somente as verificações afetadas por uma correção.

## Orchestrated Delivery

Comece com `adt-orchestrate-analyze` → `adt-orchestrate-prepare` → opcionalmente `adt-orchestrate-implement`. Use quando uma feature se beneficiar da análise O1 e coordenação entre stories. O1 investiga perguntas concretas de forma proporcional à demanda. O2 prepara um PRD e PLAN para cada story selecionada e apresenta o conjunto completo de PLANs para uma aprovação. O3 é opcional e despacha um passo do PLAN por vez, reconciliando cada resultado antes do próximo.

Memory Bank e arquivos separados de CONTINUITY, CHANGE, TASKS, ANALYSIS, ARCH ou SEC não são pré-requisitos padrão. Use arquivos auxiliares quando registrarem evidências distintas e úteis. O rótulo brownfield sozinho não exige um espelho de arquitetura. O fechamento de O3 segue as validações do PLAN aprovado e uma revisão substantiva. Reutilize evidências atuais; rode novamente apenas as verificações invalidadas por uma correção. Peça revisão de segurança quando um risco concreto justificar.

Detalhes: [Orchestrated Delivery](orchestrated-delivery.pt.md).

## ADT Delivery

Comece com `adt-delivery-flow` para entrega ponta a ponta ou invoque `adt-delivery-refine`, `adt-delivery-plan` ou `adt-delivery-implement` para uma etapa que já pode ser executada diretamente. Este fluxo mantém refinamento, planejamento, aprovação, progresso da implementação e evidências de fechamento em um único `PLAN.md` evolutivo na raiz da feature. O coordenador executa as etapas em ordem; o planejamento termina com uma aprovação explícita antes da implementação. O ciclo e o ritmo são próprios deste fluxo, separados de Classic SDD e O1/O2/O3.

A implementação e o fechamento seguem o escopo e as evidências de validação aceitos no plano, seguidos pela skill existente `adt-code-review`. O fluxo não faz commit, push, merge ou publicação automaticamente.

## Limites compartilhados

- Os fluxos são recomendações; Classic SDD não exige Orchestrated Delivery antes.
- Somente uma decisão material sem resposta bloqueia o trabalho afetado. Trabalho independente pode continuar.
- Rascunhar e salvar documentos durante uma etapa autorizada de análise ou planejamento é preparação. A aprovação ocorre no plano completo antes da implementação.
- Diagnósticos genéricos de documentos, títulos exatos, arquivos auxiliares opcionais e claims de progresso não criam gates de aprovação.
- Uma correção exige somente as verificações cuja evidência ela invalida. Revisões de segurança, arquitetura e dados são solicitadas quando um risco concreto justificar, não como checklist universal por passo.
