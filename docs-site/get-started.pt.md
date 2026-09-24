# Começar

Baixe o bootstrap de Release (ou clone), valide o repositório, sincronize um agente e invoque uma skill no **projeto da aplicação** que você está construindo.

## Pré-requisitos

Sistemas suportados: **Windows**, **Linux** (Ubuntu, Debian e derivados) e **macOS**.

| Requisito | Notas |
|-----------|--------|
| **PowerShell** | **Windows:** 5.1+ ou **pwsh 7+** (recomendado). **Linux / macOS:** **somente pwsh 7+** — Windows PowerShell 5.1 não existe nesses OS. ([guia de instalação](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)) |
| **Git** | Opcional — só se preferir clonar em vez da Opção 0 |
| **Agente alvo** | Pelo menos um de: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode (ADE), Hermes, OpenHands |

## 0. Bootstrap de Release (recomendado)

Sem clone. Assets fixos: `agent-dev-toolkit.zip` + `agent-dev-toolkit.zip.sha256`. Fluxo: download HTTPS → SHA256 → extract → `toolkit.ps1` interativo (Smart Manager). Sem `gh` / Node / `.exe`. Ver [INSTALL.md § 0](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/INSTALL.md#0-release-bootstrap-https--checksum--toolkit).

**Windows:**

```bat
curl.exe -fsSL -o bootstrap.bat https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.bat
bootstrap.bat
```

(`bootstrap.bat` baixa `bootstrap.ps1` automaticamente se estiver ausente.)

```powershell
curl.exe -fsSL -o bootstrap.ps1 https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1
pwsh -NoProfile -File .\bootstrap.ps1
```

**Linux / macOS:**

```bash
curl -fsSL -o bootstrap.ps1 https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1
pwsh -NoProfile -File ./bootstrap.ps1
# ou bootstrap.sh da mesma URL de Release
```

Sync não interativo em vez do Smart Manager: `-DirectSync -Agent cursor` (adicione `-SyncWhatIf` para smoke seguro). Testes: `-SkipSync` / `-NoExtract`.

## 1. Clone (alternativa)

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Abrir o Smart Manager

A opção 0 abre isto após o extract. A partir de um clone:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
```

| Menu (rótulos em inglês no CLI) | Resultado |
|------|-----------|
| **Validate core only** | Só contratos do repo — **sem** escrita no ambiente do agente |
| **Sync agent** | Publica skills/policy/hooks no alvo escolhido |
| **Validate agent** | `validate-core` + teste smoke do adaptador para um agente |
| **Sync then validate** | Sync e, em seguida, teste smoke no mesmo alvo |
| **Uninstall agent** | Remove arquivos **gerenciados** do toolkit (desinstalação seletiva — não limpa a pasta de instalação inteira) |

## 3. Validar o repositório (seguro)

Confirma que o toolkit está saudável sem escrever no ambiente do agente:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
```

## 4. Sincronizar um agente

### Padrão seguro — fixture in-repo

Sync não interativo **omite** `-InstallRoot` e grava a fixture do adaptador em `scripts/validation/fixtures/`. Use para aprendizado e teste smoke seguro em CI; **não** altera o ambiente real do agente.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
```

No menu interativo, escolha **In-repo fixture** para o mesmo caminho seguro.

### Ambiente real do agente — ativação explícita

Caminhos sob `%USERPROFILE%` / `$HOME` são recusados salvo se você passar `-AllowUserHome` (ou confirmar no wizard). O Sync interativo deixa o menu de alvo em **Live agent home** (pasta de instalação real) por padrão — confirme antes de gravar.

#### Cursor → `~/.cursor`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor `
  -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

#### Claude Code → `~/.claude`

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude `
  -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

#### GitHub Copilot — Mode obrigatório

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode user `
  -InstallRoot "$env:USERPROFILE\.copilot" -AllowUserHome

pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent copilot -Mode repo `
  -InstallRoot "D:\Source\MyApp\.github"
```

No Mode `repo`, o InstallRoot costuma ser a pasta `.github` do repositório da aplicação, então `-AllowUserHome` muitas vezes não é necessário.

#### Outras pastas de instalação real

| Agente | InstallRoot típico |
|--------|---------------------|
| `antigravity` | `$env:USERPROFILE\.gemini` |
| `codex` | `~/.codex` (produto/AGENTS/rules); skills USER opcionais `~/.agents/skills` via `-UserScope` + `-AllowUserHome` — ver [Adaptadores](../adapters/) / [Usando skills](../using-skills/) |
| `opencode` | `$env:USERPROFILE\.config\opencode` |
| `grok` | `$env:USERPROFILE\.grok` |
| `zcode` | `$env:USERPROFILE\.zcode` |
| `hermes` | `$env:USERPROFILE\.hermes` |
| `openhands` | Raiz do repo (skills em `.agents/skills`); usuário live `$env:USERPROFILE\.agents` (skills em `skills/`) |

Sempre adicione `-AllowUserHome` quando o InstallRoot resolver sob o perfil do usuário. Detalhes de layout: [Adaptadores](../adapters/).

### Simulação (dry run)

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -WhatIf
```

## 5. O que é publicado

Todo sync prepara `<InstallRoot>/sdd/` (`sessions/` + seed de `manifest.json` schema v2 quando ausente). Artefatos típicos:

| Agente | Sob InstallRoot |
|--------|-----------------|
| Cursor | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/` |
| Claude | `skills/`, `rules/*.md`, `CLAUDE.md`, hooks + `settings.json` mesclado |
| Copilot | `skills/`, `instructions/`, `copilot-instructions.md` |
| Codex | `plugin/` (+ marketplace), `rules/*.md`, `AGENTS.md` materializado; `.agents/skills` opcional com `-UserScope` (dual-root — skills e rules não compartilham um único TOOLKIT_ROOT) |
| Hermes | `skills/`, `AGENTS.md` (sem árvore `rules/`); plugin `agent-dev-toolkit-guard` + `agent-hooks` path/secrets; `config.yaml` apenas chaves gerenciadas |
| OpenHands | Projeto: `.agents/skills/`, `.agents/agents/`, `AGENTS.md`, `.openhands/hooks` (`guard_pre_tool.sh` path/secrets), `.plugin/plugin.json`. Skills do usuário live: `~/.agents/skills` |
| Outros | Ver [Adaptadores](../adapters/) e [Arquitetura](../architecture/) |

**Armazenamento SDD (primeira gravação Classic):** as skills perguntam **repositório** vs **global** quando o projeto ainda não está no manifesto.

- **Repositório** — `features/` + `memory-bank/` na raiz do projeto da aplicação (cites portáteis como `features/NNN-slug/...`; `.gitignore` padrão pode incluir `/features/` salvo `features_versioned` true)
- **Global** — a mesma árvore sob `{{SDD_ROOT}}/<repo-id>/` (fora do git do projeto; sem editar `.gitignore` do projeto)

Install/sync: [docs/INSTALL.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/INSTALL.md). Layout do core: [docs/domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md). Contrato de storage: [core/sdd/STORAGE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/sdd/STORAGE.md).

## 6. Abrir o projeto da aplicação

Abra o repositório da **aplicação** que você quer alterar (não só este toolkit). Após um sync na instalação real, confira o router + uma skill de exemplo no InstallRoot desse agente (exemplos):

```text
%USERPROFILE%\.claude\CLAUDE.md
%USERPROFILE%\.claude\skills\sdd-spec\SKILL.md
%USERPROFILE%\.claude\skills\help-skills\SKILL.md
```

Ou no Cursor: `%USERPROFILE%\.cursor\AGENTS.md` e `skills\…`. Reinicie ou recarregue o agente se as skills não aparecerem. Aceite os hooks na UI do agente se solicitado.

## 7. Primeira skill

Prefira ids de skill; forma slash quando o host suportar:

```text
help-skills
```

Depois SDD clássico:

```text
sdd-spec
sdd-plan - <prd-path>
sdd-develop - <plan-path> - Step 1
```

Normalização opcional de handoff (mesma trilha — não é um quarto estágio): `read-sdd-artifact` → `source_context` tipado. Invocation (`direct` / `orchestrated`) e provenance (`agreed` / `invented`) ficam dentro desses skill ids — veja [Usando skills](../using-skills/) e [docs/domains/core.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/domains/core.md).

Mudança pequena sem SDD completo: `developer` ou uma skill de stack como `dotnet-developer`. Escolher trilha **Classic SDD** / **Backlog Refine** / **Orchestrated Delivery**: [Usando skills](../using-skills/).

Depois de `commit` e `push`, abra um PR com `open-github-pr` (feature → `develop` = **squash**; release `develop` → `master`/`main` = **rebase**; sempre perguntar auto-merge). Detalhes: [Usando skills](../using-skills/).

## 8. Depois de `git pull`

Reexecute o sync para cada agente que você usa. Sync é **atualização no lugar** (update-in-place): sobrescreve arquivos gerenciados e remove skills gerenciadas que saíram de `core/skills/`. Preserva `sdd/sessions/` e `sdd/manifest.json`.

## 9. Desinstalação (seletiva)

Remove skills, policy/rules, routers e hooks gerenciados pelo toolkit — não a pasta de instalação inteira do agente. Preserva `sdd/sessions/` e `sdd/manifest.json`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

## Solução de problemas

| Sintoma | Correção |
|---------|----------|
| Sync recusa InstallRoot | Adicione `-AllowUserHome` ou confirme no wizard |
| Copilot TE02 | Mode ausente/inválido — passe `-Mode user` ou `-Mode repo` |
| Skills ausentes no IDE | Sync no **ambiente real do agente**; reinicie/aceite os hooks se necessário |
| Esperava escrita no ambiente em run tipo CI | Use fixtures / omita InstallRoot real |

Próximo: [Usando skills](../using-skills/) · [Caveman](../caveman/) · [Adaptadores](../adapters/) · [Créditos](../credits/) · [Mantenedores](../maintainers/)
