# Adaptadores

!!! tip "pt-BR"
    Conteúdo útil em português. A versão em inglês permanece a referência canônica quando houver divergência.

Os adaptadores publicam o **core** compartilhado (skills, policy, router e hooks, quando suportados) no layout de instalação de cada agente. Os orquestradores (`scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`) resolvem o agente via `adapters/registry.json` e chamam o módulo PowerShell daquela entrada.

Para o fluxo do produto, comece em [Começar](../get-started/). Visão do núcleo e dos adapters: [Arquitetura](../architecture/). Depois do sync: [Usando skills](../using-skills/).

## Agentes Tier-1

| id | displayName |
|----|-------------|
| `cursor` | Cursor |
| `antigravity` | Antigravity |
| `claude` | Claude Code |
| `codex` | Codex |
| `copilot` | GitHub Copilot |
| `opencode` | OpenCode |
| `grok` | Grok Build |
| `zcode` | ZCode |

Os oito têm módulos concretos com publish e smoke in-repo.

## Como o sync funciona

1. Resolve `-Agent <id>` em [`adapters/registry.json`](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/adapters/registry.json).
2. Carrega o módulo do adapter (`Publish-*`, `Invoke-SmokeValidate`, `Uninstall-Toolkit`, …).
3. O `InstallRoot` padrão é um fixture in-repo; caminhos vivos em USERPROFILE exigem `-AllowUserHome` explícito.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
```

## Árvore de origem

READMEs e módulos por agente ficam no diretório `adapters` do repositório:

- [adapters/ on GitHub](https://github.com/tibursocampos/agent-dev-toolkit/tree/master/adapters)
- Contrato completo e tabelas de install-root: [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md)

Próximo: [Começar](../get-started/) · [Usando skills](../using-skills/) · [Arquitetura](../architecture/)
