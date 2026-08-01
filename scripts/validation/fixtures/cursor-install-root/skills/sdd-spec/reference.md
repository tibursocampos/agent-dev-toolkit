# PRD template (spec skill)

Use this template when writing the PRD at the resolved path (repository or global). **Default:** all section titles and body text in **Brazilian Portuguese (pt-BR)**. English only if the user overrides in the skill invocation - see `sdd-artifact-language-pt-br.mdc`.

**Identifiers** (types, methods, APIs, paths, test names) stay in **English**. No implementation code in the PRD.

Storage: `STORAGE.md`. Pipeline (confirm-before-write, canonical paths, modes): `PIPELINE.md`.

## Filename and numbering

| Part | Rule |
|------|------|
| Folder | From manifest: `features/NNN-slug/USnn/PRD/` (Forma A default `US01`) or global under `<classic.path>/features/...` |
| Sequence | Next `NNN` (3 digits) after listing PRDs under `features/**/PRD/` only (workspace + global feature root for `<repo-id>`) |
| Slug | Short ASCII summary (kebab-case or snake_case; Portuguese words allowed) |
| Example (repo) | `features/002-exportacao-perfil/US01/PRD/002_exportacao_perfil_usuario.md` |
| Example (global) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/acme-payments-api/features/002-exportacao-perfil/US01/PRD/002_exportacao_perfil_usuario.md` |

## Storage and `.gitignore` (spec skill)

Before `Write` in **repository** mode, follow `STORAGE.md` § Repository mode - `.gitignore`: ensure SDD block includes **`/features/`**. Keep `/PRD/`, `/PLAN/`, `/docs/PRD/`, `/docs/PLAN/` in `.gitignore` **only as a safety net** (not active Classic SDD paths). **Do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets. Run this on first SDD write in a repo.

**Global** mode: no `.gitignore` changes (do not add features / memory-bank / PRD / PLAN patterns).

After choosing storage, write `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/<repo-id>/manifest.json` with `artifact_language`: `pt-BR` (default) or `en` (override).

## Product documentation language

If the PRD scope includes creating or updating **project** docs under `docs/` or README, **ask** the user pt-BR vs English before writing that documentation (separate from PRD artifact language).

---

## Document template (pt-BR - default)

Copy from the heading below through **Histórico de alterações**, then remove instructional comments in brackets.

```markdown
# PRD: [Nome da feature]

| Campo | Valor |
|-------|--------|
| **Sequência** | NNN |
| **Rastreamento** | [issue GitHub / slug / TBD] |
| **Versão** | 1 |
| **Data** | AAAA-MM-DD |
| **Status** | Pronto para planejamento |
| **Prioridade** | Alta / Média / Baixa |
| **Complexidade** | Baixa / Média / Alta |
| **Repositório** | [nome na raiz do git] |
| **Stack** | [.NET / Angular / outro] |

## 1. Visão geral

### 1.1 Contexto

[Por que é necessário? Situação atual e problema.]

### 1.2 Objetivo

[Resultado desejado após a implementação.]

## 2. Critérios de aceite

Use BDD: **Dado** / **Quando** / **Então** / **E**.

### CA1 - [Nome descritivo]

**Dado** [contexto inicial]
**Quando** [ação]
**Então** [resultado esperado]
**E** [condição extra opcional]

### CA2 - [Nome descritivo]

**Dado** [contexto inicial]
**Quando** [ação]
**Então** [resultado esperado]

## 3. Escopo técnico (alto nível)

### 3.1 Componentes a modificar

[Listar módulos, serviços ou áreas - sem código.]

### 3.2 Novos componentes

[Listar módulos, endpoints ou artefatos - sem código.]

### 3.3 Reuso sem alteração

[Peças existentes reutilizadas como estão.]

### 3.4 Fluxo de dados

[Fluxo textual ou descrição de diagrama entre componentes.]

## 4. Especificações técnicas

Descrever responsabilidades e contratos **sem** exemplos de código.

### 4.1 Domínio / entidades

[Campos, tipos, restrições no nível de negócio.]

### 4.2 DTOs / commands / queries

[Entradas e saídas - nomes opcionais, formatos obrigatórios.]

### 4.3 Handlers / serviços

[Responsabilidades de negócio.]

### 4.4 Acesso a dados

[Operações necessárias - padrões leitura/escrita.]

### 4.5 Eventos / mensageria

[Payloads publicados ou consumidos, se houver.]

### 4.6 Validações

[Regras e expectativas de erro.]

## 5. Regras de negócio

- **RN01**: [Regra]
- **RN02**: [Regra]

## 6. Requisitos funcionais

- **RF01**: [Requisito]
- **RF02**: [Requisito]

## 7. Requisitos não funcionais

- **RNF01**: [Performance, segurança, observabilidade, etc.]
- **RNF02**: [Requisito]

## 8. Migrações de banco (se aplicável)

**Migração necessária?** Sim / Não

Se sim: tabelas/colunas afetadas, impacto em dados existentes, reversibilidade.

## 9. Integrações (se aplicável)

### 9.1 Sistemas externos

[Listar APIs, filas, terceiros.]

### 9.2 Mudanças de contrato

[Alterações de payload ou API; breaking change Sim/Não com justificativa.]

## 10. Tratamento de erros

### TE01 - [Nome do cenário]

- **Situação**: [Quando ocorre]
- **Tratamento**: [Comportamento esperado]
- **Mensagem usuário/log**: [Intenção da mensagem]

## 11. Casos de uso

### CU01 - [Caso de uso principal]

**Ator:** [Usuário / sistema / serviço]

**Pré-condições:**

- [Condição]

**Fluxo principal:**

1. [Passo]
2. [Passo]
3. [Resultado esperado]

**Fluxos alternativos:**

- **FA01**: [Exceção ou ramo]

## 12. Cenários de teste

Espelhar critérios de aceite; incluir borda e falha.

### CT1 - [Caminho feliz]

**Dado** … **Quando** … **Então** …

### CT2 - [Validação / borda]

**Dado** … **Quando** … **Então** …

## 13. Definição de pronto

- [ ] Implementação alinhada a este PRD
- [ ] Testes unitários/integração para o novo comportamento
- [ ] .NET: xUnit, Moq, Shouldly; nomes `Should_<Result>_When_<Condition>`
- [ ] Migrações aplicadas e verificadas (se aplicável)
- [ ] Code review concluído
- [ ] Build passa local/CI

**Angular (se aplicável):** build, typecheck e testes de frontend passam.

## 14. Próximos passos

Este PRD está pronto para a skill **plan**:

```
/sdd-plan - <caminho-completo-do-prd>
```

## 15. Referências

- [Docs do projeto em `docs/`]
- [PRDs relacionados]
- [Links externos]

Diretrizes (lazy-load após sync; não colar corpos aqui):

- `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/dotnet-guidelines/clean-architecture.md`
- `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md`

## 16. Notas

**Riscos:**

- [Risco]

**Dependências:**

- [Dependência]

## 17. Histórico de alterações

| Data | Versão | Autor | Descrição |
|------|---------|--------|-------------|
| AAAA-MM-DD | 1 | [Nome] | Versão inicial |
```

---

## English override template

Use only when the user requests English in the skill invocation. Same structure; section titles in English (`## 1. Overview`, **Given**/**When**/**Then**, status **Ready for planning**). Set manifest `artifact_language` to `en`.

---

## Quality checklist (before handoff)

- [ ] User confirmed **sim** on canonical path (`PIPELINE.md` § Confirm before write)
- [ ] Path matches `features/**/PRD/NNN_*.md` or global `.../features/**/PRD/NNN_*.md` only
- [ ] No implementation code in the PRD; no production/test code edited in `spec` session
- [ ] Every acceptance criterion is testable
- [ ] Complexity and risks documented
- [ ] Body in pt-BR unless English override
- [ ] Type/method/API names in English where cited
- [ ] Status **Pronto para planejamento** (or **Ready for planning** if EN override)
- [ ] Handoff: `/sdd-plan - <full-prd-path>`
