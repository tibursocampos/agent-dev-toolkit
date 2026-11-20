# PRD: [Feature or story name]

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

## Outcome and context

### Current need

[Problem or need motivating the work. For a brownfield change, describe relevant current behavior and cite available evidence.]

### Expected outcome

[Mudança observável para usuário, operação ou sistema.]

### Brownfield impact (when applicable)

- **Comportamento atual:** [o que foi observado e a evidência, ou o que ainda não foi verificado]
- **Mudança pretendida:** [resultado que o escopo aprovado deve produzir]
- **Riscos concretos:** [compatibilidade, dados, integração, operação ou `nenhum identificado` com base suficiente]

## Scope

### In scope

- [Capacidade ou comportamento incluído]

### Out of scope (when applicable)

- [Exclusão e motivo]

## Behavior and acceptance

Describe material functional and non-functional requirements in verifiable language. Use REQ/AC or other IDs when they help with references. Preserve equivalent criteria in existing documents. Use scenarios for success, error, or boundary paths that affect the outcome.

| Referência (opcional) | Comportamento esperado | Condição ou limite (quando relevante) | Como reconhecer o resultado |
|-----------------------|------------------------|--------------------------------------|-----------------------------|
| [ID ou omitir] | [comportamento] | [condição, falha ou limite] | [sinal observável] |

### Scenario — [observed behavior]

```gherkin
Dado [contexto relevante]
When [action or event]
Then [observable outcome]
```

### Rules, contracts, and integrations (when relevant)

[Relevant business rules, inputs, outputs, examples, failures, access expectations, compatibility, and contracts. For each material surface, consult `skills/_shared/sdd-artifacts/AUTHORING-CONTENT.md` and cite the specific canonical source when a contract lives in another document.]

## Material decisions and questions

Registre decisões necessárias para entender o comportamento ou iniciar implementação. Uma pergunta bloqueia somente o trabalho que depende de sua resposta; dúvidas menores permanecem visíveis e não interrompem trabalho independente.

| Question or decision and options | Status or answer | Affected work | Decision source |
|-------------------|-------------------|----------------------------------|--------------------------|
| [question or omit] | [open / decision and source] | [impact] | [portable path or omit] |

## Expected validation

[Observações, cenários ou verificações que demonstram o comportamento. O plano detalha sequência, dependências e validações de implementação; não é necessário prescrever um teste para cada exemplo.]

## Risks and constraints (when relevant)

- [Risco, restrição de acesso, dependência ou limite de evidência e seu impacto]

## References (when relevant)

- [Caminho portátil e seção/símbolo lidos, com limites da evidência]
