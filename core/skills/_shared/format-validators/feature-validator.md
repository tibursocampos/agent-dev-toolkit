# PRD Format Validator

Documents the PRD content checklist against the canonical template at `templates/sdd/PRD.md`. The executable structural gate is `scripts/validation/validate-prd.ps1`; this file is guidance, not an executable validator.

**Content-language:** Resolve via `agents/LANGUAGE.md` (invocation → preferences → manifest → else chat; `null` ≠ pt-BR). When content-language is **pt-BR**, use the pt-BR section titles checklist below. When `artifact_language: en` / English override, use the **English override** checklist.

**Output paths:** `features/**/PRD/` or `{{SDD_ROOT}}/<repo-id>/features/**/PRD/` only (see `sdd-artifacts/STORAGE.md`). Root/flat `PRD/` and `docs/PRD/` are not valid Classic SDD paths.

## Validation levels

### Level 1: Structure - pt-BR (when content-language is pt-BR)

**Executable structure:** `validate-prd.ps1` requires the PRD title and core metadata rows; Execution policy and Related headings; numbered sections 1–5 and 8–14; overview/context/objective; technical scope subsections 3.1–3.4; requirement subsections 4.1–4.4; at least one `REQ-NNN`, one `CA` heading, and a use-case block. It accepts the Portuguese canonical headings and the corresponding English headings where defined by the English override. It does not check heading order or prose quality.

**Conditional content:** sections 1.3 (success metrics), 1.4 (blast radius), 6 (database migrations), and 7 (integrations) may be omitted when they have no applicable content; the gate does not infer applicability from prose. The `### 4.5 EARS` subsection is optional; omit it when EARS adds no clarity. `## 5.1 Perguntas em aberto` is optional and should be omitted when there are no open questions. Within `## Related`, sibling rows are optional when the corresponding artifacts are unavailable; supplied paths must be portable. An API route described requires `### 7.3 Contrato observável de API`; other integrations do not.

### Level 1: Structure - English override

When `artifact_language` is `en` or user requested English in invocation:

- `## 1. Overview`, `### 1.1 Context`, `### 1.2 Objective`
- `## 2. Acceptance criteria` with Given/When/Then
- Sections 3-14 per the corresponding English headings in `templates/sdd/PRD.md` (Technical scope through Change history), preserving the same conditional and optional rules above
- Status **Ready for planning**

### Level 2: Content (recommended)

| Field / section | Rule | Severity |
|-----------------|------|----------|
| Metadata `Status` / `Status` | Not empty. New spec write: pt **Pronto para planejamento** (or EN: Ready for planning). After PLAN **Implementation status** `COMPLETED`: pt **Implementado** (or EN: Implemented). Any other value | error |
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

## Executable gate in spec and plan skills

**Integration point:** After writing the PRD and before handoff to `/sdd-plan`; `/sdd-plan` reruns the same deterministic gate on its source PRD.

**Flow:**

1. Detect content-language from `LANGUAGE.md` resolution (invocation → preferences → manifest → else chat).
2. Run `scripts/validation/validate-prd.ps1`; use this file as template/content review guidance, not as an executable substitute.
3. On errors, report missing REQ ids, CA headings, required template structure, or a triggered conditional section and correct the PRD before handoff.
4. The script checks structure and applicability triggers only; it does not establish content quality, requirement-to-CA traceability, or host activation behavior.

## Output example

```text
Validating PRD format (pt-BR)...

PRD does not fully match template:
  ## 2. Critérios de aceite: only one CA block found
     Expected: at least 2 | Actual: 1

PRD saved with warnings - review manually.
```

---

**Version:** 1.2.0 (agent-dev-toolkit — content-language via `LANGUAGE.md`; no hard-coded artifact locale)
