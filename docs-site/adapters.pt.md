# Adaptadores

Os adaptadores publicam o **core** compartilhado (skills, policy, router e hooks, quando suportados) no layout de instalação de cada agente. Os orquestradores (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolvem o agente via `adapters/registry.json` e chamam o módulo PowerShell daquela entrada.

Para o fluxo do produto, comece em [Começar](../get-started/). Visão do núcleo e dos adaptadores: [Arquitetura](../architecture/). Depois do sync: [Usando skills](../using-skills/).

## Agentes Tier-1

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

Os oito têm módulos concretos com publicação e teste smoke no repositório.

## Nota Codex

O Codex é **dual-root**: skills do plugin em `InstallRoot/plugin` (`rules=true` Publish-Policy → `InstallRoot/rules`); pai de produto/AGENTS/hooks é o InstallRoot (live `~/.codex`). Sync padrão é **somente plugin**; `-UserScope` opcional espelha skills para fixture `InstallRoot/.agents/skills` ou live `~/.agents/skills` (exige `-AllowUserHome`). Contrato completo: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) · guia: [Usando skills](../using-skills/).

## Como o sync funciona

1. Resolve `-Agent <id>` em [`adapters/registry.json`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/registry.json).
2. Carrega o módulo do adaptador (`Publish-*`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`, …).
3. O `InstallRoot` padrão é uma fixture in-repo; caminhos reais sob USERPROFILE exigem `-AllowUserHome` explícito.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
# ou: -Agent cursor | copilot | codex | …
```

## Árvore de origem

READMEs e módulos por agente ficam no diretório `adapters/` do repositório:

- [adapters/ no GitHub](https://github.com/tibursocampos/agent-dev-toolkit/tree/master/adapters)
- Contrato completo e tabelas de InstallRoot: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md)

Próximo: [Começar](../get-started/) · [Usando skills](../using-skills/) · [Arquitetura](../architecture/)
