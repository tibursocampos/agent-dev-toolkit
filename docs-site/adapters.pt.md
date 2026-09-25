---
title: Adaptadores
---

# Adaptadores

Um adaptador publica o **core** compartilhado no layout de instalação de um agente. `adapters/registry.json` nomeia o agente. O módulo em `adapters/<id>/` faz a publicação. Esta página é esse mapa. Os passos de instalação estão em [Começar](get-started.md).

## Registro

Arquivo: `adapters/registry.json`.

| Campo | Significado |
|-------|-------------|
| `id` | Id da CLI / `-Agent` |
| `displayName` | Rótulo humano |
| `module` | Caminho relativo a `adapters/` |
| `capabilities` | Booleanos `skills`, `rules`, `hooks`, `router`, `plugin`, `agents`, mais a string `subagents` (`native` ou `none`) |
| `publishSurface` | Alvos opcionais de roteador de arquivo inteiro. Antigravity usa blocos de markdown gerido. Copilot dobra o roteador em `copilot-instructions.md` via `Publish-Policy`. O sync registra sha256 em `.toolkit-managed-publish.json`. Uninstall remove um roteador de arquivo inteiro só quando o hash do inventário bate |

## Os dez agentes

Todo agente listado tem um módulo concreto com publicação e um smoke no repositório. O assistente de Sync ao vivo **[1]** resolve `Get-InstallRoots` → `OfficialUserRootPath` (Enter é o home ao vivo). CI e padrões não interativos usam fixtures, salvo `-AllowUserHome`.

| Agente | InstallRoot ao vivo | Skills, regras, hooks | Invocação |
|--------|---------------------|------------------------|-----------|
| `cursor` | `~/.cursor` | `skills/`, `rules/*.mdc`, `hooks.json`, `AGENTS.md` | `/id` |
| `antigravity` | `~/.gemini` | `config/skills`, `config/skills.json`, `config/AGENTS.md`, GUARDRAILS, `config/hooks` PreToolUse | `use skill id` ou `/id` |
| `claude` | `~/.claude` | `skills/`, `rules/`, `CLAUDE.md`, hooks em `settings.json` | `/id` |
| `codex` | `~/.codex` | Raiz dupla: config e hooks sob `~/.codex`; plugin sob `InstallRoot/plugin`; `$` via `~/.codex/skills`; `-UserScope` opcional em `~/.agents/skills`; regras sob `InstallRoot/rules` | `$id` |
| `copilot` | `~/.copilot` ou `.github` | `-Mode user` ou `repo`. `skills/`, `instructions/`, `copilot-instructions.md`, `hooks/` | `/id`, depois `/skills reload` |
| `opencode` | `~/.config/opencode` | `skills/`, `AGENTS.md`, `plugins/` JS | `skill({ name: "…" })` |
| `grok` | `~/.grok` | `skills/`, `rules/`, `hooks/`, `AGENTS.md` | `/id` |
| `zcode` | `~/.zcode` | `skills/`, `AGENTS.md`, `cli/config.json`, `hooks/hooks.json` | `$id` |
| `hermes` | `$HERMES_HOME` (Windows `%LOCALAPPDATA%\hermes`; POSIX `~/.hermes`) | `skills/`, `AGENTS.md` (política dobrada). Semeia `memories/MEMORY.md` se faltar | `/id` |
| `openhands` | Árvore do projeto. Skills de usuário em `~/.agents` | Projeto: `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, hooks `.openhands/`, `.plugin/plugin.json` | Mencione o id da skill |

## Capacidades

| Flag | Intenção |
|------|----------|
| `skills` | Publicar Agent Skills de `core/skills/` |
| `rules` | Publicar política de `core/policy/` |
| `hooks` | Publicar hooks |
| `router` | Publicar material de roteador de `core/router/` |
| `plugin` | Empacotamento de plugin ou extensão |
| `agents` | Publicar markdown de roster de `core/agents/` |
| `subagents` | `native` ou `none`. Padrões de stub nunca inventam `native` |

`subagents` abaixo é a string declarada em `adapters/registry.json`. O valor efetivo do Antigravity pode diferir (sonda mais adiante nesta página).

| Agente | skills | rules | hooks | router | plugin | agents | subagents | Notas |
|--------|--------|-------|-------|--------|--------|--------|-----------|-------|
| `cursor` | true | true | true | true | false | true | `native` | `Publish-Agents` → `InstallRoot/agents/` |
| `antigravity` | true | true | true | true | true | false | `native` | Declarado `native`. `Publish-Agents` é no-op. O valor efetivo pode ser `none` |
| `claude` | true | true | true | true | false | true | `native` | O smoke de hooks é só arquivos. A UI de confiança fica fora de escopo |
| `codex` | true | true | true | true | true | true | `native` | Raiz dupla. `Publish-Agents` → `agents/*.toml`. A confiança `/hooks` é manual |
| `copilot` | true | true | true | false | false | true | `native` | `Publish-Router` é no-op. O modo `repo` publica agents |
| `opencode` | true | false | true | true | true | true | `native` | `HooksSemantics=plugin-only` (lançamento JS) |
| `grok` | true | true | true | true | false | true | `native` | Nativo sob `~/.grok` |
| `zcode` | true | false | true | true | false | true | `native` | `Publish-Policy` é no-op |
| `hermes` | true | true | true | true | true | false | `native` | Política dobrada em `AGENTS.md`. Nunca `SOUL.md` |
| `openhands` | true | true | true | true | true | true | `none` | O único `none` declarado. O roster não é spawn nativo |

### Guarda de caminho e segredos

Regras compartilhadas: `adapters/_shared/guard-rules.md`. Ajudantes: `adapters/_shared/GuardCommon.ps1`. Caminhos fora do workspace, e uma escrita ou exclusão sem caminho resolvível, são negados (fail-closed).

| Agente | Ligação |
|--------|---------|
| Cursor | `preToolUse` Write/Edit/Shell/Delete mais `beforeShellExecution`. `failClosed`. GuardCommon |
| Claude | PreToolUse `Write\|Edit\|Bash\|PowerShell` → `permissionDecision` deny |
| Codex | PreToolUse mais `agents/*.toml` |
| Copilot | hooks `version:1` `preToolUse` |
| OpenHands | `pre_tool_use` mais `guard_pre_tool.sh` |
| ZCode | PreToolUse |
| Grok | PreToolUse |
| OpenCode | Lançamento JS `tool.execute.before` |
| Antigravity | PreToolUse em `config/hooks` |
| Hermes | Plugin `agent-dev-toolkit-guard` mais `agent-hooks`. `config.yaml` chaveado só em `plugins.enabled` / `hooks.pre_tool_call`. Nunca SOUL, tokens ou gateway |

A maioria dos adaptadores declara `subagents: native`. OpenHands declara `none` (SPAWN fica no pai). A capacidade efetiva do Antigravity é fail-closed em `Get-Capabilities`. Ordem da sonda em `core/skills/_shared/agents/SPAWN.md`: override `ADT_ANTIGRAVITY_SUBAGENTS` → versão de produto `>= 2.0.0` quando conhecida → `agy --version` analisável `>= 1.0.0` como proxy do harness 2.0 (a CLI permanece `1.x`; não exija major da CLI ≥ 2) → senão `none`. Antes de 2.0, ou quando a sonda não consegue dizer, o valor efetivo é `none`.

A publicação pode emitir só honestidade de profundidade e threads alinhada ao SPAWN, e herança de modelo (ou omitir o modelo). Tetos: developer ≤ 2, orchestrate ≤ 4. A publicação não fixa um modelo de filho diferente do pai. Ela não emite `delegation.max_spawn_depth` do host nem knobs de config.toml para Hermes, Antigravity (`agents: false`) ou OpenCode.

Honestidade do emissor TRACE:

| Alegação | Hosts |
|----------|--------|
| `emit-trace.ps1` ligado, fail-open | Cursor (`hooks.json` postToolUse / subagentStop). Claude (PostToolUse / SubagentStop) |
| Só o asset, sem fio PostToolUse ao vivo | Codex (`Publish-Hooks` permanece a guarda PreToolUse) |
| Não alegado | OpenHands, OpenCode, Hermes, Grok, Copilot, Antigravity, ZCode |

Assert: `Assert-TraceEmitterFailOpen.ps1`. O arquivo da trilha é `features/NNN-slug/TRACE.jsonl`.

## Comandos públicos

Stub do módulo: `adapters/_contract/AdapterContract.ps1`. Módulos concretos ficam em `adapters/<id>/`.

| Comando | Intenção |
|---------|----------|
| `Get-Capabilities` | Reportar flags. O stub devolve toda flag `false` e `Implemented = false` |
| `Get-InstallRoots` | Resolver raízes oficiais. O stub não escreve caminho |
| `Publish-Skills` | Publicar skills. O stub não escreve |
| `Publish-Policy` | Publicar política. O stub não escreve |
| `Publish-Router` | Publicar o roteador. O stub não escreve |
| `Publish-Agents` | Publicar markdown de roster de `core/agents/` |
| `Publish-Hooks` | Publicar hooks. O stub não escreve |
| `Get-SddRoot` | Resolver ou preparar `<InstallRoot>/sdd` |
| `Invoke-SmokeValidate` | Smoke de um InstallRoot de fixture. Não deve exigir um perfil ao vivo |
| `Uninstall-Toolkit` | Remoção chaveada. Mantém `sdd/sessions` e `sdd/manifest.json` |

Um resultado não implementado é `Success = false`, `Implemented = false`, `ExitCode = 1`, com uma mensagem acionável. Stubs não devem escrever sob o perfil do usuário.

### Raiz SDD

Contratos canônicos: `core/sdd/` (`PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md`). Arquivo público de estado: `manifest.json`. Ajudante: `scripts/_lib/Initialize-SddRootLayout.ps1`.

| Item | Valor |
|------|--------|
| `Get-SddRoot` | Devolve `<InstallRoot>/sdd` (`SddRoot`, `SessionsPath`, `ManifestPath`) |
| `Get-SddRoot -Prepare` | Cria `sdd/sessions/` se faltar. Semeia `manifest.json` (`schema_version: 2`, `repositories` vazio) só quando o arquivo está ausente |
| Sync | `scripts/sync-agent.ps1` sempre chama `Get-SddRoot -Prepare` depois de Publish |
| Uninstall | Precisa manter `sdd/sessions/` e `sdd/manifest.json` |
| Guarda | Prepare respeita `Resolve-InstallRoot` (`-AllowUserHome` sob o perfil do usuário) |

Os placeholders `{{TOOLKIT_ROOT}}`, `{{SDD_ROOT}}` e `{{GUARDRAILS_PATH}}` permanecem em `core/` no disco. Cada adaptador os substitui no destino. Agulhas: `scripts/validation/contracts/must-not-contain-ide.json`.

## Scripts que carregam um módulo

Esses três scripts resolvem um agente no registro e chamam o módulo. O passo a passo de instalação, inclusive exemplos de `-Action`, permanece em [Começar](get-started.md).

| Script | Comportamento |
|--------|----------------|
| `scripts/toolkit.ps1` | Menu ou `-Action` / `-Agent`. Lista os agentes do registro. Sync, Validate e Uninstall exigem um agente. Encaminha Sync e Validate. Uninstall chama `Uninstall-Toolkit`. **Backup** (`-Action Backup`) é um stub fail-closed e não chama um adaptador |
| `scripts/sync-agent.ps1 -Agent <id>` | Carrega a entrada do registro e o módulo, chama `Publish-*` e depois sempre `Get-SddRoot -Prepare`. Adaptadores desconhecidos ou incompletos saem com código diferente de zero e **not implemented** (TE04). O InstallRoot padrão é o fixture no repositório. Um caminho no perfil do usuário sem `-AllowUserHome` é recusado |
| `scripts/validate-agent.ps1 -Agent <id>` | Sempre roda `validate-core` e depois `Invoke-SmokeValidate` contra o InstallRoot de fixture. Um smoke documentado como no-op não falha a execução. Um `-Agent` ausente ou desconhecido ainda aborta (TE01 / TE02) |

## Cursor

| Item | Valor |
|------|--------|
| Módulo | `adapters/cursor/CursorAdapter.ps1` |
| Raiz oficial | `~/.cursor` |
| Fixture | `scripts/validation/fixtures/cursor-install-root` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `agents` true. `plugin` false |
| Artefatos | `skills/`, `rules/*.mdc`, `AGENTS.md`, `agents/*.md`, `hooks/*.ps1`, `hooks.json`, `sdd/` |

```powershell
$cursorFixture = Join-Path $PWD 'scripts\validation\fixtures\cursor-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor -InstallRoot $cursorFixture
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
```

Uninstall remove skills, regras, hooks e `AGENTS.md` do toolkit, e desfaz o merge dos handlers geridos em `hooks.json`. CI: `Assert-CursorKeyedUninstall.ps1`.

## Antigravity

| Item | Valor |
|------|--------|
| Módulo | `adapters/antigravity/AntigravityAdapter.ps1` |
| Raiz oficial | `~/.gemini` |
| Layout | `config/skills`, `config/plugins`, `config/hooks`, `config/skills.json`, `config/AGENTS.md`, `config/GEMINI.md` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `plugin` true. `agents` false |
| `Publish-Agents` | No-op. O spawn do host é `invoke_subagent` |
| `Publish-Hooks` | `config/hooks/hooks.json` mais `guard-pre-tool.ps1` |

A ponte legada `antigravity-ide/plugins` não é um gate de CI nem de smoke padrão. Knowledge Items ao vivo e a UI de confiança da IDE ficam fora de escopo. Fixture: `scripts/validation/fixtures/antigravity-install-root`. Smoke: `Invoke-AntigravityCiSmoke.ps1`.

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent antigravity
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent antigravity
```

## Claude Code

| Item | Valor |
|------|--------|
| Módulo | `adapters/claude/ClaudeAdapter.ps1` |
| Raiz oficial | `~/.claude`. Escopo de projeto: `.claude/` do repo |
| Fixture | `scripts/validation/fixtures/claude/` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `agents` true. `plugin` false |
| Artefatos | `skills/`, `rules/*.md`, `hooks/*.ps1`, `CLAUDE.md`, `agents/*.md`, `settings.json` mesclado |

Merge de `settings.json`: escreve `settings.json.bak` primeiro; upsert chaveado para `UserPromptSubmit`, `PreCompact`, `PostToolUse`, `PreToolUse`; entradas estreitas aditivas em `permissions.allow`, um `Bash(pwsh -NoProfile -File "<InstallRoot>/hooks/<script>")` por hook gerido. O re-sync remove `Bash(pwsh *)` / `Bash(powershell *)` largos e legados, salvo `-AllowBroadShellPermissions`. As outras chaves ficam. A codificação é UTF-8 sem BOM. JSON inválido aborta (TE01). Falha de backup aborta (TE02).

O matcher `PreToolUse` `Write|Edit|Bash|PowerShell` roda `guard-pre-tool.ps1`. A UI de confiança de hooks fica fora do smoke.

```powershell
$claudeFixture = Join-Path $PWD 'scripts\validation\fixtures\claude'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude -InstallRoot $claudeFixture
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
```

## Codex

| Item | Valor |
|------|--------|
| Módulo | `adapters/codex/CodexAdapter.ps1` |
| Home de produto | `~/.codex` |
| Espelho `$` | `InstallRoot/skills` (`~/.codex/skills` ao vivo). O caminho do plugin sozinho não alimenta `$` |
| Skills USER opcionais | `~/.agents/skills` via `-UserScope` e, em home ao vivo, `-AllowUserHome` |
| Fixture | `scripts/validation/fixtures/codex` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `plugin`, `agents` todos true |

O sync padrão é só plugin. `Publish-Agents` escreve `agents/*.toml`. `AGENTS.md` usa caminhos absolutos de raiz dupla e não guarda placeholders `{{…}}`. `/hooks` do Codex é manual. O smoke define `RequiresHooksTrust=false`. Não existe a flag `$skill --menu`.

```powershell
$codexFixture = Join-Path $PWD 'scripts\validation\fixtures\codex'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot $codexFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent codex -InstallRoot $codexFixture
```

## GitHub Copilot

| Item | Valor |
|------|--------|
| Módulo | `adapters/copilot/CopilotAdapter.ps1` |
| Flag obrigatória | `-Mode user` ou `-Mode repo`. Modo ausente ou inválido é TE02 |
| Modo `user` | Modela `~/.copilot`. Fixture `scripts/validation/fixtures/copilot/user` |
| Modo `repo` | Modela `.github`. Fixture `scripts/validation/fixtures/copilot/repo` |
| Capacidades | `skills`, `rules`, `hooks`, `agents` true. `router` e `plugin` false |

O layout relativo é o mesmo nos dois modos: `skills/`, `instructions/*.instructions.md`, `copilot-instructions.md`, `hooks/`. `Publish-Router` é no-op. O texto do roteador é dobrado em `copilot-instructions.md`. `agents/*.md` publica só no modo `repo`. Layouts JetBrains e Eclipse ficam fora de escopo.

```powershell
$copilotUser = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$copilotRepo = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user -InstallRoot $copilotUser
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $copilotRepo
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
```

## OpenCode

| Item | Valor |
|------|--------|
| Módulo | `adapters/opencode/OpenCodeAdapter.ps1` |
| Raiz oficial | `~/.config/opencode` |
| Fixture | `scripts/validation/fixtures/opencode/` |
| Capacidades | `skills`, `hooks`, `router`, `plugin`, `agents` true. `rules` false |
| Hooks | `HooksSemantics=plugin-only`. `plugins/agent-dev-toolkit-marker.js` |
| `Publish-Policy` | No-op |

```powershell
$opencodeFixture = Join-Path $PWD 'scripts\validation\fixtures\opencode'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent opencode -InstallRoot $opencodeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent opencode -InstallRoot $opencodeFixture
```

## ZCode

| Item | Valor |
|------|--------|
| Módulo | `adapters/zcode/ZCodeAdapter.ps1` |
| Raiz oficial | `~/.zcode` |
| Fixture | `scripts/validation/fixtures/zcode-install-root` |
| Capacidades | `skills`, `hooks`, `router`, `agents` true. `rules` e `plugin` false |
| `Publish-Policy` | No-op |

Só filesystem ADE. GLM Coding Plan (endpoint, base URL, MCP) fica fora de escopo. Não use o id de agente `zcode` para esse setup. Uninstall desfaz o merge de `cli/config.json` e `hooks/hooks.json`. CI: `Assert-ZcodeKeyedUninstall.ps1` e `Invoke-ZCodeCiSmoke.ps1`.

```powershell
$zcodeFixture = Join-Path $PWD 'scripts\validation\fixtures\zcode-install-root'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent zcode -InstallRoot $zcodeFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent zcode -InstallRoot $zcodeFixture
```

## Grok Build

| Item | Valor |
|------|--------|
| Módulo | `adapters/grok/GrokAdapter.ps1` |
| Raiz oficial | `~/.grok` (o InstallRoot é esse diretório) |
| Fixture | `scripts/validation/fixtures/grok` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `agents` true. `plugin` false |
| Invocação | `/id` |

Publique direto sob o InstallRoot. Não aninhe `.grok/skills` quando o InstallRoot já é `~/.grok`. `/hooks-trust` é manual. O smoke não escreve `trusted_folders.toml`.

```powershell
$grokFixture = Join-Path $PWD 'scripts\validation\fixtures\grok'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent grok -InstallRoot $grokFixture
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent grok -InstallRoot $grokFixture
```

## Hermes

| Item | Valor |
|------|--------|
| Módulo | `adapters/hermes/HermesAdapter.ps1` |
| Raiz oficial | `HERMES_HOME`, senão Windows `%LOCALAPPDATA%\hermes`, senão `~/.hermes` |
| Fixture | `scripts/validation/fixtures/hermes` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `plugin` true. `agents` false. `subagents` `native` |
| Invocação | `/id`, com `delegate_task` para subagentes |

`Publish-Policy` dobra a política em `AGENTS.md` e acrescenta `adapters/hermes/assets/spawn-bridge.md`. Não escreve uma árvore `rules/`. `GUARDRAILS_PATH` é `InstallRoot/AGENTS.md`. `memories/MEMORY.md` é semeado uma vez se faltar. `SOUL.md` nunca é escrito. Skills do home oficial de usuário não precisam de confiança. Uma cópia de projeto pode chamar `hermes skills trust`. Uma CLI `hermes` ausente pula a confiança e a publicação ainda sucede. Uninstall mantém segredos, `memories/MEMORY.md`, `SOUL.md` e `sdd/*`.

Fora de escopo: tokens de gateway, cron, Kanban, voz e YAML `delegation.*`.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent hermes `
  -InstallRoot "$env:LOCALAPPDATA\hermes" -AllowUserHome
pwsh -NoProfile -File .\scripts\validation\Invoke-HermesCiSmoke.ps1
```

## OpenHands

| Item | Valor |
|------|--------|
| Módulo | `adapters/openhands/OpenHandsAdapter.ps1` |
| Raiz de projeto | `AGENTS.md`, `.agents/skills/`, `.agents/agents/`, `.openhands/`, `.plugin/` |
| Skills de usuário | `~/.agents/skills` via `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` |
| Fixture | `scripts/validation/fixtures/openhands` |
| Capacidades | `skills`, `rules`, `hooks`, `router`, `plugin`, `agents` true. `subagents` `none` |

Hooks são shell, não `.ps1`: `guard_pre_tool.sh` para `pre_tool_use`. As skills funcionam sem o plugin. Canvas e ACP não são spawn de pai para filho. Placeholders resolvem com `TOOLKIT_ROOT` = `InstallRoot/.agents` numa árvore de projeto, e com esse diretório home quando o InstallRoot é `~/.agents` ao vivo (skills em `skills/`, sem um `.agents` aninhado).

Fora de escopo: Automation Server, cron, webhooks do GitHub, YAML de sandbox, segredos de LLM e `.openhands/microagents/` legado.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands
$openhandsFixture = Join-Path $PWD 'scripts\validation\fixtures\openhands'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent openhands -InstallRoot $openhandsFixture
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent openhands `
  -InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenHandsCiSmoke.ps1
```

## Restrições

- O smoke usa um fixture no repositório. Uma CI verde não exige sync de perfil ao vivo.
- O conteúdo publicado nos agentes vem de `core/`.
- Uma escrita em home ao vivo precisa de `-AllowUserHome` e fica fora da CI.
