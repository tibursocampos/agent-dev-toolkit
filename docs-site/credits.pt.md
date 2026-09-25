---
title: Créditos
---

# Créditos

O **agent-dev-toolkit** é software original. As seções abaixo nomeiam o trabalho externo que formou um comportamento, e o caminho onde esse comportamento vive neste repositório. O toolkit mantém o próprio código. Ele afirma afiliação só quando esses projetos a afirmam.

## Compressão de resposta

Encurtar a prosa do chat segue [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman).

O que este repositório entrega é uma integração de preferências: `core/skills/_shared/caveman/`, política `caveman-mode` e comandos de chat `caveman on|off|…`. A compactação opcional de continuidade é `COMPACT.md`. O `caveman-compress` de origem permanece naquele projeto. Isto é um recorte da ideia, não uma cópia do repositório.

A compressão é uma preferência de sessão e começa desligada. Os comandos, e o texto que permanece em prosa completa: [Usando skills](using-skills.md#session-behavior).

## Impeccable

O fluxo de comandos de UI e a orientação de design vêm de [pbakaus/impeccable](https://github.com/pbakaus/impeccable) e da CLI Impeccable (`npx impeccable`).

A skill `impeccable` do toolkit é um harness parcial, sincronizado pelos adaptadores: um subconjunto de referências, um handoff de `DESIGN-BRIEF.md` e os gates deste toolkit. Uma instalação upstream completa, inclusive hooks, permanece opcional e espera um sim explícito. Rodar esta skill e rodar o Impeccable sozinho são sessões diferentes.

## frontend-design da Anthropic

Um motivo de assinatura, um plano compacto de tokens antes do código e a intenção de escrita de UX vêm em parte de [anthropics/skills `frontend-design`](https://github.com/anthropics/skills/tree/main/skills/frontend-design).

A UI de produto neste toolkit segue `/impeccable` → `docs/DESIGN-BRIEF.md` → um `*-developer` de stack. O `frontend-design` de origem é uma referência opcional ao lado desse handoff. Não é uma skill do Core, e aquele repositório não é copiado para `core/`.

## Memory bank e Spec Kit

O `memory-bank/` da Orchestrated Delivery, e as políticas de gate em volta dele, são um mapa de workspace escrito para este toolkit: um inventário em PowerShell, sem a toolchain do Spec Kit.

Um workspace durável se apoia em parte em práticas em torno de [github/spec-kit](https://github.com/github/spec-kit). Este toolkit não executa Spec Kit, `uv` nem `specify`. Esses caminhos saíram do MVP. O mapa de workspace é Orchestrated Delivery e `memory-bank-init`. Os contratos Classic SDD rodam dentro desse caminho. Contratos internos (REQ, validate, CHANGE, EVD, STATE, TRACE) ficam dentro da chamada de skill que já existe.

## Qualidade do backlog de produto

Normas em `core/skills/_shared/backlog-item-types/` parafraseiam ideias públicas de gestão de produto: INVEST, divisão vertical, orçamento Gherkin e altitude do resultado. O toolkit não copia corpora de terceiros para o Core e não entrega slash skills de gestão de projeto da Anthropic como Core.

| Tema nas normas do toolkit | Fonte |
|----------------------------|--------|
| Qualidade de story INVEST | [xp123 — INVEST in Good Stories](https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/) |
| Divisão vertical / fatia fina | [Mountain Goat — story splitting](https://www.mountaingoatsoftware.com/agile/user-stories/story-splitting) |
| Gherkin / Then observável | [Cucumber — Gherkin reference](https://cucumber.io/docs/gherkin/reference/) |
| Altitude de resultado vs story vs tarefa | [Jeff Patton — User Story Mapping](https://www.jpattonassociates.com/user-story-mapping/) |

Campos de evidência seguem omitir em vez de fabricar (`product-evidence-lite.md`). Um scorecard não exige Evidência inventada. A compressão de chat deixa rascunhos de produto (FEATURE, STORY, PRD) em prosa completa. Veja `core/skills/_shared/caveman/CAVEMAN.md`.

## Licença

MIT © Raphael Campos (`LICENSE` no repositório). Ferramentas que você instala à parte mantêm a própria licença, inclusive a CLI Impeccable e o Spec Kit.
