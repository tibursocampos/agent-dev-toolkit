---
title: Arquitetura
---

# Arquitetura

O **agent-dev-toolkit** é um core neutro de agente, publicado por adaptadores em cada install root do host. Operadores sincronizam com um CLI em PowerShell e depois invocam os mesmos ids de skill no host. Evidência: `core/skills/*/SKILL.md` (**42** skills), `adapters/registry.json` (**10** agentes).

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
.github/workflows/validate-toolkit.yml
.github/workflows/publish-release-bootstrap.yml
.github/workflows/enforce-release-source.yml
```

## Camadas

| Camada | Papel |
|--------|--------|
| Core | Agent Skills (`SKILL.md`), `_shared`, markdown de política, roteador neutro, contratos SDD. Os placeholders ficam na origem |
| Adaptadores | Publicam skills, política, roteador, hooks e agents no layout do host. O smoke usa um InstallRoot de fixture |
| CLI | `scripts/toolkit.ps1` escolhe o agente para sync, validação e desinstalação |
| Install root | Destino. O alvo padrão do sync é um fixture no repositório. Um caminho no perfil do usuário precisa de `-AllowUserHome` |
| CI | `validate-toolkit.yml` em `pull_request` para `master`, `main`, `develop`. Uma execução verde não sincroniza um home ao vivo |

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
- `core/skills/` — 42 skills mais `_shared`. Agentes leem o mapa com `help-skills` (`CATALOG.md` e `OPERATOR.md`).
- `core/policy/` — corpos de regra (`.md`; adaptadores podem normalizar para `.mdc` ou instructions).
- `core/router/` — roteador neutro (`AGENTS.md`). O nome do arquivo no host depende do adaptador.
- `core/sdd/` — `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`, alcançados por `Get-SddRoot`.

Prompts de especialista em `core/agents/` (`architect`, `database`, `repo-analyst`, `security`, `shell-runner`) são publicados quando `agents` é true. `qa_checklist` não tem arquivo de agente.

## Placeholders

O conteúdo do core não grava um home de IDE fixo. Os adaptadores resolvem placeholders na publicação.

| Placeholder | Significado |
|-------------|-------------|
| `{{TOOLKIT_ROOT}}` | Raiz de instalação do toolkit. O Codex separa skills de plugin das regras do InstallRoot |
| `{{SDD_ROOT}}` | Raiz de estado SDD (`preferences.json`, `sessions/`, `manifest.json`, árvore Classic global opcional) |
| `{{GUARDRAILS_PATH}}` | Caminho da política de guardrails para o agente alvo |

Em runtime, as skills resolvem o estado SDD via `effective_SDD_ROOT`, para um caminho gravado de outro agente não vencer. `effective_SDD_ROOT` guarda sessões, preferências e `manifest.json` (schema v2), mais `features/` e `memory-bank/` **globais** opcionais quando `classic.storage_mode` é `global`. O modo **repository** mantém essas árvores sob o `$Cwd` do consumidor.

Agulhas `mustNotContain`: `scripts/validation/contracts/must-not-contain-ide.json`. Suíte do core: `scripts/validation/validate-core.ps1` (alias `validate-all.ps1`). Nomes de marca podem aparecer em regras de coautor. Não são caminhos de home no filesystem.

## Pontos de entrada

- `scripts/toolkit.ps1`
- `scripts/sync-agent.ps1`
- `scripts/validate-agent.ps1`
- `scripts/validation/validate-core.ps1`
- `scripts/validation/Assert-SyncAllowUserHomeForward.ps1`
- `scripts/validation/Invoke-CursorCiSmoke.ps1`
- `scripts/validation/Invoke-AntigravityCiSmoke.ps1`
- `scripts/validation/Invoke-ClaudeCiSmoke.ps1`
- `scripts/validation/Invoke-CodexCiSmoke.ps1`
- `scripts/validation/Invoke-CopilotCiSmokeSuite.ps1`
- `scripts/validation/Invoke-OpenCodeCiSmoke.ps1`
- `scripts/validation/Invoke-GrokCiSmoke.ps1`
- `scripts/validation/Invoke-ZCodeCiSmoke.ps1`
- `scripts/validation/Invoke-HermesCiSmoke.ps1`
- `scripts/validation/Invoke-OpenHandsCiSmoke.ps1`
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
| `hooks/*.ps1` | Inclui `guard-pre-tool.ps1` e `GuardCommon.ps1` |
| `hooks.json` | `preToolUse` e `beforeShellExecution` (`failClosed`) |
| `agents/*.md` | Roster quando `agents=true` |
| `sdd/sessions/` | Sessões (`Get-SddRoot -Prepare`) |
| `sdd/manifest.json` | Semente quando ausente. Nunca sobrescreve um arquivo existente |

Fixture: `scripts/validation/fixtures/cursor-install-root`. Smoke: `Invoke-CursorCiSmoke.ps1` em uma cópia efêmera. A CI não escreve um `~/.cursor` ao vivo e não dirige a UI de confiança de hooks.

## Antigravity

O InstallRoot modela `~/.gemini`.

| Caminho relativo | Papel |
|------------------|--------|
| `config/skills` | Skills em kebab mais `dev_persona` |
| `config/plugins` | Superfície de plugin (GUARDRAILS sob o id do plugin gerido) |
| `config/hooks` | Guarda PreToolUse de caminho e segredos quando `hooks=true` |
| `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` | Descoberta e markdown gerido |

`antigravity-ide/plugins` é uma ponte legada, só documentação e opt-in. Não é um gate de CI. Knowledge Items ao vivo e a UI de confiança da IDE ficam fora de escopo. Smoke: `Invoke-AntigravityCiSmoke.ps1`. O `subagents` do registro é `native`. O valor efetivo vem de `Get-Capabilities` (sonda fail-closed).

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

Fixture: `scripts/validation/fixtures/claude`. Smoke: `Invoke-ClaudeCiSmoke.ps1`.

## OpenCode

O InstallRoot modela `~/.config/opencode`.

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<kebab-id>/SKILL.md` | Skills |
| `AGENTS.md` | Roteador |
| `agents/*.md` | `Publish-Agents` |
| `plugins/*.js` | Plugins JS. `tool.execute.before` lança em caminho e segredos |

Hooks são só plugin. Smoke: `Invoke-OpenCodeCiSmoke.ps1` (só filesystem).

## ZCode

O InstallRoot modela `~/.zcode` (filesystem ADE, não GLM Coding Plan).

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Roteador |
| `agents/*.md` | Roster |
| `cli/config.json` | Config de hooks |
| `hooks/hooks.json` | PreToolUse de caminho e segredos |

Fixture: `scripts/validation/fixtures/zcode-install-root/`. Smoke: `Invoke-ZCodeCiSmoke.ps1`.

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
| `copilot-instructions.md` | Instruções sempre ligadas, a partir da origem do roteador |
| `hooks/*` | `version:1` `preToolUse` de caminho e segredos |

Layouts JetBrains e Eclipse ficam fora de escopo. Smoke: `Invoke-CopilotCiSmokeSuite.ps1`.

## Grok Build

O InstallRoot é `~/.grok` (ou um `.grok` de projeto que você passa). A árvore é nativa, não aninhada `.grok/.grok`.

| Caminho relativo | Papel |
|------------------|--------|
| `skills` | Skills, ao vivo `~/.grok/skills` |
| `rules` | Política |
| `agents` | Roster |
| `hooks` | PreToolUse. `/hooks-trust` é manual |
| `AGENTS.md` | Roteador |

Fixture: `scripts/validation/fixtures/grok`.

## Hermes

O InstallRoot é o home do Hermes. Windows: `%LOCALAPPDATA%\hermes`. POSIX: `~/.hermes`. Skills e `AGENTS.md` ficam direto sob essa raiz.

| Caminho relativo | Papel |
|------------------|--------|
| `skills/<id>/SKILL.md` | Skills |
| `AGENTS.md` | Roteador mais política dobrada. Sem árvore `rules/` |
| `plugins/agent-dev-toolkit-guard` e `agent-hooks/` | Hooks de caminho e segredos |
| `memories/MEMORY.md` | Semeado uma vez se faltar |
| `SOUL.md` | Nunca criado nem sobrescrito |

`Publish-Agents` é no-op (`agents=false`). Subagentes: `delegate_task` do host. Fixture: `scripts/validation/fixtures/hermes`. Smoke: `Invoke-HermesCiSmoke.ps1`.

## OpenHands

O InstallRoot de projeto é uma árvore de repositório.

| Caminho relativo | Papel |
|------------------|--------|
| `.agents/skills/<id>/SKILL.md` | Skills, não microagents legados |
| `.agents/agents/*.md` | Roster. Não é spawn nativo |
| `AGENTS.md` | Roteador mais política dobrada |
| `.openhands/hooks.json` e `.openhands/hooks/*.sh` | Hooks de shell, incluindo `guard_pre_tool.sh` |
| `.plugin/plugin.json` | Metadados do plugin. As skills funcionam sem o plugin |

Skills de usuário ao vivo: `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` publica `skills/` sob esse home. `subagents=none`. Fixture: `scripts/validation/fixtures/openhands`. Smoke: `Invoke-OpenHandsCiSmoke.ps1`.

## CI

`.github/workflows/validate-toolkit.yml` roda em `pull_request` para `master`, `main` e `develop`. Jobs: `validate` (`windows-latest`), `validate-ubuntu` (`ubuntu-latest`), gate `ci-ok`.

O job `validate` no Windows:

1. `validate-core.ps1 -Quiet`
2. Asserts de desinstalação chaveada para Claude, Copilot, Codex, OpenCode, Antigravity, Grok, Cursor, ZCode, Hermes e OpenHands
3. `Assert-SyncAllowUserHomeForward.ps1`
4. Dez smokes de agente (Copilot é uma suíte): Cursor, Antigravity, Claude, Codex, suíte Copilot, OpenCode, Grok, ZCode, Hermes, OpenHands

`validate-ubuntu` roda `Assert-InstallRootSafety.ps1`, `validate-core.ps1 -Quiet` e os mesmos dez smokes de fixture.

`publish-release-bootstrap.yml` envia o zip, o SHA256 e os entrypoints de bootstrap em `release` published e em `workflow_dispatch`. `enforce-release-source.yml` falha salvo se um pull request para `master` ou `main` vier de `develop`.

`.github/workflows/docs.yml` publica este site. É um workflow separado.

Os smokes conferem arquivos publicados nos fixtures. Eles não lançam runtimes de produto.
