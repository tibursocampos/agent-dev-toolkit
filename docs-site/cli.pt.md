---
title: CLI
---

# CLI

`scripts/toolkit.ps1` é o Smart Manager e a entrada não interativa. `scripts/sync-agent.ps1` publica um agente. `scripts/validate-agent.ps1` confere o repositório e depois esse agente. Uninstall chama `Uninstall-Toolkit`.

A instalação por release ou clone está em [Começar](get-started.md). Os layouts por agente estão em [Adaptadores](adapters.md).

## Smart Manager

A opção 0 abre isto depois da extração. A partir de um clone:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

| Menu | O que faz |
|------|-----------|
| **Sync agent** | Publica skills, política e hooks. O assistente escolhe o agente e depois o home ao vivo (Enter é o padrão), um fixture ou um caminho customizado |
| **Validate agent** | `validate-core` mais o smoke do adaptador para um agente |
| **Sync then validate** | Sync e depois o smoke do mesmo alvo |
| **Validate core only** | Só contratos do repositório. Sem escrita no home do agente |
| **Validation lab** | Roda `validate-core` ou um script `Invoke-*CiSmoke` |
| **Uninstall agent** | Remove arquivos chaveados do toolkit no InstallRoot. Mantém `sdd/sessions` e `sdd/manifest.json` |
| **Help and docs** | Explicação no menu das ações e flags |

Caminho seguro para aprender:

1. **Validate core only** — o repositório está saudável e nada é escrito no seu perfil.
2. **Sync agent** → por exemplo `cursor` → **Live agent home** (Enter) → confirme a escrita.
3. Para aprender sem tocar o perfil, escolha **In-repo fixture**.
4. **Validate agent** para o mesmo agente e alvo.

| Ação | Script | Escreve no home do agente? |
|------|--------|----------------------------|
| Validate core | `scripts/validation/validate-core.ps1` | Não |
| Validate agent | `scripts/validate-agent.ps1 -Agent <id>` | Só se você escolheu um InstallRoot ao vivo ou customizado |

### `-Action` não interativo

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action SyncAndValidate -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

Sync, Validate e Uninstall exigem `-Agent` quando você pula o menu.

| Flag | Função |
|------|--------|
| `-Agent` | Id do registro (`cursor`, `claude`, …) |
| `-InstallRoot` | Raiz alvo. Omita e o adaptador usa o fixture no repositório |
| `-AllowUserHome` | Obrigatório quando o InstallRoot cai sob `%USERPROFILE%` / `$HOME` |
| `-Mode` | Obrigatório para `copilot`: `user` ou `repo` |
| `-Quiet` / `-SkipSmoke` | Encaminhados para validate-agent / validate-core |
| `-Action Backup` | Termina com falha, salvo `-ForceStub` (testes). Não chama um adaptador |

Smoke opcional, no estilo da CI, a partir de um clone:

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
```

## Sync

O assistente interativo usa como padrão **[1] Live agent home** (Enter). Confirme antes da escrita. Escolha **[2] In-repo fixture** para deixar o perfil intacto.

Omitir `-InstallRoot` em `sync-agent.ps1` ou em `-Action Sync` usa o fixture em `scripts/validation/fixtures/`. Esse é o padrão seguro para CI. Ele não altera o home ao vivo do agente.

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
```

### Home ao vivo

Caminhos sob `%USERPROFILE%` / `$HOME` são recusados sem `-AllowUserHome`.

Cursor → `~/.cursor`:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

Se você também sincronizar Claude, Codex ou outros agentes, desligue no Cursor **Include third-party Plugins, Skills, and other configs** para as instalações ficarem separadas.

Claude Code → `~/.claude`:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude `
  -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

GitHub Copilot exige `-Mode`:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode user `
  -InstallRoot "$env:USERPROFILE\.copilot" -AllowUserHome

pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode repo `
  -InstallRoot "D:\Source\MyApp\.github"
```

O modo `repo` em geral aponta para a pasta `.github` do repositório consumidor, então `-AllowUserHome` muitas vezes não é necessário.

| Agente | InstallRoot típico |
|--------|--------------------|
| `antigravity` | `$env:USERPROFILE\.gemini` |
| `codex` | `~/.codex` (produto, AGENTS, rules). Skills `$` em `~/.codex/skills`. Skills USER opcionais em `~/.agents/skills` com `-UserScope` e `-AllowUserHome` |
| `opencode` | `$env:USERPROFILE\.config\opencode` |
| `grok` | `$env:USERPROFILE\.grok` |
| `zcode` | `$env:USERPROFILE\.zcode` |
| `hermes` | `$env:USERPROFILE\.hermes` (skills e `AGENTS.md` ficam direto nessa raiz) |
| `openhands` | Árvore do projeto como InstallRoot. Skills de usuário: `$env:USERPROFILE\.agents` com `-AllowUserHome` (as skills caem em `skills/`) |

Inclua `-AllowUserHome` sempre que o InstallRoot cair sob o perfil do usuário. O home ao vivo do Hermes também pode ser `%LOCALAPPDATA%\hermes` ou `$env:HERMES_HOME`. Detalhe: [Adaptadores](adapters.md).

Ensaio:

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -WhatIf
```

## O que o sync publica

| Agente | Artefatos típicos sob o InstallRoot |
|--------|-------------------------------------|
| Cursor | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/`, `hooks.json` |
| Claude | `skills/`, `rules/*.md`, `CLAUDE.md`, `hooks/`, `settings.json` mesclado |
| Copilot | `skills/`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/` |
| Codex | `plugin/` (e marketplace), `skills/` (espelho `$`), `rules/*.md`, `AGENTS.md` materializado. `.agents/skills` opcional com `-UserScope` |
| OpenCode | `skills/`, `AGENTS.md`, `plugins/*.js` |
| Grok | `skills/`, `rules/`, `hooks/`, `AGENTS.md` (o InstallRoot é `~/.grok`) |
| ZCode | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` |
| Hermes | `skills/`, `AGENTS.md` (roteador mais política dobrada; sem `rules/`). Semeia `MEMORY.md` se faltar. Nunca escreve `SOUL.md` |
| OpenHands | Projeto: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/hooks.json` mais `hooks/*.sh`, `.plugin/plugin.json`. Skills de usuário: `skills/` sob `~/.agents` |
| Antigravity | `config/skills`, `config/plugins`, markdown gerido |

Todo sync também prepara `<InstallRoot>/sdd/` (`sessions/` mais `manifest.json`) via `Get-SddRoot -Prepare`.

### Onde os arquivos da feature ficam

Depois do prepare, `manifest.json` (schema **v2**) fica na raiz SDD efetiva (`effective_SDD_ROOT` = `<InstallRoot>/sdd`). As configurações por projeto são `repositories[<cwd>].classic.storage_mode` e `.path`.

| Modo | Onde os artefatos ficam |
|------|-------------------------|
| **repository** | `$Cwd/features/` e `$Cwd/memory-bank/` |
| **global** | Caminho sob a raiz SDD (`classic.path`, em geral `{{SDD_ROOT}}/<repo-id>/`) — `features/` e `memory-bank/` juntos ali |

Use caminhos portáteis no corpo dos artefatos (`features/NNN-slug/US01/PRD/...`). No modo **repository**, o padrão `features_versioned: false` acrescenta `/features/` ao `.gitignore` (mais `/docs/features/` e redes de segurança de PRD/PLAN). Defina `true` para versionar essas árvores. Mantenha sempre `!/docs/documentation-plan/plan.md`. O modo global não edita o `.gitignore` do projeto.

A semente nunca sobrescreve um manifesto existente. Contrato completo: `core/sdd/STORAGE.md`.

## Verificar

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
```

Ou abra **Validation lab** no menu. Depois de um sync ao vivo do Cursor, arquivos como estes devem existir:

```text
%USERPROFILE%\.cursor\AGENTS.md
%USERPROFILE%\.cursor\skills\sdd-spec\SKILL.md
%USERPROFILE%\.cursor\rules\guardrails.mdc
```

Reinicie o agente ou recarregue a janela se as skills não aparecerem. Confie nos hooks na UI do agente se ela pedir. Esse passo de confiança é manual e fica fora da CI.

No primeiro sync, se `preferences.json` não existir sob a raiz SDD, o assistente pergunta **Always orchestrate** (padrão) ou **Adaptive**.

## Abra o projeto e a primeira skill

Abra o repositório da **aplicação** no agente (só este repositório do toolkit não é o projeto consumidor).

A forma canônica é o **id da skill**. Os prefixos do host diferem (`/`, `$`, `use skill`, ferramenta `skill` do OpenCode). Depois do sync do Copilot, rode `/skills reload`. Um exemplo de cada skill está em [Primeiro uso](first-use.md).

Comece uma feature com analyze. Cursor e Claude:

```text
/orchestrate-analyze
```

Codex e ZCode: `$orchestrate-analyze`. OpenCode: `skill({ name: "orchestrate-analyze" })`.

Essa skill classifica o pedido e pergunta. Uma story clara pode usar `/sdd-spec`. Um item de produto, sem entrega de feature, usa `/refine-story`. Os gates, a pergunta de armazenamento e as fases seguintes estão em [Entrega orquestrada](orchestrated-delivery.md).

## Desinstalar

A desinstalação é chaveada em todo adaptador registrado. Ela remove skills, política, arquivos de roteador e hooks geridos pelo toolkit. Ela mantém `sdd/sessions/` e `sdd/manifest.json`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

O menu **Uninstall agent** usa o mesmo assistente de alvo do Sync.

## Depois de `git pull`

Rode o sync de novo para cada agente que você usa. O sync atualiza arquivos geridos no lugar e poda skills geridas que não existem mais em `core/skills/`. Ele mantém `sdd/sessions/` e um `sdd/manifest.json` existente. Todo sync executa `Get-SddRoot -Prepare`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

