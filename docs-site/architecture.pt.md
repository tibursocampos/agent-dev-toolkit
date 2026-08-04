# Arquitetura

**agent-dev-toolkit** mantém um **núcleo** neutro em relação ao agente (skills, policy, router, contratos SDD) e **adaptadores** que o publicam no layout nativo de instalação de cada agente. Operadores sincronizam via CLI; a CI valida contra fixtures, não contra ambientes reais do agente.

Para o fluxo do produto, comece em [Começar](../get-started/). Pontos de publicação por agente: [Adaptadores](../adapters/). Após o sync: [Usando skills](../using-skills/).

## Fluxo em alto nível

```text
┌─────────────────────────────────────────────────────────┐
│  core/                                                  │
│    skills/   policy/   router/   sdd/                   │
└──────────────────────────┬──────────────────────────────┘
                           │ Publish-* (placeholders resolvidos)
┌──────────────────────────▼──────────────────────────────┐
│  adapters/<agent>/  ← registry.json                     │
│    Cursor · Claude · Codex · Copilot · Antigravity ·    │
│    OpenCode · Grok · ZCode                              │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture ou ambiente real)
┌──────────────────────────▼──────────────────────────────┐
│  Pasta de instalação: ~/.cursor · ~/.claude · ~/.copilot · … │
│  Codex também: skills do plugin + InstallRoot/rules (dual) │
│           + ~/.agents/skills opcional (UserScope)          │
└─────────────────────────────────────────────────────────┘
```

## Camadas

| Camada | Papel |
|--------|-------|
| **Core** | Agent Skills (`SKILL.md`), `_shared` (incl. CATALOG via `/help-skills`), policy em markdown, router neutro, contratos SDD — sem caminhos fixos em código de pasta de instalação de IDE |
| **Adaptadores** | Mapeiam core → layout do agente; resolvem placeholders; fazem merge de hooks/settings; uninstall seletivo (arquivos gerenciados) |
| **CLI** | `toolkit.ps1` / `sync-agent` / `validate-agent` — selecionar agente, sync, validar, uninstall |
| **Validação** | Suite de contratos + testes smoke em fixture; a CI nunca exige deploy real em `%USERPROFILE%` para ficar verde |

## Layout do repositório

```text
core/          # skills (kebab), policy, router, contratos sdd
adapters/      # módulos por agente + registry.json + _contract
scripts/       # toolkit.ps1, sync-agent, validate-agent, _lib, validation
docs/          # documentação pública (fonte da verdade para aprofundamentos)
.github/workflows/validate-toolkit.yml
```

## Placeholders de path

O conteúdo do core não deve fixar em código uma única raiz de perfil de usuário de IDE. Os adaptadores resolvem estes placeholders na publicação:

| Placeholder | Significado |
|-------------|-------------|
| `{{TOOLKIT_ROOT}}` | Raiz de instalação do toolkit no agente (destination-aware; Codex separa skills do plugin vs `rules/` em InstallRoot) |
| `{{SDD_ROOT}}` | Raiz de estado SDD (`preferences.json`, `sessions/`, features globais) |
| `{{GUARDRAILS_PATH}}` | Path do arquivo de policy de guardrails para o agente de destino |

## Pontos de entrada

| Script | Propósito |
|--------|-----------|
| `scripts/toolkit.ps1` | Smart Manager (menu interativo) |
| `scripts/sync-agent.ps1` | Publica o core em um InstallRoot de agente |
| `scripts/validate-agent.ps1` | Suite do core + teste smoke de um agente |
| `scripts/validation/validate-core.ps1` | Apenas contratos do repositório (sem escrita no ambiente do agente) |
| `.github/workflows/validate-toolkit.yml` | CI: validate-core, asserts de uninstall, oito testes smoke de agente |

As árvores de instalação por agente (Cursor, Claude, Codex, …) estão na documentação completa de arquitetura e de adaptadores — não são duplicadas aqui. Veja [Adaptadores](../adapters/).

## Documentação completa no GitHub

- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — camadas, placeholders, pontos de entrada, layouts de instalação por agente, CI
- [docs/overview.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/overview.md) — problema, fluxo do operador, restrições de design
- [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) — registry, tiers, pontos de publicação, tabelas de InstallRoot
