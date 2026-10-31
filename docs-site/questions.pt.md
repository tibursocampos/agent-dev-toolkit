---
title: Perguntas
---

# Perguntas

Algumas etapas param e esperam por você. O agente faz uma pergunta, mostra as opções e não continua até receber uma resposta que consiga ler. Esta página explica como a pergunta é feita e como responder. As regras vêm de `core/skills/_shared/agents/QUESTIONS.md`. Para os ids das skills, veja [Usando skills](using-skills.md).

## Como o agente pergunta

O agente usa o componente de pergunta nativo do host somente quando a opção escolhida volta para o agente. Se o host não tiver esse componente, ou se a resposta não chegaria ao agente, o agente pergunta em texto simples, com opções numeradas, no idioma da conversa.

Nos dois casos, o fluxo espera. A pergunta continua aberta até ser respondida. Silêncio, tempo esgotado ou o fim de um turno não são resposta.

## Como responder

Responda no seu idioma. Qualquer um destes funciona:

- Escolha uma opção no componente de pergunta, quando ele aparecer.
- Responda em texto com um sim claro, um pedido de ajuste ou um cancelamento. Por exemplo: "sim", "yes", "ok", "oui".

O agente converte a sua resposta em um id estável:

| Sua resposta | Id | Significado |
|--------------|----|-------------|
| Um sim claro | `confirm` | Aprova a ação ou o artefato exato mostrado. |
| Um pedido de mudança na proposta | `adjust` | Altera a proposta antes de agir. |
| Uma parada | `cancel` | Não executa a ação protegida pelo gate. |

Algumas respostas mantêm a pergunta aberta:

- Silêncio ou tempo esgotado.
- Um emoji isolado.
- Uma resposta ambígua ou não relacionada.

Uma resposta que concorda e ao mesmo tempo muda o escopo vira `adjust`. O agente mostra a proposta alterada e pergunta de novo. Texto livre que muda a proposta também vira `adjust`.

## Ids e rótulos dos gates

Os ids são tokens estáveis em inglês e não mudam com o idioma da conversa. Os rótulos que você vê seguem o idioma da conversa.

| Id | Significado | Rótulo (pt) |
|----|-------------|-------------|
| `confirm` | Aprova a ação ou o artefato exato mostrado. | sim |
| `adjust` | Altera a proposta antes de agir. | ajustar |
| `cancel` | Para. Não executa a ação protegida pelo gate. | cancelar |
| `skip` | Deixa uma etapa opcional sem fazer e continua. | pular |
| `decline` | Recusa uma oferta opcional. | não |

As palavras do gate no seu idioma são rótulos. Os ids por trás delas são os mesmos em todos os idiomas.

Uma aprovação cobre somente a ação para a qual foi dada. Um `confirm` para uma gravação ou um commit não aprova a próxima.

## Quais hosts mostram um componente de pergunta

O agente usa somente a linha do próprio host. Um nome de ferramenta nesta tabela indica que o toolkit conhece a ferramenta. O componente só é usado quando a resposta chega ao agente. Caso contrário, o agente pergunta em texto.

| Host | Mecanismo |
|------|-----------|
| `claude`, `grok`, `zcode` | `AskUserQuestion` |
| `hermes` | `ask_user` |
| `cursor`, `antigravity`, `codex`, `copilot`, `opencode`, `openhands` | Nenhum. Perguntas em texto com opções numeradas. |

## Quem pergunta

Somente a sessão principal faz perguntas a você. Subagentes nunca perguntam diretamente. Quando um subagente precisa de uma resposta, ele para e informa a pergunta no seu recibo. A sessão principal então pergunta a você e espera.

## Perguntas de texto livre

Algumas perguntas são abertas de propósito. As perguntas de intake do `sdd-spec` são um exemplo. Elas não têm um conjunto fixo de ids, e a sua resposta é registrada como texto. A pergunta continua esperando até você responder.
