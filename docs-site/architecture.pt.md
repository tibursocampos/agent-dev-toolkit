---
title: Arquitetura
---

# Arquitetura

O **agent-dev-toolkit** é um core neutro de agente, publicado por adaptadores em cada install root do host. Operadores sincronizam com um CLI em PowerShell e depois invocam os mesmos ids de skill no host. Evidência: `core/skills/*/SKILL.md` (**46** skills), `adapters/registry.json` (**10** agentes).

```text
core/  skills, policy, router, sdd, agents
        │  Publish-* (placeholders resolvidos no sync)
        ▼
adapters/<id>/  + adapters/registry.json
        │  InstallRoot (fixture no repositório, ou home ao vivo com -AllowUserHome)
        ▼
layout do host   ~/.cursor, ~/.claude, ~/.codex, ~/.copilot ou .github, …
```

## Layout

```text
core/          skills, política, roteador, contratos sdd, agents
adapters/      módulos por agente, registry.json, _contract
scripts/       toolkit.ps1, sync-agent, validate-agent, _lib, validation, bootstrap
docs/          documentação de operador no repositório
memory-bank/   mapa durável do workspace (Passo 0 da Entrega orquestrada)
.github/workflows/validate-toolkit.yml
.github/workflows/master-release-ci.yml
.github/workflows/enforce-release-source.yml
.github/workflows/release.yml
.github/workflows/publish-release-bootstrap.yml
.github/workflows/docs.yml
```

## Camadas

| Camada | Papel |
|--------|--------|
| Core | Agent Skills (`SKILL.md`), `_shared`, markdown de política, roteador neutro, contratos SDD. Os placeholders ficam na origem |
| Adaptadores | Publicam skills, política, roteador, hooks e agents no layout do host. O smoke usa um InstallRoot de fixture |
| CLI | `scripts/toolkit.ps1` escolhe o agente para sync, validação e desinstalação |
| Install root | Destino. O alvo padrão do sync é um fixture no repositório. Um caminho no perfil do usuário precisa de `-AllowUserHome` |
| CI e release | `validate-toolkit.yml` em `pull_request` para `develop` emite os checks agregadores `validate` e `ci-ok` após os jobs de core, adapter-smoke e docs estrita. PRs de release para `master` / `main` emitem `ci-ok` para a direção da branch e `release-source` para origem, metadados e prontidão do App; eles não repetem a suíte completa. Uma execução verde não sincroniza um home ao vivo |

Comandos estáveis do adaptador: `Get-Capabilities`, `Get-InstallRoots`, `Publish-Skills`, `Publish-Policy`, `Publish-Router`, `Publish-Agents`, `Publish-Hooks`, `Get-SddRoot`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`.

`scripts/sync-agent.ps1` roda Publish e depois sempre `Get-SddRoot -Prepare`. Ações do CLI: `Sync`, `Validate`, `SyncAndValidate`, `ValidateCore`, `ListAgents`, `Uninstall`, `Backup`. Sync, Validate e Uninstall exigem `-Agent`. Uninstall é chaveado e mantém `sdd/sessions` e um `sdd/manifest.json` existente. Backup falha fechado, salvo `-ForceStub`.

O caminho de feature publicado a partir deste core é Orchestrated Delivery (`orchestrate-analyze` → `orchestrate-deliver` → `orchestrate-develop`). Deliver roda `sdd-spec` e depois `sdd-plan`. Develop roda um passo de `sdd-develop` por filho. Detalhe: [Primeiro uso](first-use.md). Flags por agente: [Adaptadores](adapters.md).

## Como um app consumidor escolhe um estilo

Isto é separado do layout de core e adaptadores do próprio toolkit. O pack de guidelines é `core/skills/_shared/code-guidelines/`.

| Modo | Fluxo |
|------|--------|
| **Greenfield** | O especialista de roster **architect** propõe pela Camada A (`architecture-selection.md`) → rascunho ARCH → **sim** → ARCH aprovado. Não há estilo padrão silencioso |
| **Brownfield** | Espelha o estilo ARCH do repositório ou já aprovado. Seleciona de novo só se você pedir para mudar |

Depois da confirmação (ou de um espelho brownfield): carregue **um** arquivo da Camada B em `principles/architecture/` e então o overlay de stack da Camada C correspondente. `orchestrate-analyze` roda o gate de confirmação quando a natureza é greenfield ou `needs_domain` sem estilo estabelecido.

## Política de origem

- O conteúdo de produto para agentes vive em `core/`.
- Nome do arquivo público de estado SDD: `manifest.json`.
- `core/skills/` — 46 skills mais `_shared`. Agentes leem o mapa com `help-skills` (`CATALOG.md` e `OPERATOR.md`).
- `core/policy/` — corpos de regra (`.md`; adaptadores podem normalizar para `.mdc` ou instructions).
- `core/router/` — roteador neutro (`AGENTS.md`). O nome do arquivo no host depende do adaptador.
- `core/skills/_shared/sdd-artifacts/` — `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`, alcançados por `Get-SddRoot`.

Prompts de especialista em `core/agents/` (`architect`, `database`, `repo-analyst`, `security`, `shell-runner`) são publicados quando `agents` é true. `qa_checklist` não tem arquivo de agente.

## Placeholders

O conteúdo do core não grava um home de IDE fixo. Os adaptadores resolvem placeholders na publicação.

| Placeholder | Significado |
|-------------|-------------|
| `{{TOOLKIT_ROOT}}` | Raiz de instalação do toolkit. O Codex separa skills de plugin das regras do InstallRoot |
| `{{SDD_ROOT}}` | Raiz de estado SDD (`preferences.json`, `sessions/`, `manifest.json`, árvore Classic global opcional) |
| `{{GUARDRAILS_PATH}}` | Caminho da política de guardrails para o agente alvo |

Em runtime, as skills resolvem o estado SDD via `effective_SDD_ROOT`, para um caminho gravado de outro agente não vencer. Scripts de runtime sob `<InstallRoot>/scripts/<area>` resolvem `-SddRoot` omitido para `<InstallRoot>/sdd`; os helpers não inferem essa raiz pelo perfil do usuário. `effective_SDD_ROOT` guarda sessões, preferências e `manifest.json` (schema v2), mais `features/` e `memory-bank/` **globais** opcionais quando `classic.storage_mode` é `global`. O modo **repository** mantém essas árvores sob o `$Cwd` do consumidor.

Skills publicadas resolvem seus helpers de runtime declarados a partir da árvore instalada do toolkit. Helpers de sessão recusam incompatibilidades persistidas de identidade de repositório ou PLAN antes de alterar estado. Checks de fixture e estáticos comprovam esses contratos de publicação e sessão; eles não comprovam uma execução em host, IDE ou hook ao vivo.

Agulhas `mustNotContain`: `scripts/validation/contracts/must-not-contain-ide.json`. Suíte do core: `scripts/validation/validate-core.ps1` (alias `validate-all.ps1`). Nomes de marca podem aparecer em regras de coautor. Não são caminhos de home no filesystem.

## Pontos de entrada

- `scripts/toolkit.ps1`
- `scripts/sync-agent.ps1`
- `scripts/validate-agent.ps1`
- `scripts/validation/validate-core.ps1`
- `scripts/validation/Assert-SyncAllowUserHomeForward.ps1`
- `scripts/validation/Invoke-AdapterCiSmoke.ps1 -Adapter <id>` (ids from `adapters/registry.json`: cursor, antigravity, claude, codex, copilot, opencode, grok, zcode, hermes, openhands)
- `.github/workflows/validate-toolkit.yml`
- `.github/workflows/publish-release-bootstrap.yml`
- `.github/workflows/enforce-release-source.yml`

## Cursor

O InstallRoot modela `~/.cursor`.

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<kebab-id>/SKILL.md` | Skills de `core/skills/` |
| `rules/*.mdc` | Política (`.md` → `.mdc`) |
| `AGENTS.md` | Roteador |
| `hooks/*.ps1` | Assets de compatibilidade; não decidem autorização |
| `hooks.json` | Hooks geridos; entradas de autorização do Toolkit são removidas no sync |
| `agents/*.md` | Roster quando `agents=true` |
| `sdd/sessions/` | Sessões (`Get-SddRoot -Prepare`) |
| `sdd/manifest.json` | Semente quando ausente. Nunca sobrescreve um arquivo existente |

Fixture: `scripts/validation/fixtures/cursor-install-root`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter cursor` em uma cópia efêmera. A CI não escreve um `~/.cursor` ao vivo e não dirige a UI de confiança de hooks.

## Antigravity

O InstallRoot modela `~/.gemini`.

| Caminho relativo | Papel |
|------------------|--------|
| `config/skills` | Skills em kebab mais `dev_persona` |
| `config/plugins` | Superfície de plugin (GUARDRAILS sob o id do plugin gerido) |
| `config/hooks` | Configuração de hooks do provider; sem decisão de autorização do Toolkit |
| `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` | Descoberta e markdown gerido |

`antigravity-ide/plugins` é uma ponte legada, só documentação e opt-in. Não é um gate de CI. Knowledge Items ao vivo e a UI de confiança da IDE ficam fora de escopo. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter antigravity`. O `subagents` do registro é `native`. O valor efetivo vem de `Get-Capabilities` (sonda fail-closed).

## Codex

O home de produto ao vivo é `~/.codex`. A descoberta de skills USER é `~/.agents/skills`. Skills de plugin e regras do InstallRoot não são um único `TOOLKIT_ROOT`.

| Caminho relativo | Papel |
|------------------|--------|
| `plugin/.codex-plugin/plugin.json` | Manifesto do plugin (`skills: ./skills/`) |
| `plugin/skills/<kebab-id>/SKILL.md` | Skills empacotadas no plugin |
| `plugin/skills/_shared/skills-catalog/CATALOG.md` e `OPERATOR.md` | Mapa via `help-skills` |
| `rules/*.md` | Política |
| `.agents/plugins/marketplace.json` | Entrada de marketplace local |
| `AGENTS.md` | Caminhos absolutos de raiz dupla, materializados |
| `plugin/hooks/hooks.json` | Hooks do plugin. A confiança `/hooks` é manual |
| `.agents/skills/` | `-UserScope` opcional (ao vivo: `$HOME/.agents/skills` mais `-AllowUserHome`) |

O sync padrão é só plugin. Fixture: `scripts/validation/fixtures/codex`.

## Claude Code

O InstallRoot modela `~/.claude` ou `.claude` do projeto.

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `rules/*.md` | Política (`.md`, não `.mdc`) |
| `CLAUDE.md` | Roteador |
| `hooks/*.ps1` | De `adapters/claude/assets/hooks/` |
| `settings.json` | Upsert chaveado de hooks mais `permissions.allow` aditivo. UTF-8 sem BOM. Backup `.bak` |

Fixture: `scripts/validation/fixtures/claude`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter claude`.

## OpenCode

O InstallRoot modela `~/.config/opencode`.

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `AGENTS.md` | Roteador |
| `agents/*.md` | `Publish-Agents` |
| `plugins/*.js` | Plugins JS. O marcador de compatibilidade não instala hook de autorização |

Hooks são só plugin. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter opencode` (só filesystem).

## ZCode

O InstallRoot modela `~/.zcode` (filesystem ADE, não GLM Coding Plan).

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Roteador |
| `agents/*.md` | Roster |
| `cli/config.json` | Config de hooks |
| `hooks/hooks.json` | Configuração PreToolUse; o Toolkit não decide autorização |

Fixture: `scripts/validation/fixtures/zcode-install-root/`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter zcode`.

## GitHub Copilot

`-Mode user|repo` é obrigatório. A árvore relativa é a mesma sob qualquer raiz.

| Modo | O InstallRoot modela | Fixture |
|------|----------------------|---------|
| `user` | `~/.copilot` | `scripts/validation/fixtures/copilot/user` |
| `repo` | `.github` | `scripts/validation/fixtures/copilot/repo` |

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `instructions/*.instructions.md` | Política |
| `copilot-instructions.md` | Instruções sempre ligadas com o roteador embutido; o Copilot não tem superfície de roteador dedicada (`router=false`) |
| `hooks/*` | Nenhum hook ativo registrado (`HookActivation` `unavailable`); sem decisão de autorização do Toolkit |
| `agents/nome.agent.md` | Um arquivo de agente do catálogo no modo repo. O modo user não publica agentes |

Layouts JetBrains e Eclipse ficam fora de escopo. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter copilot`.

## Grok Build

O InstallRoot é `~/.grok` (ou um `.grok` de projeto que você passa). A árvore é nativa, não aninhada `.grok/.grok`.

| Caminho relativo | Papel |
|------------------|--------|
| `skills` | Skills, ao vivo `~/.grok/skills` |
| `rules` | Política |
| `agents` | Roster |
| `hooks` | Hooks PreToolUse de compatibilidade. `/hooks-trust` é manual |
| `AGENTS.md` | Roteador |

Fixture: `scripts/validation/fixtures/grok`.

## Hermes

O InstallRoot é o home do Hermes. Windows: `%LOCALAPPDATA%\hermes`. POSIX: `~/.hermes`. Skills e `AGENTS.md` ficam direto sob essa raiz.

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Roteador mais política dobrada. Sem árvore `rules/` |
| `plugins/agent-dev-toolkit-guard` | Plugin de compatibilidade; não registra hook; a autorização continua com o Hermes |
| `memories/MEMORY.md` | Semeado uma vez se faltar |
| `SOUL.md` | Nunca criado nem sobrescrito |

`Publish-Agents` é no-op (`agents=false`). O merge de hooks mantém chaves que não são do toolkit e remove entradas antigas de `pre_tool_call` do toolkit. Uma checagem estrutural de `config.yaml` roda antes de qualquer mudança. Subagentes: `delegate_task` do host. Fixture: `scripts/validation/fixtures/hermes`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter hermes`.

## OpenHands

O InstallRoot de projeto é uma árvore de repositório.

| Caminho relativo | Papel |
|------------------|--------|
| `.agents/skills/<id>/SKILL.md` | Skills, não microagents legados |
| `.agents/agents/*.md` | Roster. Não é spawn nativo |
| `AGENTS.md` | Roteador mais política dobrada |
| `.openhands/hooks.json` e `.openhands/hooks/*.sh` | Hooks de shell, incluindo `guard_pre_tool.sh` |
| `.plugin/plugin.json` | Metadados do plugin. As skills funcionam sem o plugin |

Skills de usuário ao vivo: `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` publica `skills/` sob esse home. `subagents=none`. Fixture: `scripts/validation/fixtures/openhands`. Smoke: `Invoke-AdapterCiSmoke.ps1 -Adapter openhands`.

## CI

`.github/workflows/validate-toolkit.yml` roda em `pull_request` para `develop`. A topologia é `validate-core` (`windows-latest`) → `adapter-smoke` (matriz `ubuntu-latest` com os 10 adaptadores) e `adapter-smoke-windows` (só codex); em paralelo, `docs-strict` faz o build estrito do MkDocs. O check agregador `validate` depende de todos os jobs de validação; `ci-ok` depende desses jobs e de `validate`.

O job `validate-core` roda `validate-core.ps1` e depois `Assert-SyncAllowUserHomeForward.ps1`. O smoke de adaptador é o genérico `Invoke-AdapterCiSmoke.ps1 -Adapter <id>`, com raiz descartável em `.adt-work/`.

`docs-strict` instala `docs-site/requirements-docs.txt` e roda `mkdocs build --strict -f docs-site/mkdocs.yml`.

`master-release-ci.yml` emite `ci-ok` em pull requests para `master`/`main` depois de verificar que a origem é `develop`. `enforce-release-source.yml` emite `release-source`; ele valida a origem, os metadados de release e as credenciais e permissões do App de sincronização.

O fluxo normal de release começa quando um PR opt-in de `develop` → `master`/`main` é integrado. `release.yml` verifica as credenciais do App, cria a tag e o release no commit promovido, chama `publish-release-bootstrap.yml` para enviar o zip, o SHA256 e os entrypoints de bootstrap, e solicita um PR normal de reconciliação para `develop`. A reconciliação ocorre após cada PR de release integrado. Se a publicação funcionou, mas a reconciliação falhou, execute `release.yml` a partir do commit promovido em `master`/`main` com `reconcile_only=true` e a versão em branco; isso tenta a reconciliação novamente sem criar outra tag. Falhas apenas no upload dos assets podem ser repetidas por `publish-release-bootstrap.yml` usando a tag existente.

Os workflows emitem checks; rulesets e proteções de branch do GitHub definem quais são obrigatórios. Na verificação de 2026-10-29, `protect-develop` exige `validate`, a proteção legada também exige `ci-ok`, e `protect-release` exige `release-source`. Confira as configurações remotas novamente antes de confiar neste registro.

`.github/workflows/docs.yml` publica este site. É um workflow separado.

Os smokes conferem arquivos publicados nos fixtures. Eles não lançam runtimes de produto.
