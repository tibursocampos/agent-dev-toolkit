# PRD Structure Diagnostic

Optional PRD authoring and diagnostic guidance against `templates/sdd/PRD.md`. `scripts/validation/validate-prd.ps1` reports differences from a legacy structure; neither this file nor that script is a handoff or implementation gate. The active `sdd-spec` contract controls whether a PRD is ready.

**Content-language:** Resolve via `agents/LANGUAGE.md` (invocation → preferences → manifest → else chat; `null` ≠ pt-BR). When content-language is **pt-BR**, use the pt-BR section titles checklist below. When `artifact_language: en` / English override, use the **English override** checklist.

**Output paths:** `features/**/PRD/` or `{{SDD_ROOT}}/<repo-id>/features/**/PRD/` only (see `sdd-artifacts/STORAGE.md`). Root/flat `PRD/` and `docs/PRD/` are not valid Classic SDD paths.

## Validation levels

### Optional legacy-structure diagnostic - pt-BR (when content-language is pt-BR)

When run, `validate-prd.ps1` checks for a legacy shape: PRD title and metadata rows; Execution policy and Related headings; numbered sections 1–5 and 8–14; overview/context/objective; technical scope subsections 3.1–3.4; requirement subsections 4.1–4.4; a `REQ-NNN`, `CA` heading, and use-case block. It recognizes Portuguese headings and the corresponding English headings defined by the diagnostic. A mismatch is informational for the workflow: inspect whether behavior, acceptance, scope, or a relevant contract is actually unclear; equivalent content does not need rewriting to satisfy this structure.

The diagnostic also checks conditional legacy structure: sections 1.3 (success metrics), 1.4 (blast radius), 6 (database migrations), and 7 (integrations); its trigger rules may not reflect context conveyed elsewhere. EARS, open-question sections, sibling rows, and API-contract subsections are optional authoring choices. Review substance and applicability directly rather than treating a diagnostic trigger as a gate.

### Optional legacy-structure diagnostic - English override

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
| Acceptance section | Use clear observable acceptance where it helps; no fixed block count | guidance |
| Definition of done | Keep implementation completion evidence in the PLAN; no fixed checkbox count | guidance |
| No implementation code blocks | No fenced code with full implementations | error |

### Level 3: Quality (optional)

| Section | Rule | Severity |
|---------|------|----------|
| Context / Contexto | Minimum ~80 characters | info |
| Acceptance criteria | Dado/Quando/Então or Given/When/Then in each block | info |
| Próximos passos / Handoff | Contains `/sdd-plan` with PRD path | info |
| Identifiers in prose | Type/method names in English when cited | info |

## Optional diagnostic use

Run `validate-prd.ps1` only when explicitly requested or when its output helps investigate a concrete issue. `sdd-spec` and `sdd-plan` do not require it before handoff, and planning does not rerun it automatically.

**Flow:**

1. Detect content-language from `LANGUAGE.md` resolution (invocation → preferences → manifest → else chat).
2. If the diagnostic is run, use this file to understand its checks and inspect any reported mismatch.
3. Correct only omissions that materially affect behavior, acceptance, scope, or relevant contracts. Do not rewrite equivalent content solely to satisfy the diagnostic.
4. The script does not establish content quality, requirement traceability, or host activation behavior.

## Output example

```text
Validating PRD format...

PRD does not fully match template:
  ## 2. Critérios de aceite: only one CA block found
     Expected: at least 2 | Actual: 1

PRD saved with warnings - review manually.
```

---

**Version:** 1.2.0 (agent-dev-toolkit — content-language via `LANGUAGE.md`; no hard-coded artifact locale)
