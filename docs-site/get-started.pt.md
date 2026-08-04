# Começar

Clone o toolkit, valide o repositório, sincronize um agente e invoque uma skill no **projeto da aplicação** que você está construindo.

## Pré-requisitos

| Requisito | Notas |
|-----------|--------|
| **PowerShell** | Windows: 5.1+ ou pwsh 7+. macOS/Linux: pwsh 7+ |
| **Git** | Clonar / atualizar este repositório |
| **Agente alvo** | Pelo menos um de: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode (ADE) |

## 1. Clone

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## 2. Abrir o Smart Manager

Entrada principal — menu interativo (wizards de agente/alvo, Help):

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

Sempre adicione `-AllowUserHome` quando o InstallRoot resolver sob o perfil do usuário. Detalhes de layout: [Adaptadores](../adapters/).

### Simulação (dry run)

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -WhatIf
```

## 5. O que é publicado

Todo sync prepara `<InstallRoot>/sdd/` (`sessions/` + `manifest.json`). Artefatos típicos:

| Agente | Sob InstallRoot |
|--------|-----------------|
| Cursor | `skills/`, `rules/*.mdc`, `AGENTS.md`, `hooks/` |
| Claude | `skills/`, `rules/*.md`, `CLAUDE.md`, hooks + `settings.json` mesclado |
| Copilot | `skills/`, `instructions/`, `copilot-instructions.md` |
| Codex | `plugin/` (+ marketplace), `rules/*.md`, `AGENTS.md` materializado; `.agents/skills` opcional com `-UserScope` (dual-root — skills e rules não compartilham um único TOOLKIT_ROOT) |
| Outros | Ver [Adaptadores](../adapters/) e [Arquitetura](../architecture/) |

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

Mudança pequena sem SDD completo: `developer` ou uma skill de stack como `dotnet-developer`. Escolher Forma A/B/C: [Usando skills](../using-skills/).

Depois de `commit` e `push`, abra um PR com `open-github-pr` (feature → `develop`; modo release `develop` → `master`/`main`). Detalhes: [Usando skills](../using-skills/).

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
| Copilot TE02 | Falha de sync do Copilot (modo ausente) — passe `-Mode user` ou `-Mode repo` |
| Skills ausentes no IDE | Sync no **ambiente real do agente**; reinicie/aceite os hooks se necessário |
| Esperava escrita no ambiente em run tipo CI | Use fixtures / omita InstallRoot real |

Próximo: [Usando skills](../using-skills/) · [Caveman](../caveman/) · [Adaptadores](../adapters/) · [Créditos](../credits/) · [Mantenedores](../maintainers/)
