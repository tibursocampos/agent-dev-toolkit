# Começar

Clone o toolkit, valide o repositório, sincronize um agente e invoque uma skill em um projeto **consumidor**.

## Pré-requisitos

| Requisito | Notas |
|-----------|--------|
| **PowerShell** | Windows: 5.1+ ou pwsh 7+. macOS/Linux: pwsh 7+ |
| **Git** | Clonar / atualizar este repositório |
| **Agente alvo** | Pelo menos um de: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode ADE |

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

| Menu | Resultado |
|------|-----------|
| **Validate core only** | Só contratos do repo — **sem** escrita no home do agente |
| **Sync agent** | Publica skills/policy/hooks no alvo escolhido |
| **Validate agent** | `validate-core` + smoke do adapter para um agente |
| **Sync then validate** | Sync e, em seguida, smoke no mesmo alvo |
| **Uninstall agent** | Remove arquivos **chaveados** do toolkit (não limpa o home inteiro) |

## 3. Validar o repositório (seguro)

Confirma que o toolkit está saudável sem escrever no home do agente:

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ValidateCore
```

## 4. Sincronizar um agente

### Padrão seguro — fixture in-repo

Sync não interativo **omite** `-InstallRoot` e grava a fixture do adapter em `scripts/validation/fixtures/`. Use para aprendizado e smoke seguro em CI; **não** altera o home live do agente.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor -Quiet
```

No menu interativo, escolha **In-repo fixture** para o mesmo caminho seguro.

### Home live — opt-in explícito

Caminhos sob `%USERPROFILE%` / `$HOME` são recusados salvo se você passar `-AllowUserHome` (ou confirmar no wizard). O Sync interativo deixa o menu de alvo em **Live agent home** por padrão — confirme antes de gravar.

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

No Mode `repo`, o InstallRoot costuma ser a pasta `.github` do repo consumidor, então `-AllowUserHome` muitas vezes não é necessário.

#### Outros roots live

| Agente | InstallRoot típico |
|--------|---------------------|
| `antigravity` | `$env:USERPROFILE\.gemini` |
| `codex` | `~/.codex` (skills USER: `~/.agents/skills`) |
| `opencode` | `$env:USERPROFILE\.config\opencode` |
| `grok` | `$env:USERPROFILE\.grok` |
| `zcode` | `$env:USERPROFILE\.zcode` |

Sempre adicione `-AllowUserHome` quando o InstallRoot resolver sob o perfil do usuário. Detalhes de layout: [Adapters](../adapters/).

### Dry run

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
| Outros | Ver [Adapters](../adapters/) e [Arquitetura](../architecture/) |

## 6. Abrir um projeto consumidor

Abra o repositório da **aplicação** que você quer alterar (não só este toolkit). Após um sync live do Cursor, confira arquivos como:

```text
%USERPROFILE%\.cursor\AGENTS.md
%USERPROFILE%\.cursor\skills\sdd-spec\SKILL.md
```

Reinicie ou recarregue o agente se as skills não aparecerem. Confie nos hooks na UI do agente se solicitado.

## 7. Primeira skill

```text
/sdd-spec
```

Depois planeje e implemente um passo:

```text
/sdd-plan - <prd-path>
/sdd-develop - <plan-path> - Step 1
```

Mudança pequena sem SDD completo: `/developer` ou uma skill de stack como `/dotnet-developer`. Escolher Forma A/B/C: [Usando skills](../using-skills/).

Depois de `/commit` e `/push`, abra um PR com `/open-github-pr` (feature → `develop`; modo release `develop` → `master`/`main`). Detalhes: [Usando skills](../using-skills/).

## 8. Depois de `git pull`

Reexecute o sync para cada agente que você usa. Sync é **update-in-place**: sobrescreve arquivos gerenciados e remove skills gerenciadas que saíram de `core/skills/`. Preserva `sdd/sessions/` e `sdd/manifest.json`.

## 9. Uninstall (chaveado)

Remove skills, policy/rules, routers e hooks gerenciados pelo toolkit — não o home inteiro do agente. Preserva `sdd/sessions/` e `sdd/manifest.json`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude
```

## Troubleshooting

| Sintoma | Correção |
|---------|----------|
| Sync recusa InstallRoot | Adicione `-AllowUserHome` ou confirme no wizard |
| Copilot TE02 | Passe `-Mode user` ou `-Mode repo` |
| Skills ausentes no IDE | Sync no **home live**; reinicie/confie nos hooks se necessário |
| Esperava escrita no home em run tipo CI | Use fixtures / omita InstallRoot live |

Próximo: [Usando skills](../using-skills/) · [Adapters](../adapters/) · [Maintainers](../maintainers/)
