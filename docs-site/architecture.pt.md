# Arquitetura

**agent-dev-toolkit** mantém um **núcleo** neutro em relação ao agente (skills, policy, router, contratos SDD) e **adapters** que o publicam no layout nativo de instalação de cada agente. Operadores sincronizam via CLI; a CI valida contra fixtures, não contra lares live.

Para o passeio pelo produto, comece em [Começar](../get-started/). Superfícies de publish por agente: [Adapters](../adapters/). Após o sync: [Usando skills](../using-skills/).

## Fluxo em alto nível

```text
┌─────────────────────────────────────────────────────────┐
│  core/                                                  │
│    skills/   policy/   router/   sdd/                   │
└──────────────────────────┬──────────────────────────────┘
                           │ Publish-* (placeholders resolved)
┌──────────────────────────▼──────────────────────────────┐
│  adapters/<agent>/  ← registry.json                     │
│    Cursor · Claude · Codex · Copilot · Antigravity ·    │
│    OpenCode · Grok · ZCode                              │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture or live home)
┌──────────────────────────▼──────────────────────────────┐
│  Agent home: ~/.cursor · ~/.claude · ~/.copilot · …     │
└─────────────────────────────────────────────────────────┘
```

## Camadas

| Camada | Papel |
|--------|-------|
| **Core** | Agent Skills (`SKILL.md`), `_shared`, policy em markdown, router neutro, contratos SDD — sem paths de lar de IDE hardcoded |
| **Adapters** | Mapeiam core → layout do agente; resolvem placeholders; fazem merge de hooks/settings; uninstall com chave |
| **CLI** | `toolkit.ps1` / `sync-agent` / `validate-agent` — selecionar agente, sync, validar, uninstall |
| **Validation** | Suite de contratos + smokes em fixture; a CI nunca exige deploy live em `%USERPROFILE%` para ficar verde |

## Layout do repositório

```text
core/          # skills (kebab), policy, router, sdd contracts
adapters/      # per-agent modules + registry.json + _contract
scripts/       # toolkit.ps1, sync-agent, validate-agent, _lib, validation
docs/          # public documentation (source of truth for deep dives)
.github/workflows/validate-toolkit.yml
```

## Placeholders de path

O conteúdo do core não deve hardcodar uma única raiz de perfil de usuário de IDE. Os adapters resolvem estes placeholders no publish:

| Placeholder | Significado |
|-------------|-------------|
| `{{TOOLKIT_ROOT}}` | Raiz de instalação do toolkit no agente (skills, rules/policy, router) |
| `{{SDD_ROOT}}` | Raiz de estado SDD (`preferences.json`, `sessions/`, features globais) |
| `{{GUARDRAILS_PATH}}` | Path do arquivo de policy de guardrails para o agente de destino |

## Pontos de entrada

| Script | Propósito |
|--------|-----------|
| `scripts/toolkit.ps1` | Smart Manager (menu interativo) |
| `scripts/sync-agent.ps1` | Publica o core em um InstallRoot de agente |
| `scripts/validate-agent.ps1` | Suite do core + smoke de um agente |
| `scripts/validation/validate-core.ps1` | Apenas contratos do repositório (sem escrita no lar) |
| `.github/workflows/validate-toolkit.yml` | CI: validate-core, asserts de uninstall, oito smokes de agente |

As árvores de instalação por agente (Cursor, Claude, Codex, …) estão na documentação completa de arquitetura e de adapters — não são duplicadas aqui. Veja [Adapters](../adapters/).

## Documentação completa no GitHub

- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — camadas, placeholders, pontos de entrada, layouts de instalação por agente, CI
- [docs/overview.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/overview.md) — problema, fluxo do operador, restrições de design
- [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) — registry, tiers, superfícies de publish, tabelas de InstallRoot
