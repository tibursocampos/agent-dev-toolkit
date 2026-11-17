---
title: Usando skills
---

# Usando skills

Invoque skills pelo **id** (kebab-case em `core/skills/`). O id é o mesmo em todo host. O prefixo é do host (`/`, `$`, `use skill` ou a ferramenta `skill` do OpenCode). Compat em muitos hosts: `use skill <id>`, ou linguagem natural que bate com a descrição da skill.

Depois de qualquer sync, invoque **`adt-help-skills`**. Ela lê o catálogo instalado (`CATALOG.md` e `OPERATOR.md`). Há **52** skills invocáveis. Pastas em `core/skills/_shared/` são packs, não skills. Os arquivos architect, database, security, repo-analyst e shell-runner em `core/agents/` são papéis do roster, não ids de skill.

O roteamento depende do adaptador: o Copilot tem `router=false`, então a orientação de `core/router/AGENTS.md` fica embutida no `copilot-instructions.md` gerado; isso não é um id de skill separado nem prova de execução no host ao vivo.

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

Escolha o fluxo antes com [Choosing the flow](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/guides/flow-selection.md) (guia ainda só em inglês).

```text
Feature
  └─ adt-orchestrate-analyze
        ├─ entende o resultado, pergunta decisões materiais e investiga proporcionalmente
        ├─ um arquivo trivial → /adt-developer (só se você escolher esse atalho)
        ├─ uma story já clara → adt-sdd-spec
        └─ stories selecionadas → PRD + PLAN por story → uma aprovação do conjunto completo
                    └─ um passo adt-sdd-develop por filho → adt-run-tests, adt-code-review, adt-run-tests (após mudanças da revisão), security
```

### Orchestrated Delivery

```text
adt-orchestrate-analyze
adt-orchestrate-prepare - features/NNN-slug/
adt-orchestrate-implement - features/NNN-slug/
```

Analyze investiga proporcionalmente e usa especialistas para perguntas concretas. Deliver prepara PRDs e PLANs das stories selecionadas e apresenta o conjunto completo, explicitamente listado, para uma aprovação antes da implementação. Develop despacha serialmente, um passo do PLAN por filho, reconciliando cada resultado antes do próximo. Memory Bank e arquivos auxiliares são contexto opcional. Detalhes: [Entrega orquestrada](orchestrated-delivery.pt.md).

Legenda dos gates (rótulo em português = id): `sim` = confirm, `ajustar` = adjust, `cancelar` = cancel, `pular` = skip, `não` = decline. Os rótulos são localizados; os ids ficam sempre em inglês. Detalhes: [Perguntas e confirmações](questions.md).

Use o papel **architect** do roster quando uma pergunta concreta de arquitetura precisar de análise especializada. Peça uma decisão ao operador somente quando ela afetar materialmente comportamento, aceite, escopo ou implementação. Ser greenfield, não ter estilo definido ou ser brownfield não exige aprovação ou espelhamento de ARCH. O pai permanece coordenador.

Em Classic SDD e O1/O2/O3, somente uma questão material sem resposta bloqueia o trabalho afetado. Dúvidas menores ficam visíveis; stories independentes podem avançar. O PLAN é a única fonte persistida de progresso. Backlog Refine e outras skills mantêm seus próprios contratos.

### Classic SDD direto

Use isto quando uma feature tiver caminho claro. SDD clássico é independente e não exige O1, pasta de especialista ou Memory Bank. Chamadas internas de O2 não exibem outra tabela de progresso.

| Ordem | Skill | Saída |
|-------|--------|--------|
| 1 | `adt-sdd-spec` | `features/NNN-slug/USnn/PRD/NNN_slug.md` |
| 2 | `adt-sdd-plan` | `features/NNN-slug/USnn/PLAN/PLAN_NNN_slug.md` |
| 3 | `adt-sdd-develop` | Um passo do PLAN: código, testes, progresso do PLAN |
| — | `adt-read-sdd-artifact` | `source_context` somente leitura |

A pasta de story padrão, quando não informada, é `US01` (`TSnn` para story técnica). Pastas `PRD/` ou `PLAN/` na raiz são inválidas.

```text
adt-sdd-spec
adt-sdd-plan - features/NNN-slug/US01/PRD/NNN_slug.md
adt-sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
adt-read-sdd-artifact - features/NNN-slug/US01/PRD/NNN_slug.md
```

`adt-sdd-spec` define comportamento esperado, escopo, aceite, contratos relevantes e perguntas materiais no PRD. Rascunhar e salvar fazem parte da preparação; não há aprovação separada para escrever o PRD. IDs e gramática exata ajudam na rastreabilidade, mas não são gates de autorização. Contexto brownfield entra no PRD ou PLAN quando for relevante. A skill não escreve PLAN na mesma sessão.

`adt-sdd-plan` deriva passos executáveis diretamente do PRD ou de uma demanda suficientemente especificada. `adt-split-story-checklist` é opcional. O PLAN reúne dependências, aceite, evidências de validação, bloqueios, próxima ação e a única tabela de progresso. Apresente o PLAN completo para uma aprovação explícita antes da implementação. O planejamento direto termina com handoff; não inicia a implementação automaticamente.

`adt-sdd-develop` segue o ritmo `step_by_step` ou `continuous` do PLAN aprovado. Antes de cada passo, confira aprovação, dependências, escopo, aceite e evidências relevantes. O PLAN é a única fonte de progresso; flags de SESSION e claims não são pré-requisitos. Registre o estado/evidência canônicos por passo. Agrupe validações quando isso produzir evidência mais clara do que rodar testes após cada passo.

`adt-read-sdd-artifact` não tem gate de **sim**. Tipos permitidos: FEATURE, STORY, PRD, PLAN. Motivos de rejeição: `path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path`.

Classic SDD e O2 fazem verificações substantivas de comportamento, aceite, escopo, dependências e validação exigida. Validadores genéricos de PRD/PLAN/CHANGE podem ser diagnósticos opcionais; títulos, contagem de seções e arquivos auxiliares não autorizam avanço.

### Um item de produto

O O1 cria stories justificadas sem exigir um scorecard ou chamada separada de refine. Invoque `adt-refine-story` para formar um item único de backlog fora do fluxo de feature.

O modo é obrigatório. Se você omitir, a skill pergunta uma vez.

| Modo | Invocação | Item padrão |
|------|-----------|-------------|
| feature | `feature`, `1` | User story ou bug |
| tech | `tech`, `technical`, `2` | Story técnica |
| split | `split`, `3` | Qualquer tipo, depois handoff para o checklist |

```text
adt-refine-story - feature
adt-refine-story - tech
adt-refine-story - split
adt-split-story-checklist - features/NNN-slug/US01/STORY.md
```

### Desafiar um requisito

Rode `adt-requirement-review` antes do SDD quando uma feature ou story ainda tem perguntas abertas, ou quando uma story técnica precisa ser conferida contra o repositório. O modo é obrigatório: `--feature` confere lacunas funcionais e critérios de aceite; `--tech` confere contratos e fluxos contra o repositório. A skill pergunta uma vez se você omitir o modo.

```text
adt-requirement-review --feature - features/NNN-slug/US01/STORY.md
adt-requirement-review --tech - features/NNN-slug/US01/STORY.md
```

Depois de um **sim** explícito, a revisão grava um relatório e acrescenta ao histórico de perguntas em `REFINE/`, ao lado da story. O status é `READY` ou `NEEDS_CLARIFICATION`. O `adt-refine-story` chama essa revisão no passo 4a, antes de passar para o `adt-sdd-spec`.

Persistência, nesta ordem: `features/NNN-slug/USnn/STORY.md` ou `TSnn/STORY.md`, `REFINE/` opcional (incluindo `REFINE/qa-history.md`), ou o atalho `docs/backlog/<slug>.md` depois de uma pergunta de idioma da documentação. A skill não cria cartões de tracker.

Em Classic SDD e O1/O2/O3, resolva uma pergunta antes do trabalho dependente somente quando ela afetar materialmente comportamento, aceite, escopo, acesso ou implementação. Dúvidas menores ficam visíveis e não interrompem trabalho independente.

`adt-split-story-checklist` cria tarefas SMART de forma opcional sob a story existente (`REFINE/tasks.md` por padrão). Não cria pastas novas `USnn` ou `TSnn`. `adt-sdd-plan` pode derivar passos diretamente do PRD; a falta de checklist nunca bloqueia o planejamento, em qualquer nível de complexidade.

### Mudança pequena de stack

```text
adt-developer
```

`adt-developer` confere um brief de UI e depois a tabela de stack. O primeiro acerto vence.

| Sinal | Skill |
|-------|--------|
| Plugin Blip novo, sem projeto `blip-ds` existente | `adt-blip-plugin-developer` |
| `package.json` tem `blip-ds` e `iframe-message-proxy` | `adt-react-developer` |
| Marcadores Blazor | `adt-blazor-developer` |
| `electron`, `electron-builder` ou `electron-vite` | `adt-electron-developer` |
| `vue` (e não React nem Angular) | `adt-vue-developer` |
| `react-native` ou `expo` | `adt-react-native-developer` |
| `react` | `adt-react-developer` |
| `@angular/core` ou `angular` | `adt-angular-developer` |
| `package.json` sem nenhum dos anteriores | `adt-javascript-developer` |
| `.csproj` / `.sln` sem marcadores Blazor | `adt-dotnet-developer` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle` | `adt-java-developer` |
| Evidência explícita de Arduino Core/framework, metadados do Arduino ou `framework = arduino` configurado | `adt-arduino-developer` |
| Evidência nativa de ESP-IDF (`idf_component.yml`, lockfile do Component Manager, `idf_component_register`, estrutura CMake do ESP-IDF, `sdkconfig`/`sdkconfig.defaults` ou scripts `idf.py`) | `adt-esp-idf-developer` |
| Runtime MicroPython ou fluxo de firmware declarado, com evidência de runtime, target ou porta | `adt-micropython-developer` |
| Aplicações, ferramentas ou testes CPython no host (inclusive código do host que se comunica com firmware) | `adt-python-developer` |
| `.py`, `main.py` ou nome de família de placa sem evidência de framework/runtime/toolchain | `/adt-developer` (pergunte evidências de framework/core/runtime/versão/toolchain; não infira) |
| Python sem evidência de runtime/target/porta quando APIs ou deployment puderem diferir | `/adt-developer` (pergunte evidências de runtime, target e porta; a ambiguidade é intencional) |
| `requirements.txt` ou `pyproject.toml` com evidência de runtime no host | `adt-python-developer` |

HTML isolado ou scripts de shell ficam em `/adt-developer`. Um escopo grande faz handoff para `/adt-sdd-spec`. O O3 não chama `adt-*-developer` para um passo do PLAN.

Cada skill de stack é trabalho pequeno ou médio. Confirme com **sim** antes de escrever. Um resultado, e para.

| Skill | Escopo | Handoff quando o escopo cresce |
|-------|--------|--------------------------------|
| `adt-dotnet-developer` | .NET | `/adt-sdd-spec` |
| `adt-java-developer` | JVM. Spring Boot é o padrão que a skill nomeia | `/adt-sdd-spec` |
| `adt-javascript-developer` | Node ou DOM. Não existe o id `node-developer` | `/adt-sdd-spec` |
| `adt-python-developer` | FastAPI ou Flask, pytest | `/adt-sdd-spec` |
| `adt-react-developer` | React web | `/adt-react-native-developer` para mobile |
| `adt-react-native-developer` | React Native ou Expo | `/adt-react-developer` para web |
| `adt-angular-developer` | Angular | Criar um brief quando decisões visuais substanciais forem necessárias |
| `adt-vue-developer` | Vue 3, Composition API, Pinia, Vitest | Criar um brief quando decisões visuais substanciais forem necessárias |
| `adt-blazor-developer` | WASM, Server, Hybrid | `/adt-dotnet-developer` para a API |
| `adt-electron-developer` | Main, preload, renderer, IPC, empacotamento | Segurança e CSP carregam primeiro quando o IPC muda |
| `adt-blip-plugin-developer` | Andaime de um plugin Blip React novo | UI para `adt-react-developer`. Ela não implementa o conjunto da feature |
Para UI nova ou redesign visual substancial, registre público, hierarquia, direção visual, comportamento responsivo, estados dos componentes e acessibilidade em `docs/DESIGN-BRIEF.md` antes da implementação. A orientação geral está em `core/skills/_shared/frontend-guidelines/frontend-practices.md`.

Guidelines ficam em `core/skills/_shared/code-guidelines/`. Carregue um arquivo.

| Camada | Pergunta | Arquivo |
|--------|----------|---------|
| A | Qual estilo | `principles/architecture-selection.md` |
| B | O que o estilo exige | Um de `architecture/vertical-slice.md`, `concentric-dependency.md`, `ddd-tactical.md`, `event-driven.md` |
| C | Como esta stack faz isso | O pack `*-guidelines` correspondente |

Quando uma escolha concreta de arquitetura afetar materialmente comportamento ou implementação, apresente-a e resolva-a antes do trabalho dependente. A classificação greenfield ou brownfield, sozinha, não exige aprovação ou espelhamento de ARCH. O código existente é evidência das convenções atuais, não uma exigência de criar uma nota separada de arquitetura. Vertical slice continua sendo uma opção para greenfield com CRUD pesado. Clean Architecture, onion e hexagonal são a mesma regra concentric.

### Depois da implementação

```text
adt-run-tests
adt-code-review
adt-run-tests (após mudanças da revisão, ou registre que não foi necessário repetir)
security
adt-test-coverage
adt-commit
adt-push
adt-open-github-pr
```

`adt-code-review` pergunta single versus multi-angle. Não há padrão. Ângulos: quality, acceptance, security (no máximo três filhos quando `subagents=native`). Faixas de achado: `critical`, `important` e `nice-to-have`. Decisões: **Approved**, **Approved with reservations**, **Changes required**. A skill não edita código. Depois do relatório ela pergunta **sim** / **pular** só para uma correção e uma nova revisão. Não pergunta sobre memory bank, docs do projeto ou pull request. `adt-code-explain` é separada: compara mudanças quando os dois endpoints resolvem, pergunta pelo endpoint faltante ou explica código existente a partir de tópico, símbolo, arquivo ou pasta resolvível, sem diff. Cita o código aberto e separa observação de inferência; não emite veredito de revisão. Quando um escopo do O3 fecha, a ordem é `adt-run-tests`, `adt-code-review`, `adt-run-tests` após mudanças da revisão (ou registre que não foi necessário repetir), a passagem de `security`, depois `/adt-commit` e `/adt-push`.

`adt-run-tests` roda o comando de teste de cada stack detectada e devolve `PASS` ou `FAIL`. Não edita código. Uma checagem que o repositório não tem fica `SKIPPED`.

`adt-test-coverage` é Coverlet para .NET. Limiar padrão **80**. Escreve `TestResults/CoverageReport/`. Não bloqueia merge sozinha. `adt-code-review` aplica o limiar. Uma falha vai para `/adt-dotnet-developer` ou `/adt-sdd-develop`. Um build quebrado vai para `/adt-repair-dotnet-build`. `adt-run-tests` chama essa skill só quando o PLAN pede cobertura.

`adt-repair-dotnet-build` usa `dotnet build` / `dotnet test` local, ou um log colado. Não chama uma API de CI remota. Um erro por vez, só .NET. Cada edição proposta espera confirmação.

`adt-refactor` é um passo seguro com os testes ainda verdes. Não mistura features nem correções de bug. Sem auto-commit.

`adt-performance-profile` audita primeiro, espera uma escolha de fluxo e então prova a mudança com um micro-benchmark.

Modos de `adt-framework-upgrade`: `audit`, `plan`, `migrate`, `validate`. Packs no disco: `angular`, `dotnet`. Se o modo for omitido, a skill pergunta uma vez. `migrate` precisa de **sim**. O id da skill nunca inclui um número de versão (`dotnet10-upgrade` e `framework-upgrade-vN` são proibidos). `targetVersion` precisa ser maior que `currentVersion`.

### Skills de plataforma

Elas ficam ao lado da entrega. Quando a mudança é um passo do PLAN, termine a skill e volte a `/adt-sdd-develop` para o passo correspondente. Cada passo precisa da própria invocação, mas não exige um novo chat do operador.

```text
adt-api-standards
adt-api-standards - versioning
adt-api-integrate - <openapi>
adt-i18n-manager
adt-containerize
adt-ef-add-migration
adt-scaffold-message-handler
```

`adt-api-standards` cobre forma REST, versionamento, erros, nomes e higiene de segurança. Foco opcional: `rest`, `versioning`, `errors`, `naming`, `security`. Clientes tipados são `adt-api-integrate` (OpenAPI ou Swagger). Sem segredos no código-fonte.

`adt-i18n-manager` extrai literais de UI para `.resx` ou `.json` e os troca por chaves. Espera uma escolha de fluxo antes de escrever. Não localiza logs nem configuração.

`adt-containerize` escreve um Dockerfile multi-stage, `.dockerignore` e compose para dependências locais. Espera uma escolha de fluxo. Arquivos que serão commitados não contêm segredos.

`adt-ef-add-migration` descobre o projeto de startup, o DbContext e a pasta de migrations, e então roda `dotnet ef migrations add`. Um nome inferido é confirmado antes. Use no repositório consumidor.

`adt-scaffold-message-handler` coleta fila, contrato, retry e idempotência antes de escrever um consumidor. Detecta MassTransit, RabbitMQ ou Azure Service Bus no repositório consumidor. Não entrega um template corporativo.

### Git e documentação do repositório

`adt-commit`, `adt-push` e `adt-open-github-pr` permanecem em prosa completa. Heads permitidos: `feature/<slug>` ou `feat/<id>` (um segmento). Bloqueados: `main`, `master`, `develop`, `feature/a/b` aninhado. Nenhum deles faz force-push de `main`, `master` ou `develop`.

```text
adt-commit
adt-push
adt-open-github-pr
adt-document-plan
adt-document-implement
adt-help-skills
```

`adt-commit` redige um Conventional Commit (`feat`, `fix`, `docs`, `style`, `adt-refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) e espera o texto exato. Assunto e corpo são em inglês. Não pergunta sobre memory bank nem docs do projeto. Depois do commit, um trailer `Co-authored-by` é removido até sumir. Push ou pull request só roda quando o mesmo pedido já inclui essa ação.

`adt-push` roda `git push -u origin HEAD` depois da checagem do branch. Se esta conversa já pediu um pull request, carrega `adt-open-github-pr`. Caso contrário, pergunta.

`adt-open-github-pr` é dono de `gh pr create`. Feature (`feature/*` ou `feat/*` atual) aponta para `develop` com `--squash` quando o auto-merge está ligado. Release (`develop` para `master` ou `main`) usa `--rebase`. O gate do conteúdo (ids `confirm`, `adjust`, `cancel`) é separado da pergunta de auto-merge (ids `confirm`, `decline`). Os rótulos são localizados. Se o branch não estiver em `origin`, o handoff é `/adt-push` primeiro.

`adt-document-plan` pergunta o idioma da documentação uma vez, e então escreve `docs/overview.md` e `docs/documentation-plan/plan.md`. Não escreve PLANs de feature. Para este toolkit o idioma é inglês. `adt-document-implement` executa um passo pendente e para.

`adt-help-skills` imprime o catálogo estático. Não inventa ids. Não existe o id `open-pr`. O id é `adt-open-github-pr`.

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

As respostas dos gates são interpretadas pelo significado, em qualquer idioma; silêncio, resposta ambígua ou emoji isolado não é aprovação.

### Orquestrador pai

adaptive: trabalho trivial (limites 3/6/150) pode ficar no pai. always: delega tudo, exceto qa_checklist. Tabela completa: `core/policy/orchestrator-session.md` "Modes".
### Compressão opcional do chat

O primeiro sync interativo pergunta se a compressão de resposta Caveman fica ligada ou desligada; **ligada** é o padrão. O primeiro sync não interativo usa `caveman_mode: true`. Ela só encurta a prosa do chat. Não muda passos de skill, gates nem documentação.

Comandos: `caveman on`, `caveman off`, `caveman status`, `caveman lite`, `caveman full`, `caveman ultra`. `stop caveman` e `normal mode` desligam.

`adt-help-skills`, `adt-read-sdd-artifact`, `adt-commit`, `adt-push` e `adt-open-github-pr` nunca comprimem. Gates, rascunhos, caminhos e as opções dos gates (ids `confirm`, `adjust`, `cancel`; no install em português: sim / ajustar / cancelar) permanecem claros. Arquivo de política: `core/policy/caveman-mode.md`. A ideia está creditada em [Créditos](credits.md).

### Subagentes: modelo e esforço

Use `adt-settings` para consultar ou salvar um único par geral de modelo e esforço para subagentes, ou para voltar a herdar. O padrão é herdar os dois valores do pai. Um par salvo serve somente como pré-seleção da pergunta de sessão, feita uma vez; ele não altera uma sessão depois que a pergunta foi respondida.

Os pares disponíveis vêm da linha do adapter efetivo em `SUBAGENT-OPTIONS.md`. Quando não há mecanismo comprovado para aplicar o par, o host herda os valores do pai.

| Adapter | Status |
|---------|--------|
| Claude | documented, not verified at runtime |
| Codex | documented, not verified at runtime |
| Cursor | documented, not verified at runtime |
| Hermes | documented, not verified at runtime |
| Copilot | documented, not verified at runtime |

Atualize o status de um adapter somente depois de registrar evidência real para ele.

### Outras chaves de preferência

| Chave | Padrão | Efeito |
|-------|--------|--------|
| `orchestrator_mode` | `adaptive` | O pai orquestra; trabalho trivial pode ficar no pai |
| `subagent_models.default` | ausente (herdar) | Par `{model, effort}` opcional usado como pré-seleção |
| `caveman_mode` | `true` no primeiro sync | Compressão do chat ligada; o sync interativo pode desligá-la |
| `caveman_level` | `full` | Intensidade se a compressão for ligada |
| `artifact_language` | `null` | Sem override de locale |
| `verify_mode` | `false` | O O3 não faz spawn de um verificador somente leitura depois de cada implementador |

`verify_mode: true` é um segundo filho depois de um passo bem-sucedido de `adt-sdd-develop`. Ele é separado do script de evidência (`validate-evidence`).

## Sync de novo

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Arquivos geridos são sobrescritos. Arquivos alheios no home do agente permanecem.
