# Usando skills

Invoque as skills do toolkit após um sync bem-sucedido. Prefira **ids de skill** (kebab-case em `core/skills/`). O **id** é estável entre hosts; o prefixo é específico do host (`/`, `$`, `use skill`, ferramenta `skill` do OpenCode ou `name` da skill no OpenHands). Compat: `use skill <id>` ou linguagem natural alinhada à `description` da skill.

Após qualquer sync, invoque a skill **`help-skills`** para o catálogo estático instalado (`CATALOG.md` + `OPERATOR.md`) — não carregue cada `SKILL.md`.

**Não é invoke de skill:** Codex `/hooks` e Grok `/hooks-trust` são UI de trust de hooks. Não existe flag de produto Codex `$skill --menu` — `$` / `/skills` é o picker nativo de skills.

## Matriz canônica de invoke

| Host | Path das skills (live, típico) | Forma explícita | Exemplo |
|------|--------------------------------|-----------------|---------|
| Cursor | `~/.cursor/skills` | `/id` | `/help-skills` |
| Claude | `~/.claude/skills` | `/id` | `/sdd-spec` |
| Codex | `~/.codex/skills` (+ opcional `~/.agents/skills`) | `$id` | `$help-skills` |
| Copilot | `~/.copilot/skills` ou `<repo>/.github/skills` | `/id` (+ `/skills reload` após sync) | `/dotnet-developer` |
| OpenCode | `~/.config/opencode/skills` | ferramenta `skill` | `skill({ name: "help-skills" })` |
| Antigravity | `~/.gemini/config/skills` | `use skill id` ou `/id` | `use skill sdd-plan` |
| Grok | `~/.grok/skills` | `/id` | `/help-skills` |
| ZCode | `~/.zcode/skills` | `$id` | `$help-skills` |
| Hermes | `~/.hermes/skills` | `/id` | `/help-skills` |
| OpenHands | `.agents/skills` (projeto) / `~/.agents/skills` (usuário) | `name` da skill (o agente carrega quando for relevante) | `help-skills` |

## Especialistas em paralelo (padrão)

Após o sync, o router publicado pede aos agentes que prefiram **subagentes especialistas em paralelo** para planejamento, execução multi-facet, análise ou dúvidas não triviais, mantendo **esta sessão como pai**. Trabalho trivial / single-path fica no pai.

- **`needs_*` → roster** — quais papéis spawnar: [ROSTER.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/skills/_shared/agents/ROSTER.md)
- **`model` no Task** — omitir por padrão (o filho herda o modelo da sessão pai); ver [SUBAGENT-MODEL.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/skills/_shared/agents/SUBAGENT-MODEL.md)
- **Pai orquestrador** — esta sessão fica enxuta (metas, gates, paths, receipts); **sem código da aplicação** no pai quando há especialistas
- **Caps** — filhos `*-developer` **≤ 2**; paralelo `orchestrate-*` **≤ 4** (em ondas se houver mais). Fallback com `subagents=none`: no pai, nunca hard-fail — [docs/SPAWN.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/SPAWN.md) · [Arquitetura](../architecture/)
- **Superfícies de idioma** — chat do usuário + artefatos persistidos = idioma do chat; prompts de filhos e receipts para agentes = **en-US** ([LANGUAGE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/skills/_shared/agents/LANGUAGE.md))

## Pré-requisitos

1. Sync de pelo menos um agente — ver [Começar](../get-started/).
2. **Projeto da aplicação** aberto nesse agente (não só este repositório do toolkit).
3. Opcional: validação com `toolkit.ps1 -Action Validate -Agent <id>`.

## Qual trilha / skill?

```mermaid
flowchart TD
  Start([Nova tarefa]) --> Q1{Várias stories / brownfield / precisa de especialistas?}
  Q1 -->|Sim| FC[Orchestrated Delivery]
  Q1 -->|Não| Q2{Feature única de complexidade média ou alta?}
  Q2 -->|Sim| SDD[Classic SDD]
  Q2 -->|Só item de backlog informal| FB[Backlog Refine]
  Q2 -->|Não| Q3{Correção pequena em uma área?}
  Q3 -->|Sim .NET| NET[dotnet-developer]
  Q3 -->|Sim outra stack| STACK[skill de stack ou developer]
  Q3 -->|Incerto| DEV[router developer]
  FC --> S0["/memory-bank-init Step 0"]
  S0 --> O1["/orchestrate-analyze"]
  O1 --> ArchGate{"Projeto novo / needs_domain (modelagem de domínio)?"}
  ArchGate -->|Sim| Confirm["papel architect: minuta → sim (confirmar) → ARCH"]
  ArchGate -->|Espelho brownfield| O2
  Confirm --> O2["/orchestrate-deliver"]
  O2 --> O3["/orchestrate-develop ou /sdd-develop"]
  FB --> Refine["/refine-story"]
  Refine --> AorC[Depois Classic SDD ou Orchestrated Delivery]
  SDD --> Spec["/sdd-spec"]
  Spec --> Plan["/sdd-plan"]
  Plan --> Impl["/sdd-develop um passo"]
  NET --> DoneNet[Mudança de código]
  STACK --> DoneNet
  DEV --> STACK
  Impl --> DoneSdd[Mudança de código]
  O3 --> DoneSdd
  AorC --> SDD
  AorC --> FC
  DoneNet --> Post
  DoneSdd --> Post
  Post[Depois do código] --> CR["/code-review"]
  CR --> TC["/test-coverage opcional .NET"]
  TC --> Commit["/commit"]
  Commit --> Push["/push"]
  Push --> PR["/open-github-pr"]
```

**Resumo ASCII:**

```
Nova tarefa
  ├─ Várias stories / brownfield?        -> Orchestrated Delivery: memory-bank-init → analyze → deliver → develop
  ├─ Projeto novo / precisa domínio?     -> Orchestrated Delivery: analyze (+ confirmação architect) antes de develop
  ├─ Feature única média/alta?           -> Classic SDD: sdd-spec → sdd-plan → sdd-develop
  ├─ Item de backlog informal?           -> Backlog Refine: refine-story → checklist? → Classic ou Orchestrated
  ├─ Mudança pequena de stack?           -> *-developer ou developer
  └─ Depois do código                    -> code-review → test-coverage? → commit → push → open-github-pr
```

### Trilhas de trabalho

| Trilha | Quando | Pipeline | Notas |
|--------|--------|----------|-------|
| **Classic SDD** | Uma feature clara | `sdd-spec` → `sdd-plan` → `sdd-develop` | Sem memory-bank obrigatório |
| **Backlog Refine** | Bug/story informal | `refine-story` → `split-story-checklist` opcional → Classic ou Orchestrated | Story sizing + persona/JTBD opcional (só User Stories); coluna Product intent no FEATURE |
| **Orchestrated Delivery** | Várias stories / brownfield / domínio em projeto novo (greenfield) | `memory-bank-init` → analyze → deliver → develop | Analyze pode pedir confirmação do architect; deliver/develop reusam Classic SDD |

Mesmo fluxo de chamada das skills; contratos internos (REQ, validate, CHANGE, EVD, STATE, TRACE, selective retrieval, invocation/provenance, PLAN-LEDGER) são gates/artefatos a mais — não um segundo toolkit. Skills invocáveis usam lazy-load (`SKILL.md` + `reference.md` / `references/*` opcional); contrato: [SKILL-REFERENCE-RETRIEVAL.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/skills/_shared/sdd-artifacts/SKILL-REFERENCE-RETRIEVAL.md). SQLite/FTS não é entrega.

**Invocation / provenance / `source_context`:** `direct` vs `orchestrated`, `agreed` vs `invented`, e quando chamar `read-sdd-artifact` — [docs/domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md) (Invocation / provenance / `read-sdd-artifact`). Normas de qualidade de produto em `_shared/backlog-item-types/` (carregue **um** arquivo por vez).

Modo orchestrator (pai enxuto; especialistas fazem o trabalho pesado): padrão `always` — [docs/guides/08-orchestrator-mode.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/guides/08-orchestrator-mode.md).

Trabalho de domínio em projeto novo (greenfield): prefira Orchestrated Delivery. Assim `orchestrate-analyze` pode acionar o papel **architect** do roster (não é skill id). Ele gera uma minuta ARCH; você responde **sim** (confirmar); o ARCH fica aprovado. Só então os implementadores carregam um estilo de arquitetura e a camada de stack correspondente. Em brownfield, use descoberta primeiro: espelhe o ARCH existente.

## Invocar por agente

A skill **`help-skills`** funciona em **todos** os adapters sincronizados (não só Codex). Use a forma do host na matriz acima.

### Cursor

Skills: `~/.cursor/skills/<id>/SKILL.md`. Rules: `~/.cursor/rules/*.mdc`. Router: `AGENTS.md`.

| Ação | Exemplo |
|------|---------|
| Menu slash | `/sdd-spec` |
| Com args | `/sdd-plan - path/to/PRD.md` |
| Router de stack | `/developer` |
| Catálogo | `/help-skills` |
| Orchestrated Delivery Step 0 | `/memory-bank-init` |

Também Customize → Skills. Aceite os hooks na UI do Cursor uma vez se solicitado (fora de CI).

### Claude Code

Skills em `~/.claude/skills/` (ou `.claude/` do projeto). Router: `CLAUDE.md`. Invoque com `/id` (ex.: `/sdd-spec`, `/help-skills`).

### GitHub Copilot

Sync com `-Mode user` ou `-Mode repo`:

| Mode | Skills / instruções |
|------|---------------------|
| `user` | `~/.copilot/skills`, `instructions/`, `copilot-instructions.md` |
| `repo` | `<repo>/.github/skills`, … |

Invoque com `/id`. Após o sync, rode **`/skills reload`**. Id do catálogo: `help-skills`.

### Codex

O Codex é **dual-root** para packaging vs rules. **O path do plugin sozinho não alimenta `$`.**

| Superfície | Local |
|------------|-------|
| Skills do plugin + CATALOG + OPERATOR | Sob `InstallRoot/plugin` (packaging) |
| **Discovery `$`** | Live `~/.codex/skills` (espelho em InstallRoot) |
| Rules (Publish-Policy) | `InstallRoot/rules/*.md` |
| Produto / AGENTS / hooks | `InstallRoot` (live `~/.codex`) |
| UserScope opcional (opt-in) | Fixture `InstallRoot/.agents/skills` · live `~/.agents/skills` |

Invoque com **`$id`** (ex.: `$help-skills`). O picker nativo `$` / `/skills` é o menu do produto — não uma flag `--menu`. Aceite hooks com Codex `/hooks` após install real (UI de trust, não invoke de skill).

### OpenCode

Skills: `~/.config/opencode/skills`. Invoque via a ferramenta **`skill`**: `skill({ name: "help-skills" })`. Plugins JS em `plugins/` (`tool.execute.before` path/secrets throw). Roster: `InstallRoot/agents/` (`agents=true`).

### Grok

Path live esperado: `~/.grok/skills`. Invoque com `/id` (ex.: `/help-skills`). Trust de hooks via `/hooks-trust` se necessário (não é invoke de skill). PreToolUse path/secrets; `Publish-Agents` → `InstallRoot/agents/`.

### ZCode

Skills: `~/.zcode/skills`. Invoque com **`$id`** (ex.: `$help-skills`). Atualize em Settings → Skills se o produto exigir. PreToolUse path/secrets.

### Antigravity

Skills: `~/.gemini/config/skills`. Invoque com **`use skill <id>`** ou `/id` (ex.: `use skill sdd-plan`). PreToolUse path/secrets em `config/hooks`.

### Hermes

Skills: `~/.hermes/skills`. Invoque com **`/id`** (ex.: `/help-skills`). Oficial: cada skill instalada vira comando slash. Hooks: plugin `agent-dev-toolkit-guard` + shell `agent-hooks` path/secrets (`config.yaml` só chaves gerenciadas). Subagentes: ferramenta `delegate_task` do host (`subagents=native`). Sem roster `agents/*.md` (`agents=false`). Nunca SOUL / tokens / gateway.

### OpenHands

Skills de projeto: `.agents/skills`. Skills do usuário live: `~/.agents/skills`. O agente carrega a skill pelo `name` / `description` quando for relevante (`triggers` opcionais no frontmatter). Shell `pre_tool_use` + `guard_pre_tool.sh` (fail-closed). Canvas não é spawn de subagente — `subagents=none`; fallback SPAWN no pai. O roster publicado `.agents/agents/*.md` é SDK/plugin, não Canvas Profile.

Layouts de publicação por agente: [Adaptadores](../adapters/). Todos publicam `help-skills` + o pack skills-catalog.

## Fluxos comuns

Exemplos de fluxo usam **ids de skill**. Prefixe com a forma do seu host (`/`, `$`, `use skill`, ferramenta `skill` do OpenCode ou `name` da skill no OpenHands).

### Classic SDD

```text
sdd-spec
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step N
read-sdd-artifact - <portable-features-path>   # opcional: normaliza → source_context
```

Uma sessão de develop = **um** passo do PLAN. Contratos internos (REQ, validate, CHANGE em brownfield, EVD/STATE, TRACE, invocation/provenance) rodam nos mesmos skill ids. Use `read-sdd-artifact` quando o handoff precisar de envelope tipado `source_context` (não é um quarto estágio de autoria). Detalhe: [docs/domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md).

### Backlog Refine — modos + checklist

```text
refine-story - feature    # User Story / Bug
refine-story - tech       # Technical Story (TSnn)
refine-story - split      # reformatar passos → pronto para checklist
split-story-checklist - <story-or-backlog-path>
```

O modo é **obrigatório** (`feature` \| `tech` \| `split`). Omitir → a skill pergunta uma vez; não assuma `feature`. Modos são playbooks na mesma trilha Backlog Refine — não novas trilhas slash. Scorecard/checklist carregam **um** arquivo de `_shared/backlog-item-types/` por vez.

### API standards vs clientes tipados

```text
api-standards                 # REST / versionamento / erros / naming / higiene de segurança (agnóstico)
api-standards - versioning    # foco opcional: rest | versioning | errors | naming | security
api-integrate - <openapi>     # OpenAPI → clientes tipados / DTOs
```

Use **`api-standards`** para revisão de design (só packing; sem contratos de empresa). Use **`api-integrate`** quando precisar de clientes gerados a partir de OpenAPI.

### Orchestrated Delivery

```text
memory-bank-init
orchestrate-analyze
```

Depois `orchestrate-deliver` e `orchestrate-develop` (ou `sdd-develop`). Orquestradores **reusam** contratos Classic SDD; não os substituem. Antes do backlog **sim**, O1 pode desafiar FEATURE/US/PRD rasos (qualidade de artefato de produto) — veja [docs/domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md#product-artifact-quality-backlog-item-types).

### Mudança pequena de stack

```text
developer
```

ou `dotnet-developer`, `react-developer`, `python-developer`, …

### Depois da implementação

```text
code-review
commit
push
open-github-pr
```

PRs de feature: `feature/*` (ou `feat/*`) atual → `develop`. Modo release: `develop` → `master`/`main`. Prefira `open-github-pr` à UI web quando `gh` estiver disponível.

## Catálogo de skills (resumo)

Pastas canônicas em `core/skills/` (**40 skills** + `_shared`). SoT do agente: skill `help-skills` → `_shared/skills-catalog/CATALOG.md` (mapa) + `OPERATOR.md` (confirmações, opções, nuances — não carregue cada `SKILL.md`). Packs em `_shared/` não são skills invocáveis. **Não** existe skill `architect` — o caminho architect é acionado a partir de `orchestrate-analyze`.

| Grupo | Skills |
|-------|--------|
| **Classic SDD** | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` |
| **Backlog Refine** | `refine-story`, `split-story-checklist` |
| **Orchestrated Delivery** | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| **Stack** | `developer` + `dotnet-`, `java-`, `react-`, `react-native-`, `angular-`, `vue-`, `blazor-`, `electron-`, `javascript-`, `python-developer` |
| **Design / Blip** | `impeccable`, `blip-plugin-developer` |
| **Docs RAG** | `document-plan`, `document-implement` |
| **Operacional** | `help-skills`, `code-review`, `commit`, `push`, `open-github-pr`, `refactor`, `repair-dotnet-build`, `test-coverage`, `ef-add-migration`, `scaffold-message-handler`, `api-integrate`, `api-standards`, `performance-profile`, `containerize`, `i18n-manager` |

### Expectativas do operador (visão geral)

| Área | O que será pedido / opções |
|------|----------------------------|
| Git (`commit` / `push` / `open-github-pr`) | Confirmar mensagem de commit; confirmar push; modo PR feature vs release; confirmar título/corpo; **sempre** perguntar auto-merge. Detalhe: [git-ops.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/git-ops.md) |
| `code-review` | Escolher single vs multi-angle (sem default silencioso) |
| Orchestrated Delivery | Memory-bank Step 0; backlog **sim**; rascunho ARCH do architect → **sim** em greenfield / `needs_domain` |
| `refine-story` | Escolher modo `feature` \| `tech` \| `split` (sem default silencioso) |
| `api-standards` vs `api-integrate` | Design/padrões → `api-standards`; OpenAPI → clientes → `api-integrate` |
| `sdd-develop` | Um passo do PLAN por sessão |
| `read-sdd-artifact` | Normalização opcional → `source_context` (só paths sob `features/`) |
| `document-plan` | Pergunta o idioma da doc antes de escrever |
| Caveman | Default OFF; `caveman on\|off\|status\|lite\|full\|ultra` — [Modo Caveman](../caveman/) |
| Orchestrator | Padrão `always` — [docs/guides/08-orchestrator-mode.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/guides/08-orchestrator-mode.md) |

Notas estáticas instaladas: `_shared/skills-catalog/OPERATOR.md` (via `help-skills`).

## Re-sync quando as skills parecerem desatualizadas

Fixture (seguro) — qualquer id de agente suportado:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude
```

Exemplo live (Claude):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude `
  -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Live Cursor:

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

Arquivos gerenciados são sobrescritos; arquivos não gerenciados (externos) no ambiente do agente são preservados.

Próximo: [Começar](../get-started/) · [Adaptadores](../adapters/) · [Arquitetura](../architecture/) · [Caveman](../caveman/) · [Início](../)
