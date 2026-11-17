# PRD: [Nome da feature ou história]

Use the sections that explain the requested behavior. Remove unused prompts and do not add placeholders merely to match a structure. Prose follows the user's language; IDs and paths stay stable and portable.

| Campo | Valor |
|-------|--------|
| **Sequência** | [quando aplicável] |
| **História / referência** | [US, TS, issue ou referência útil] |
| **Data** | [quando útil] |
| **Prioridade** | [quando definida] |
| **Stack / repositório** | [quando relevante] |

## Related

| Relação | Path portátil |
|---------|---------------|
| PLAN | `features/NNN-slug/USnn/PLAN/PLAN_NNN_….md` (quando existir) |
| STORY | `features/NNN-slug/USnn/STORY.md` (quando existir) |
| FEATURE | `features/NNN-slug/FEATURE.md` (quando existir) |

Use `## Related` and portable paths. Omit absent siblings; do not create files only to satisfy a link. Existing CONTINUITY, CHANGE, or TASKS files may be consulted as optional context.

## Resultado e contexto

### Necessidade atual

[Problema ou necessidade que motivou o trabalho. Para mudança brownfield, descreva o comportamento atual relevante e cite evidência quando disponível.]

### Resultado esperado

[Mudança observável para usuário, operação ou sistema.]

### Impacto brownfield (quando aplicável)

- **Comportamento atual:** [o que foi observado e a evidência, ou o que ainda não foi verificado]
- **Mudança pretendida:** [resultado que o escopo aprovado deve produzir]
- **Riscos concretos:** [compatibilidade, dados, integração, operação ou `nenhum identificado` com base suficiente]

## Escopo

### Incluído

- [Capacidade ou comportamento incluído]

### Fora de escopo (quando houver)

- [Exclusão e motivo]

## Comportamento e aceite

Descreva cada comportamento material em linguagem verificável. Use REQ/CA ou outros IDs quando facilitarem referência entre documentos; não exija uma nomenclatura, numeração, formato BDD ou quantidade fixa. O comportamento e seus limites devem ficar claros no texto.

| Referência (opcional) | Comportamento esperado | Condição ou limite (quando relevante) | Como reconhecer o resultado |
|-----------------------|------------------------|--------------------------------------|-----------------------------|
| [ID ou omitir] | [comportamento] | [condição, falha ou limite] | [sinal observável] |

### Regras, contratos e integrações (quando relevantes)

[Regras de negócio, interfaces, validações, dados, compatibilidade, tratamento de erro ou referências a contratos existentes. Inclua apenas o que afeta o comportamento pedido.]

## Decisões e perguntas materiais

Registre decisões necessárias para entender o comportamento ou iniciar implementação. Uma pergunta bloqueia somente o trabalho que depende de sua resposta; dúvidas menores permanecem visíveis e não interrompem trabalho independente.

| Questão / decisão | Estado ou resposta | Trabalho afetado (quando houver) | Referência (quando útil) |
|-------------------|-------------------|----------------------------------|--------------------------|
| [texto ou omitir] | [aberta / decisão e fonte] | [impacto] | [caminho portátil ou omitir] |

## Validação esperada

[Observações, cenários ou verificações que demonstram o comportamento. O plano detalha sequência, dependências e validações de implementação; não é necessário prescrever um teste para cada exemplo.]

## Riscos e restrições (quando relevantes)

- [Risco, restrição de acesso, dependência ou limite de evidência e seu impacto]

## Referências (quando relevantes)

- [Caminho portátil e seção/símbolo lidos]
