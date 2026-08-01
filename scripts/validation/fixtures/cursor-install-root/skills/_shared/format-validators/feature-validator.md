# PRD Format Validator

Validates PRD markdown against the **spec** skill template (`skills/sdd-spec/reference.md`).

**Default language:** pt-BR section titles and metadata labels. If manifest or invocation sets `artifact_language: en`, use the **English override** checklist below instead.

**Output paths:** `features/**/PRD/` or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/<repo-id>/features/**/PRD/` only (see `sdd-artifacts/STORAGE.md`). Root/flat `PRD/` and `docs/PRD/` are not valid Classic SDD paths.

## Validation levels

### Level 1: Structure - pt-BR (default)

**Required sections (in order, after title/metadata table):**

- `# PRD:` title
- Metadata table (`Sequência`, `Status`, `Prioridade`, `Complexidade`, `Repositório`, `Stack` - or English equivalents if `en` override)
- `## 1. Visão geral` (`### 1.1 Contexto`, `### 1.2 Objetivo`)
- `## 2. Critérios de aceite` (at least one `### CA` block with Dado/Quando/Então)
- `## 3. Escopo técnico (alto nível)`
- `## 4. Especificações técnicas`
- `## 5. Regras de negócio`
- `## 6. Requisitos funcionais`
- `## 7. Requisitos não funcionais`
- `## 8. Migrações de banco (se aplicável)` or clear N/A in section
- `## 9. Integrações (se aplicável)` or N/A
- `## 10. Tratamento de erros`
- `## 11. Casos de uso`
- `## 12. Cenários de teste`
- `## 13. Definição de pronto`
- `## 14. Próximos passos` (contains `/sdd-plan`)
- `## 15. Referências`
- `## 16. Notas`
- `## 17. Histórico de alterações`

### Level 1: Structure - English override

When `artifact_language` is `en` or user requested English in invocation:

- `## 1. Overview`, `### 1.1 Context`, `### 1.2 Objective`
- `## 2. Acceptance criteria` with Given/When/Then
- Sections 3-17 per English template in `reference.md` (Overview through Change history)
- Status **Ready for planning**

### Level 2: Content (recommended)

| Field / section | Rule | Severity |
|-----------------|------|----------|
| Metadata `Status` / `Status` | Not empty; pt: **Pronto para planejamento** (or EN: Ready for planning) | error |
| Metadata `Prioridade` / `Priority` | Alta/Média/Baixa or High/Medium/Low | error |
| Metadata `Complexidade` / `Complexity` | Baixa/Média/Alta or Low/Medium/High | error |
| Objective section | Non-empty, not bracket placeholder | error |
| Acceptance section | At least 2 CA/AC blocks | warning |
| Definition of done | At least 3 checkboxes | warning |
| No implementation code blocks | No fenced code with full implementations | error |

### Level 3: Quality (optional)

| Section | Rule | Severity |
|---------|------|----------|
| Context / Contexto | Minimum ~80 characters | info |
| Acceptance criteria | Dado/Quando/Então or Given/When/Then in each block | info |
| Próximos passos / Handoff | Contains `/sdd-plan` with PRD path | info |
| Identifiers in prose | Type/method names in English when cited | info |

## Usage in spec skill

**Integration point:** After generating PRD content, before writing the file.

**Flow:**

1. Detect language from invocation override or manifest `artifact_language`.
2. Validate at `level: content` with matching section list.
3. On errors: log section + expected + actual; offer regenerate or save with warning.
4. `canAutoFix = false` for structural issues.

## Output example

```text
Validating PRD format (pt-BR)...

PRD does not fully match template:
  ## 2. Critérios de aceite: only one CA block found
     Expected: at least 2 | Actual: 1

PRD saved with warnings - review manually.
```

---

**Version:** 1.1.0 (agent-dev-toolkit - pt-BR default artifacts)
