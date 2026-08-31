# Code review - report template and checklists

Use when writing the final report for the `code-review` skill. Keep the report in **Brazilian Portuguese (pt-BR)** (technical terms may stay in English). Replace bracketed placeholders.

---

## SDD artifact resolution

Run in **step 0.5** before scoping the diff. Load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/STORAGE.md`. On Windows, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/` is `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/`.

### Checklist

1. **Target repo** - open workspace is the project under review (not this toolkit repo unless that is the subject).
2. **`<repo-id>`** - per `STORAGE.md`: `git remote get-url origin` -> slug; else workspace root basename; reuse `repo_id` from manifest when present.
3. **Manifest** - read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/<repo-id>/manifest.json` when it exists and `workspace_root` (normalized separators, case-insensitive on Windows) matches the open workspace -> derive classic feature root from `STORAGE.md` (repository `features/` or global `.../features/`).
4. **Glob** (parallel) - **only** under `features/` (never root/flat `PRD/` or `PLAN/`):

   | Location | Patterns |
   |----------|----------|
   | Workspace | `features/**/PRD/*.md`, `features/**/PLAN/PLAN_*.md`, `docs/features/**/PRD/*.md`, `docs/features/**/PLAN/PLAN_*.md` |
   | Global | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/<repo-id>/features/**/PRD/*.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/<repo-id>/features/**/PLAN/PLAN_*.md` |

5. **Extract `NNN`** - first three digits from PRD filename (`001_...md`) and from PLAN (`PLAN_001_...md`).
6. **Pair** - match PRD and PLAN with the same `NNN`.
7. **Select one pair** (first match wins):

   | Priority | Signal |
   |----------|--------|
   | 1 | User passed explicit PRD or PLAN path in invocation |
   | 2 | PLAN header field **PRD** points to a discovered PRD path |
   | 3 | `NNN` or feature slug aligns with current branch name |
   | 4 | Single pair after pairing |
   | 5 | Ask once in pt-BR - numbered list of PRD + PLAN paths |

8. **Read** selected PRD and PLAN before SDD traceability (step 2).
9. **Report** - always record full paths used (workspace-relative or absolute global).

### Outcomes

| Result | Action |
|--------|--------|
| One pair found | Proceed with SDD traceability |
| No artifacts after full search | Report **Limitação SDD** (technical/guidelines review only); do not state PRD/PLAN "do not exist" |
| Multiple ambiguous pairs | Ask user once; then proceed |

---

## Report template

```markdown
# Code review - [Nome da feature]

## Resumo executivo

**Decisão:** Aprovado | Aprovado com ressalvas | Alterações necessárias

| Métrica | Valor |
|---------|-------|
| Aderência ao PRD | [ex.: 4/4 critérios] |
| Status do PLAN | [ex.: 6/6 passos concluídos] |
| SDD | [PRD/PLAN encontrados - caminhos] ou **Limitação SDD** (busca completa sem artefatos) |
| Arquivos revisados | [N] |
| Build / testes | [Passou / Falhou / Não executado] |
| Cobertura (código novo) | [X% - Passou ≥ 80% / Abaixo / Não aplicável] |
| Críticos | [0] |
| Importantes | [N] |
| Nice-to-have | [N] |

[Um parágrafo: escopo, principais achados, recomendação.]

---

## Verificação do PLAN (SDD)

_Omitir esta seção somente se step 0.5 registrou **Limitação SDD**._

**PLAN:** [caminho completo]

- Progresso: [X/N] - [consistente | inconsistências listadas]
- Passos concluídos: [lista]
- Pendente / desvio: [lista ou Nenhum]

---

## Aderência ao PRD (SDD)

_Omitir esta seção somente se step 0.5 registrou **Limitação SDD**._

**PRD:** [caminho completo]

### Critérios de aceite

| Critério | Status | Evidência |
|----------|--------|-----------|
| [CA1] | Atendido / Parcial / Ausente | [arquivo, teste] |

### Regras de negócio

| Regra | Status | Local |
|-------|--------|-------|
| [RN01] | Atendida / Ausente | [tipo.método] |

---

## Arquivos revisados

- [caminho] - [nota breve]

---

## Pontos positivos

- [Boas práticas observadas]

---

## Problemas críticos (bloqueantes)

### [Título]

- **Arquivo:** `caminho:linha`
- **Categoria:** Segurança | Bug | Breaking change
- **Problema:** [o que está errado]
- **Impacto:** [por que bloqueia merge]
- **Correção sugerida:** [passos concretos]

---

## Problemas importantes (não bloqueantes)

### [Título]

- **Arquivo:** `caminho:linha`
- **Problema:** [o que melhorar]
- **Sugestão:** [como]

---

## Nice-to-have

- [Melhorias opcionais]

---

## Testes

- **Unitários:** [passou/falhou, escopo]
- **Integração:** [passou/falhou, escopo]
- **Lacunas:** [cenários não cobertos]
- **Cobertura (código novo / arquivos alterados):** [X% - Passou ≥ [threshold]% / Abaixo do target / Não executado]
- **Cobertura geral (branch):** [Y% - informativo]
- **Meta:** 100% (mínimo aceitável: [80]% quando target aplicável)
- **Fonte:** `/test-coverage` - [colar bloco do relatório ou N/A]

---

## Segurança

- [ ] Sem secrets hardcoded
- [ ] Validação de entrada em dados externos
- [ ] Sem dados sensíveis em logs
- [ ] Acesso a dados parametrizado (sem concatenação SQL)

Problemas: [Nenhum | listados]

---

## Performance

- [ ] Sem N+1 óbvio no código alterado
- [ ] Async em trabalho I/O-bound
- [ ] Sem loops/alocações ilimitados em hot paths

Problemas: [Nenhum | listados]

---

## Oportunidades de refatoração (opcional)

| Prioridade | Área | Benefício |
|------------|------|-----------|
| Média | [método/classe] | [legibilidade / testabilidade] |

---

## Recomendação final

**Decisão:** [Aprovado | Aprovado com ressalvas | Alterações necessárias]

**Obrigatório antes do merge:**

1. [Ação ou Nenhuma]

**Recomendado após o merge:**

1. [Ação ou Nenhuma]

**Próximos passos do autor:**

- [ ]
```

---

## Code analysis focus

| Area | Focus |
|------|--------|
| Correctness | Logic, edge cases, error handling |
| Architecture | Layer boundaries, DI, no domain -> infrastructure leaks |
| Tests | Behavior covered; meaningful assertions; no trivial tests |
| Security | Secrets, injection, authz, sensitive logs |
| Performance | N+1, unbounded work, missing async where I/O |
| Maintainability | Naming, method size, duplication; magic values - see `csharp-patterns.md` |

## Verification commands

| Stack | Commands |
|-------|----------|
| .NET | `dotnet build`, `dotnet test` (scoped if large) |
| .NET coverage | `/test-coverage` when PRD, PLAN, or user sets a target (default **80%** on changed production files) |
| Node | `npm run build`, `npm test` per project scripts |

When a coverage target applies: run `test-coverage` before final decision; paste summary into report section Testes. **Fail** below threshold -> **Changes required** unless user documents an accepted exception.

---

## .NET review checklist (condensed)

**Structure**

- [ ] Clean Architecture layers respected
- [ ] Namespaces and folder layout consistent
- [ ] Single responsibility; focused methods
- [ ] **C# structure/formatting** per `csharp-patterns.md` (blocking when violated): one type per file; signatures/invocations (5 params / 150 chars); follow existing patterns; named constants (no magic literals, PascalCase; shared files only when reusable); public methods before private, alphabetical within blocks

**C#**

- [ ] Explicit types; nullable reference types where enabled
- [ ] Async/await for I/O; `CancellationToken` propagated
- [ ] No unjustified `dynamic` or blocking `.Result` / `.Wait()`
- [ ] Resources disposed (`using`, `IAsyncDisposable`)

**Tests**

- [ ] xUnit + Moq + Shouldly
- [ ] Names: `Should_<Result>_When_<Condition>`
- [ ] Arrange / Act / Assert structure with `// Arrange`, `// Act`, `// Assert` comments
- [ ] Edge cases and failure paths where behavior changed

**EF / data**

- [ ] No obvious N+1; `AsNoTracking` for read-only queries when appropriate
- [ ] Migrations safe (up/down, indexes, no unintended data loss)

---

## Angular / frontend checklist (when applicable)

- [ ] No unjustified `any`; typed inputs and API models
- [ ] HTTP errors handled; services return typed results
- [ ] Build: `npm run build` (or project script)
- [ ] Tests: `npm test` when present

---

## Code smell quick scan

| Smell | Look for |
|-------|----------|
| Long method | > ~30 lines in changed code |
| Large class | Multiple unrelated responsibilities |
| Duplication | Same logic in 2+ places |
| Feature envy | Method mostly uses another type’s data |
| Primitive obsession | Many primitives where a value object fits |

---

## Approval criteria

**Approved:** PRD/PLAN satisfied; no critical issues; build/tests pass or user accepts documented gaps; when a coverage target applies (PRD, PLAN, user, or `test-coverage` run), **new code** line coverage on changed production files is **≥ threshold** (default **80%**).

**Approved with reservations:** Minor issues or PLAN cosmetic drift; no security or correctness blockers; coverage at or above threshold with some changed files below **100%** target (document gaps).

**Changes required:** Security vulnerability; broken behavior; missing PRD scope; build/test failure; critical architecture violation; **coverage below threshold** on changed production files when a target applies.

---

## Coverage gate (.NET)

Run when PRD, PLAN, or user requires coverage evidence:

```text
/test-coverage - <base-branch> - threshold 80
```

| Result from test-coverage | code-review decision |
|---------------------|
| Pass (≥ threshold) | May approve if all other criteria met |
| Fail (&lt; threshold) | **Alterações necessárias** |
| Not run, target required | Note limitation; ask user to run or waive explicitly |
| Not applicable (no .NET / no target) | Omit coverage rows in § Testes |

---

## Multi-angle mode

Optional enrichment of the same report template. **No silent default:** if the invoke omits both single and multi, the skill **must ask** (pt-BR) before step 0.5 - see `SKILL.md` § Trigger and § 0.25. O3 may suggest review; never auto-blocks the pipeline.

### Invoke examples

```text
/code-review
/code-review - single
/code-review - multi-angle
/code-review - ângulos: qualidade, aceite, segurança
```

Bare `/code-review` -> ask mode (1 single / 2 multi-ângulo). Subset allowed, e.g. `ângulos: qualidade, segurança`. Synonyms: `multi-ângulo`, `multi-angle`, `single`, `single-angle`, `simples`.

### Checklist per angle

**Quality (qualidade)**

- [ ] Correctness / edge cases / error handling in the diff
- [ ] Architecture and layer boundaries
- [ ] Meaningful tests for changed behavior
- [ ] Performance smells (N+1, unbounded work, missing async)
- [ ] Maintainability (naming, method size, duplication, magic values)

**Acceptance (aceite)**

- [ ] PRD acceptance criteria mapped to evidence in the diff
- [ ] PLAN completed steps match deliverables; no silent drift
- [ ] Business rules from PRD present where in scope
- [ ] Gaps flagged as important or critical per severity (not a separate gate)

**Security (segurança)**

- [ ] AuthZ / AuthN assumptions for new endpoints or jobs
- [ ] Input validation / injection (SQL, command, template)
- [ ] Secrets and PII handling (no hardcoded secrets; no sensitive logs)
- [ ] Dangerous defaults - hint source: `_shared/agents/prompts/security.md`
- [ ] Evidence-based findings only; state what to verify if data is missing

### Merging Task outputs into the report

1. Load `SPAWN.md`; consult capability `subagents`. When `native`: spawn one Task per requested angle (parallel, ≤3); when `none` or Task unavailable → **fallback** sequential **in-parent** angles (never hard-fail). Parent keeps the default flow for build/test/coverage.
2. Deduplicate overlapping findings; keep the strongest severity and clearest `path:line`.
3. Map into the existing template sections:
   - Blocking bugs / security / broken PRD scope -> **Problemas críticos**
   - Non-blocking quality, PLAN/PRD drift, gaps -> **Problemas importantes**
   - Optional polish -> **Nice-to-have**
4. Fold security-angle notes into § Segurança; acceptance into § Aderência ao PRD / Verificação do PLAN; quality into analysis sections and positives.
5. Apply the **same** decision matrix and coverage gates - multi-angle does not change Approved / Approved with reservations / Changes required semantics.
