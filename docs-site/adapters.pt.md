# Adaptadores

Os adaptadores publicam o **core** compartilhado (skills, policy, router e hooks, quando suportados) no layout de instalação de cada agente. Os orquestradores (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolvem o agente via `adapters/registry.json` e chamam o módulo PowerShell daquela entrada.

Para o fluxo do produto, comece em [Começar](../get-started/). Visão do núcleo e dos adaptadores: [Arquitetura](../architecture/). Depois do sync: [Usando skills](../using-skills/).

## Agentes suportados

| id | Nome de exibição |
|----|------------------|
| `cursor` | Cursor |
| `antigravity` | Antigravity |
| `claude` | Claude Code |
| `codex` | Codex |
| `copilot` | GitHub Copilot |
| `opencode` | OpenCode |
| `grok` | Grok Build |
| `zcode` | ZCode |
| `hermes` | Hermes |
| `openhands` | OpenHands |

Conjunto fechado implementado: estes 10 ids. Cada um tem módulo concreto com publicação e teste smoke no repositório.

## Nota Codex

O Codex é **dual-root**: skills do plugin em `InstallRoot/plugin` (`rules=true` Publish-Policy → `InstallRoot/rules`); pai de produto/AGENTS/hooks é o InstallRoot (live `~/.codex`). Sync padrão é **somente plugin**; `-UserScope` opcional espelha skills para fixture `InstallRoot/.agents/skills` ou live `~/.agents/skills` (exige `-AllowUserHome`). Contrato completo: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) · guia: [Usando skills](../using-skills/).

## Nota Hermes

O InstallRoot live é `$HERMES_HOME` (típico `~/.hermes`). Skills e `AGENTS.md` ficam **direto** nessa raiz. Policy é dobrada em `AGENTS.md` (sem árvore `rules/`). Hooks **são** publicados: plugin `agent-dev-toolkit-guard` + shell `agent-hooks` path/secrets; merge chaveado de `config.yaml` só para `plugins.enabled` / `hooks.pre_tool_call` — nunca SOUL / tokens / gateway. Invoque skills com `/id`. `Publish-Agents` é no-op.

## Nota OpenHands

O InstallRoot de **projeto** é a raiz do repo: skills em `.agents/skills/`, roster em `.agents/agents/`, `AGENTS.md` dobrado, hooks shell em `.openhands/` (incl. `guard_pre_tool.sh` para `pre_tool_use` path/secrets, fail-closed), metadados de plugin em `.plugin/plugin.json`. **Skills do usuário live** usam `-InstallRoot "$env:USERPROFILE\.agents" -AllowUserHome` para skills em `~/.agents/skills`. Canvas **não** é spawn de subagente (`subagents=none`; fallback SPAWN no pai).

## Path/secrets (hosts capazes)

Regras compartilhadas: [`adapters/_shared/guard-rules.md`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/_shared/guard-rules.md) + `GuardCommon.ps1`. Fora do workspace e write sem path = deny. Matriz completa: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md).

## Como o sync funciona

1. Prefira o `scripts/toolkit.ps1` interativo (Smart Manager).
2. Resolve `-Agent <id>` em [`adapters/registry.json`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/registry.json).
3. Carrega o módulo do adaptador (`Publish-*`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`, …).
4. O `InstallRoot` padrão é uma fixture in-repo; caminhos reais sob USERPROFILE exigem `-AllowUserHome` explícito.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent claude
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
# ou: -Agent cursor | copilot | hermes | openhands | …
```

## Árvore de origem

READMEs e módulos por agente ficam no diretório `adapters/` do repositório:

- [adapters/ no GitHub](https://github.com/tibursocampos/agent-dev-toolkit/tree/master/adapters)
- Contrato completo e tabelas de InstallRoot: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md)

Próximo: [Começar](../get-started/) · [Usando skills](../using-skills/) · [Arquitetura](../architecture/)
