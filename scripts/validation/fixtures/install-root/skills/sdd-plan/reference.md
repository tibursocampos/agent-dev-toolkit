# PLAN template (plan skill)

Use this template when writing the PLAN at the resolved path (repository or global). **Default:** section titles and body in **Brazilian Portuguese (pt-BR)**. English only on explicit skill invocation override - see `sdd-artifact-language-pt-br.mdc`.

**File paths** and **test names** in English. No implementation code blocks in the PLAN.

Storage rules: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/STORAGE.md`. Pipeline guards: `PIPELINE.md`.

## Filename and numbering

| Part | Rule |
|------|------|
| Folder | Same story as PRD: `features/NNN-slug/USnn/PLAN/` (or global under `<classic.path>/features/...`) |
| Sequence | Same `NNN` (3 digits) as the source PRD |
| Slug | Short ASCII summary (kebab-case or snake_case; Portuguese allowed) |
| Example (repo) | `features/002-exportacao-perfil/US01/PLAN/PLAN_002_exportacao_perfil_usuario.md` |
| Example (global) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/acme-payments-api/features/002-exportacao-perfil/US01/PLAN/PLAN_002_exportacao_perfil_usuario.md` |
| PRD link | Full path to PRD on disk (must be under `features/.../PRD/`) |

## Storage and `.gitignore` (plan skill)

If PRD is global, PLAN is global unless the user chooses repository storage. Before `Write` in **repository** mode, follow `STORAGE.md` § Repository mode - `.gitignore` (include `/features/`; keep `/PRD/` `/PLAN/` as safety net only; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets). Update manifest (`artifact_language`, folders). Do **not** write or update PLANs at repo-root `PLAN/`. **Global** mode: do not edit `.gitignore`.

## Product documentation language

If a step updates **project** `docs/` or README, the **plan** or **implement** skill must **ask** pt-BR vs English before writing that deliverable.

---

## Document template (pt-BR - default)

Copy from the heading below through **Checklist final**, then remove bracketed instructions.

```markdown
# PLAN: [Nome da feature]

| Campo | Valor |
|-------|--------|
| **PRD** | [caminho completo do PRD] |
| **Repositório** | [nome do PRD / raiz git] |
| **Stack** | [.NET / Angular / outro] |
| **Complexidade** | Baixa / Média / Alta |
| **Total de passos** | N (MVP) + M opcionais |
| **Progresso** | 0/N |

```
[⚪⚪⚪⚪⚪⚪⚪⚪] 0% (0/N)
```

## Objetivos

- [ ] O1: [Resultado mensurável ligado ao PRD]
- [ ] O2: [Resultado mensurável]
- [ ] O3: [Opcional]

## Árvore alvo (entregáveis)

[Listar arquivos ou módulos principais - só caminhos, sem código.]

```
[repo-root]/
├── [caminhos da exploração]
└── [tests]
```

## Estratégia de validação

- [ ] [Como a feature será verificada - unitário, integração, manual]
- [ ] .NET: xUnit, Moq, Shouldly; `Should_<Result>_When_<Condition>`
- [ ] Build passa local / CI
- [ ] (Opcional/.NET) Cobertura nos arquivos alterados ≥ 80% via `/test-coverage`

---

## Passos de implementação

### ⏳ PASSO 1: [Título curto]

**Status:** Pendente | **Concluído:** - | **Deps:** nenhuma | **Orçamento de tokens:** ~[k] | **Tempo:** [min]

**Entregáveis:**

- [ ] [Artefato concreto 1]
- [ ] [Artefato concreto 2]

**Arquivos:**

- `path/to/File.cs` (novo ou alterar)

**Tarefas:**

1. [Ação]
2. [Ação]

**Testes:**

- [ ] `Should_<Result>_When_<Condition>`
- [ ] [Cenário adicional]

**Aceite:**

- [ ] [Critério do CA do PRD]
- [ ] Build e testes direcionados passam

**Notas:** [Riscos; aviso se passo denso com 4+ arquivos]

---

### ⏳ PASSO 2: [Título curto]

**Status:** Pendente | **Concluído:** - | **Deps:** 1 | **Orçamento de tokens:** ~[k] | **Tempo:** [min]

[Repetir estrutura do bloco PASSO para cada baby step.]

---

### ⏳ PASSO N (Opcional - Qualidade): Verificação de cobertura

**Status:** Pendente | **Concluído:** - | **Deps:** [último passo funcional] | **Orçamento de tokens:** ~[k] | **Tempo:** [min]

**Quando aplicar:**

- [ ] Projeto .NET com `coverlet.collector` disponível (ou possível de instalar no escopo)

**Entregáveis:**

- [ ] Relatório de cobertura anexado/registrado no passo
- [ ] Lista de arquivos alterados com cobertura por arquivo (changed files)

**Arquivos:**

- `tests/...` (sem obrigatoriedade de novos arquivos)

**Tarefas:**

1. Executar `/test-coverage` com base branch adequada
2. Coletar métricas: new code, branch/overall, por arquivo alterado
3. Registrar resultado e gaps para follow-up (quando houver)

**Aceite:**

- [ ] Cobertura nos arquivos alterados ≥ 80% (meta: 100% quando viável)
- [ ] Se não aplicável, justificar explicitamente (ex.: stack sem .NET/coverlet)

**Notas:** Este passo é opcional para stacks sem suporte a `coverlet.collector`.

---

## Ordem de execução

**Caminho crítico:** 1 -> 2 -> … -> N

**Próximo passo:** PASSO 1 - [título]

---

## Mapa de componentes

| Camada / área | Caminhos |
|---------------|----------|
| Domain | [paths] |
| Application | [paths] |
| Infrastructure | [paths] |
| API / UI | [paths] |
| Tests | [paths] |

## Estratégia de testes

### Unitários

- [ ] [Cenário]

### Integração

- [ ] [Cenário]

### Manual (se necessário)

- [ ] [Cenário]

## Decisões técnicas

| Tópico | Decisão | Justificativa |
|--------|---------|---------------|
| [ex.: nome da propriedade] | [escolha] | [por quê] |

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| [Risco 1] | Baixo/Médio/Alto | [Ação] |

## Referências

- PRD: [caminho completo]
- Docs do projeto: `docs/...`
- Diretrizes (lazy-load; não colar corpos):
  - `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/clean-architecture.md`
  - `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md`

## Checklist final

- [ ] Todos os critérios de aceite do PRD mapeados em passos
- [ ] Cada passo cabe em uma sessão implement
- [ ] Dependências explícitas; sem ciclos
- [ ] Cenários de teste cobrem CA e bordas
- [ ] (Opcional/.NET) Passo final de qualidade com cobertura ≥ 80% via `test-coverage`
- [ ] Sem código de implementação embutido no PLAN
- [ ] Handoff: `/sdd-develop - <caminho-completo-do-plan> - Step 1`
```

---

## PLAN update protocol (implement skill)

Do **not** embed implement update rules inside the PLAN artifact. After each completed step, **`sdd-develop`** updates the same PLAN file per `skills/sdd-develop/reference.md` § PLAN update protocol (status **Concluído** / **Completed**, progress bar, **Próximo passo** / **Next step**, deliverable checkboxes). Do not edit progress manually during implementation except session recovery.

---

## Status legend

| Marker | Meaning |
|--------|---------|
| ⏳ PASSO N | Pending |
| 🔄 PASSO N | In progress (active implement session) |
| ✅ PASSO N | Completed |
| ❌ PASSO N | Blocked |

Use **Pendente** / **Concluído** / **Bloqueado** (or English equivalents) on the `**Status:**` line in pt-BR PLANs; emoji in the heading is optional.

**Implement skill:** step headings may use `STEP` or `PASSO`; match the PLAN file when updating.

---

## Baby-step sizing checklist

- [ ] No step with 4+ new files without splitting
- [ ] EF migration and mapping separated when both apply
- [ ] Handler, consumer, and tests not in the same step unless trivial
- [ ] Dense steps include a context warning for implement
- [ ] Optional docs step only when contract or visible behavior changes - **ask system doc language** (pt-BR vs English)

---

## Quality checklist (before handoff)

- [ ] User confirmed **sim** on canonical PLAN path (`PIPELINE.md` § Confirm before write)
- [ ] Canonical PRD on disk; PRD path and `NNN` match the PLAN filename
- [ ] Every PRD acceptance criterion appears in some step
- [ ] Step prose in pt-BR (unless English override)
- [ ] No full implementation code blocks in the PLAN
- [ ] Output path: `features/**/PLAN/PLAN_NNN_*.md` or global `.../features/**/PLAN/` only (not root `PLAN/`, ad-hoc `docs/`, or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/` outside `sdd/.../features/`)
- [ ] Handoff: `/sdd-develop - <full-plan-path> - Step 1`
- [ ] Initial progress `0/N`
