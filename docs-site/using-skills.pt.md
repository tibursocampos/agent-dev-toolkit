---
title: Usando skills
---

# Usando skills

Invoque skills pelo **id** (kebab-case em `core/skills/`). O id é o mesmo em todo host. O prefixo é do host (`/`, `$`, `use skill` ou a ferramenta `skill` do OpenCode). Compat em muitos hosts: `use skill <id>`, ou linguagem natural que bate com a descrição da skill.

Depois de qualquer sync, invoque **`help-skills`**. Ela lê o catálogo instalado (`CATALOG.md` e `OPERATOR.md`). Há **42** skills invocáveis. Pastas em `core/skills/_shared/` são packs, não skills. Os arquivos architect, database, security, repo-analyst e shell-runner em `core/agents/` são papéis do roster, não ids de skill.

`/hooks` do Codex e `/hooks-trust` do Grok são telas de confiança de hooks. Não são atalhos de skill. O Codex não tem a flag `$skill --menu`. O seletor `$` / `/skills` é o menu do produto.

Instalação: [Começar](get-started.md). Um exemplo de cada skill: [Primeiro uso](first-use.md). O caminho da feature: [Entrega orquestrada](orchestrated-delivery.md). Comandos de sync, validação e desinstalação: [CLI](cli.md).

## Pré-requisitos

1. Sincronize pelo menos um agente ([Começar](get-started.md)).
2. Abra um projeto **consumidor** nesse agente.
3. Opcional: rode `validate-agent.ps1` contra um fixture ou um InstallRoot ao vivo.

## Onde a skill roda

Raízes de instalação e layouts de publicação estão em [Adaptadores](adapters.md). Comandos de sync, validação e desinstalação estão em [CLI](cli.md).

O id é o mesmo em todo host. Cursor e Claude usam o prefixo `/`. Codex e ZCode usam `$`. OpenCode chama a ferramenta `skill`. Antigravity aceita `use skill <id>` ou `/id`. Depois de um sync do Copilot, rode `/skills reload`.

## Qual skill

```text
Feature
  └─ orchestrate-analyze
        ├─ classifica, pergunta, define needs_*, especialistas, gates de story, sim
        ├─ um arquivo trivial → /developer (só se você escolher esse atalho)
        ├─ uma story já clara → sdd-spec
        └─ backlog aprovado → orchestrate-deliver
              └─ arquivos da story, sdd-spec, contestação do PRD, sdd-plan → orchestrate-develop
                    └─ um passo sdd-develop por filho → code-review, run-tests, security
```

### Orchestrated Delivery

```text
orchestrate-analyze
orchestrate-deliver - features/NNN-slug/
orchestrate-develop - features/NNN-slug/
```

Analyze classifica, pergunta, define `needs_*`, chama especialistas quando as flags exigem e espera o **sim** do backlog. As pastas de story esperam a feature sem pergunta aberta. Deliver confere os arquivos de cada story, roda `sdd-spec`, contesta esse PRD e roda `sdd-plan`. Develop roda um passo de `sdd-develop` por filho. Gates, pastas e confirmações: [Entrega orquestrada](orchestrated-delivery.md).

Quando o analyze define greenfield ou `needs_domain` e não há estilo de ARCH, o papel de roster **architect** devolve um rascunho. Você responde **sim** antes de o estilo ser aprovado. Brownfield espelha o estilo existente. O pai permanece coordenador.

Nos quatro gates de pergunta aberta, qualquer pergunta sem resposta, inclusive **MINOR**, impede o próximo artefato (`open_question`). Fora desses gates, clarificação aberta **B** ou **I** impede a escrita de PRD e PLAN (`NEEDS_CLARIFICATION`) e **MINOR** pode permanecer. Prontidão não é `step_confirmed`.

### Classic SDD direto

Use isto quando uma story já estiver clara. As mesmas três skills rodam dentro de deliver e develop. O contexto direto não exige memory bank. Uma pasta de especialista ausente é uma pergunta. Chamadas orquestradas voltam ao O1.

| Ordem | Skill | Saída |
|-------|--------|--------|
| 1 | `sdd-spec` | `features/NNN-slug/USnn/PRD/NNN_slug.md` |
| 2 | `sdd-plan` | `features/NNN-slug/USnn/PLAN/PLAN_NNN_slug.md` |
| 3 | `sdd-develop` | Um passo do PLAN: código, testes, progresso do PLAN |
| — | `read-sdd-artifact` | `source_context` somente leitura |

A pasta de story padrão, quando não informada, é `US01` (`TSnn` para story técnica). Pastas `PRD/` ou `PLAN/` na raiz são inválidas.

```text
sdd-spec
sdd-plan - features/NNN-slug/US01/PRD/NNN_slug.md
sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
read-sdd-artifact - features/NNN-slug/US01/PRD/NNN_slug.md
```

`sdd-spec` escreve o quê e o porquê, um `REQ-NNN` estável, o que está fora de escopo, e espera **sim** / **ajustar** / **cancelar**. Ela roda `scripts/validation/validate-prd.ps1`. Brownfield também escreve `features/NNN-slug/CHANGE.md` e roda `validate-change.ps1`. Ela não escreve um PLAN na mesma sessão.

`sdd-plan` exige um PRD canônico cujo status está pronto para planejamento. O número do PLAN bate com o do PRD e vive na mesma pasta da story. Cada passo é uma sessão posterior de `sdd-develop`. SQL, DDL, JSON e OpenAPI ficam em um arquivo canônico. O PLAN cita esse caminho. **sim** antes de escrever. `validate-plan` precisa passar antes de `/sdd-develop`.

`sdd-develop` precisa do caminho canônico do PLAN e de um id de passo. Uma sessão completa um passo. Depois do **sim**, `scripts/session/Invoke-DevelopSessionGate.ps1` grava `step_confirmed`. Quando uma reivindicação é necessária, roda `scripts/ledger/Invoke-PlanLedgerClaim.ps1 -Action claim`. Use um branch de feature (`feature/<slug>` ou `feat/<id>`). Carregue um arquivo de guideline para o passo. Quando o passo alega cobertura de aceite, ou o nível de evidência é `cheap` ou mais alto, atualize `EVD/` e `STATE.md` e rode `validate-evidence.ps1`. Níveis: `off`, `cheap`, `standard`, `strict`. Quando o passo fecha a onda da feature, acrescente `TRACE.jsonl` e rode `validate-trace.ps1 -RequireArchiveComplete`. OpenSpec, `.specs/` e SQLite não são a fonte da verdade do trace.

`read-sdd-artifact` não tem gate de **sim**. Tipos permitidos: FEATURE, STORY, PRD, PLAN. Motivos de rejeição: `path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path`.

O preflight `Invoke-PrdPlanChangePreflight.ps1` é uma checagem do O2 sobre `validate-prd`, `validate-plan` e `validate-change`. Não é uma quarta skill.

### Um item de produto

O O1 já aplica o scorecard. Invoque `refine-story` ao formar um item único de backlog, ou quando o deliver parou em **B** / **I** aberto.

O modo é obrigatório. Se você omitir, a skill pergunta uma vez.

| Modo | Invocação | Item padrão |
|------|-----------|-------------|
| feature | `feature`, `1` | User story ou bug |
| tech | `tech`, `technical`, `2` | Story técnica |
| split | `split`, `3` | Qualquer tipo, depois handoff para o checklist |

```text
refine-story - feature
refine-story - tech
refine-story - split
split-story-checklist - features/NNN-slug/US01/STORY.md
```

Persistência, nesta ordem: `features/NNN-slug/USnn/STORY.md` ou `TSnn/STORY.md`, `REFINE/` opcional (incluindo `REFINE/qa-history.md`), ou o atalho `docs/backlog/<slug>.md` depois de uma pergunta de idioma da documentação. A skill não cria cartões de tracker.

Enquanto houver pergunta aberta no gate da feature, dos arquivos da story, do PRD ou do PLAN, inclusive **MINOR**, não faça handoff para `sdd-spec`. Fora desses gates, **MINOR** pode permanecer. Pronto para spec não é `step_confirmed`.

`split-story-checklist` precisa de **Steps** estruturados já existentes, salvo quando `sdd-plan` a chama com `source=prd`. Aí ela monta grupos a partir do PRD. Ela escreve tarefas SMART sob a story existente (`REFINE/tasks.md` por padrão). Ela não cria pastas novas `USnn` ou `TSnn`. No máximo cinco grupos de implementação. Uma invocação direta pergunta o idioma da documentação uma vez, no idioma do chat, antes de escrever. Uma chamada orquestrada não pergunta. Uma feature `trivial` não ganha arquivo de tarefas só para satisfazer um gate, salvo quando quem chama é `sdd-plan`, que ainda recebe um passo. `medium` e `complex` precisam do checklist antes do handoff.

### Mudança pequena de stack

```text
developer
```

`developer` confere um brief de UI e depois a tabela de stack. O primeiro acerto vence.

| Sinal | Skill |
|-------|--------|
| Plugin Blip novo, sem projeto `blip-ds` existente | `blip-plugin-developer` |
| `package.json` tem `blip-ds` e `iframe-message-proxy` | `react-developer` |
| Marcadores Blazor | `blazor-developer` |
| `electron`, `electron-builder` ou `electron-vite` | `electron-developer` |
| `vue` (e não React nem Angular) | `vue-developer` |
| `react-native` ou `expo` | `react-native-developer` |
| `react` | `react-developer` |
| `@angular/core` ou `angular` | `angular-developer` |
| `package.json` sem nenhum dos anteriores | `javascript-developer` |
| `.csproj` / `.sln` sem marcadores Blazor | `dotnet-developer` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle` | `java-developer` |
| `.py`, `requirements.txt`, `pyproject.toml` | `python-developer` |

HTML isolado ou scripts de shell ficam em `/developer`. Um escopo grande faz handoff para `/sdd-spec`. O O3 não chama `*-developer` para um passo do PLAN.

Cada skill de stack é trabalho pequeno ou médio. Confirme com **sim** antes de escrever. Um resultado, e para.

| Skill | Escopo | Handoff quando o escopo cresce |
|-------|--------|--------------------------------|
| `dotnet-developer` | .NET | `/sdd-spec` |
| `java-developer` | JVM. Spring Boot é o padrão que a skill nomeia | `/sdd-spec` |
| `javascript-developer` | Node ou DOM. Não existe o id `node-developer` | `/sdd-spec` |
| `python-developer` | FastAPI ou Flask, pytest | `/sdd-spec` |
| `react-developer` | React web | `/react-native-developer` para mobile |
| `react-native-developer` | React Native ou Expo | `/react-developer` para web |
| `angular-developer` | Angular | Brief de UI para `impeccable` quando falta |
| `vue-developer` | Vue 3, Composition API, Pinia, Vitest | Brief de UI para `impeccable` quando falta |
| `blazor-developer` | WASM, Server, Hybrid | `/dotnet-developer` para a API |
| `electron-developer` | Main, preload, renderer, IPC, empacotamento | Segurança e CSP carregam primeiro quando o IPC muda |
| `blip-plugin-developer` | Andaime de um plugin Blip React novo | UI para `react-developer`. Ela não implementa o conjunto da feature |
| `impeccable` | Comandos de design | Escreve `docs/DESIGN-BRIEF.md` depois da confirmação e para |

Gatilhos de `impeccable`: `/impeccable`, `/impeccable <command>`, `/impeccable-shape`, `/impeccable-audit`. `teach` é um alias obsoleto de `init`. Se `PRODUCT.md` faltar, rode `init` primeiro. O register é `brand` ou `product`. Comandos que vêm no repositório incluem `init`, `shape`, `craft`, `critique`, `audit`, `harden`, `polish`, `onboard`. Depois do **sim** em `shape` ou `craft`, o chat seguinte é a skill de stack nomeada por `target_stack`.

Guidelines ficam em `core/skills/_shared/code-guidelines/`. Carregue um arquivo.

| Camada | Pergunta | Arquivo |
|--------|----------|---------|
| A | Qual estilo | `principles/architecture-selection.md` |
| B | O que o estilo exige | Um de `architecture/vertical-slice.md`, `concentric-dependency.md`, `ddd-tactical.md`, `event-driven.md` |
| C | Como esta stack faz isso | O pack `*-guidelines` correspondente |

Greenfield propõe um estilo e escreve o ARCH final só depois do **sim**. Brownfield espelha. Vertical slice é a proposta para greenfield pesado em CRUD. Clean Architecture, onion e hexagonal são a mesma regra concentric.

### Depois da implementação

```text
code-review
run-tests
test-coverage
commit
push
open-github-pr
```

`code-review` pergunta single versus multi-angle. Não há padrão. Ângulos: quality, acceptance, security (no máximo três filhos quando `subagents=native`). Decisões: **Approved**, **Approved with reservations**, **Changes required**. A skill não edita código. Depois do relatório ela pergunta **sim** / **pular** para uma correção, uma nova revisão, um refresh do bank e docs do projeto. Quando um escopo do O3 fecha, `run-tests` roda em seguida, depois a passagem de security, depois `/commit` e `/push`.

`run-tests` roda o comando de teste de cada stack detectada e devolve `PASS` ou `FAIL`. Não edita código. Uma checagem que o repositório não tem fica `SKIPPED`.

`test-coverage` é Coverlet para .NET. Limiar padrão **80**. Escreve `TestResults/CoverageReport/`. Não bloqueia merge sozinha. `code-review` aplica o limiar. Uma falha vai para `/dotnet-developer` ou `/sdd-develop`. Um build quebrado vai para `/repair-dotnet-build`. `run-tests` chama essa skill só quando o PLAN pede cobertura.

`repair-dotnet-build` usa `dotnet build` / `dotnet test` local, ou um log colado. Não chama uma API de CI remota. Um erro por vez, só .NET. Cada edição proposta espera confirmação.

`refactor` é um passo seguro com os testes ainda verdes. Não mistura features nem correções de bug. Sem auto-commit.

`performance-profile` audita primeiro, espera uma escolha de fluxo e então prova a mudança com um micro-benchmark.

Modos de `framework-upgrade`: `audit`, `plan`, `migrate`, `validate`. Packs no disco: `angular`, `dotnet`. Se o modo for omitido, a skill pergunta uma vez. `migrate` precisa de **sim**. O id da skill nunca inclui um número de versão (`dotnet10-upgrade` e `framework-upgrade-vN` são proibidos). `targetVersion` precisa ser maior que `currentVersion`.

### Skills de plataforma

Elas ficam ao lado da entrega. Quando a mudança é um passo do PLAN, termine a skill e volte a `/sdd-develop` no próximo passo, em um chat novo.

```text
api-standards
api-standards - versioning
api-integrate - <openapi>
i18n-manager
containerize
ef-add-migration
scaffold-message-handler
```

`api-standards` cobre forma REST, versionamento, erros, nomes e higiene de segurança. Foco opcional: `rest`, `versioning`, `errors`, `naming`, `security`. Clientes tipados são `api-integrate` (OpenAPI ou Swagger). Sem segredos no código-fonte.

`i18n-manager` extrai literais de UI para `.resx` ou `.json` e os troca por chaves. Espera uma escolha de fluxo antes de escrever. Não localiza logs nem configuração.

`containerize` escreve um Dockerfile multi-stage, `.dockerignore` e compose para dependências locais. Espera uma escolha de fluxo. Arquivos que serão commitados não contêm segredos.

`ef-add-migration` descobre o projeto de startup, o DbContext e a pasta de migrations, e então roda `dotnet ef migrations add`. Um nome inferido é confirmado antes. Use no repositório consumidor.

`scaffold-message-handler` coleta fila, contrato, retry e idempotência antes de escrever um consumidor. Detecta MassTransit, RabbitMQ ou Azure Service Bus no repositório consumidor. Não entrega um template corporativo.

### Git e documentação do repositório

`commit`, `push` e `open-github-pr` permanecem em prosa completa. Heads permitidos: `feature/<slug>` ou `feat/<id>` (um segmento). Bloqueados: `main`, `master`, `develop`, `feature/a/b` aninhado. Nenhum deles faz force-push de `main`, `master` ou `develop`.

```text
commit
push
open-github-pr
document-plan
document-implement
help-skills
```

`commit` redige um Conventional Commit (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) e espera o texto exato. Assunto e corpo são em inglês. Se `memory-bank/` existir, pergunta refresh-light: **sim** / **pular**. Se docs do projeto existirem, pergunta se deve atualizá-los. **sim** no bank roda `memory-bank-init` refresh-light. Depois do commit, um trailer `Co-authored-by` é removido até sumir.

`push` roda `git push -u origin HEAD` depois da checagem do branch. Se esta conversa já pediu um pull request, carrega `open-github-pr`. Caso contrário, pergunta.

`open-github-pr` é dono de `gh pr create`. Feature (`feature/*` ou `feat/*` atual) aponta para `develop` com `--squash` quando o auto-merge está ligado. Release (`develop` para `master` ou `main`) usa `--rebase`. O **sim** / **ajustar** / **cancelar** do conteúdo é separado da pergunta de auto-merge (**sim** / **não**). Se o branch não estiver em `origin`, o handoff é `/push` primeiro.

`document-plan` pergunta o idioma da documentação uma vez, e então escreve `docs/overview.md` e `docs/documentation-plan/plan.md`. Não escreve PLANs de feature. Para este toolkit o idioma é inglês. `document-implement` executa um passo pendente e para.

`help-skills` imprime o catálogo estático. Não inventa ids. Não existe o id `open-pr`. O id é `open-github-pr`.

Um exemplo de cada id está em [Primeiro uso](first-use.md).

## Comportamento da sessão { #session-behavior }

Essas regras valem em todo chat depois do sync. São preferências e política. Fonte: `core/skills/_shared/agents/LANGUAGE.md`, `core/policy/orchestrator-session.md`, `core/policy/caveman-mode.md`, `scripts/_lib/Initialize-SddPreferences.ps1`.

### Idioma

| Superfície | Idioma |
|------------|--------|
| O que você lê (chat, planos do host) | O idioma deste chat |
| Artefatos de feature (prosa de FEATURE, STORY, PRD, PLAN, ARCH, SEC, CONTINUITY, CHANGE) | A mesma resolução abaixo |
| Prompts de filhos, contexto de especialistas, recibos | Inglês (`en-US`) |
| Identificadores, caminhos, ids de skill, commits, testes | Inglês |

Idioma do artefato, uma vez por escrita: override da invocação, senão `artifact_language` do `preferences.json` quando não é null, senão `artifact_language` do manifesto quando não é null, senão o idioma do chat. `null` significa sem override.

`core/policy/user-language-pt-br.md` e `core/policy/sdd-artifact-language-pt-br.md` seguem como padrão de instalação para uma sessão em português do Brasil. Quando o chat ou as preferências nomeiam outro idioma, `LANGUAGE.md` vence. Handoffs de filho levam um caminho e um trecho curto.

### Orquestrador pai

O padrão de `orchestrator_mode` é `always`. O pai guarda metas, gates, caminhos e recibos. Especialistas escrevem notas ou código. Comandos: `orchestrator always`, `orchestrator adaptive`, `orchestrator status` (aliases `orchestrate` e `parent`).

`adaptive` pode manter no pai uma pergunta de um caminho só ou uma edição de um arquivo. Qualquer mudança mais larga é spawn. Se o host tem `subagents=none`, o mesmo trabalho fica no pai. A sessão não falha porque Task está ausente.

O `model` da Task é omitido para o filho usar o modelo da sessão pai (`core/skills/_shared/agents/SUBAGENT-MODEL.md`).

### Compressão opcional do chat

`caveman_mode` começa **desligado**. Ele só encurta a prosa do chat. Não muda passos de skill, gates nem documentação.

Comandos: `caveman on`, `caveman off`, `caveman status`, `caveman lite`, `caveman full`, `caveman ultra`. `stop caveman` e `normal mode` desligam.

`help-skills`, `read-sdd-artifact`, `commit`, `push` e `open-github-pr` nunca comprimem. Gates, rascunhos, caminhos e `(sim / ajustar / cancelar)` permanecem claros. Arquivo de política: `core/policy/caveman-mode.md`. A ideia está creditada em [Créditos](credits.md).

### Outras chaves de preferência

| Chave | Padrão | Efeito |
|-------|--------|--------|
| `orchestrator_mode` | `always` | O pai permanece orquestrador |
| `caveman_mode` | `false` | Compressão do chat desligada |
| `caveman_level` | `full` | Intensidade se a compressão for ligada |
| `artifact_language` | `null` | Sem override de locale |
| `verify_mode` | `false` | O O3 não faz spawn de um verificador somente leitura depois de cada implementador |

`verify_mode: true` é um segundo filho depois de um passo bem-sucedido de `sdd-develop`. Ele é separado do script de evidência (`validate-evidence`).

## Sync de novo

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Arquivos geridos são sobrescritos. Arquivos alheios no home do agente permanecem.
