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
│    OpenCode · Grok · ZCode · Hermes · OpenHands         │
└──────────────────────────┬──────────────────────────────┘
                           │ InstallRoot (fixture ou ambiente real)
┌──────────────────────────▼──────────────────────────────┐
│  Pasta de instalação: ~/.cursor · ~/.claude · ~/.hermes · … │
│  Codex também: skills do plugin + InstallRoot/rules (dual) │
│           + ~/.agents/skills opcional (UserScope)          │
│  OpenHands: projeto .agents/skills · live ~/.agents        │
└─────────────────────────────────────────────────────────┘
```

## Camadas

| Camada | Papel |
|--------|-------|
| **Core** | Agent Skills (`SKILL.md`), `_shared` (incl. CATALOG via `/help-skills`), policy em markdown, router neutro, contratos SDD — sem caminhos fixos em código de pasta de instalação de IDE |
| **Adaptadores** | Mapeiam core → layout do agente; resolvem placeholders; fazem merge de hooks/settings; uninstall seletivo (arquivos gerenciados) |
| **CLI** | `toolkit.ps1` / `sync-agent` / `validate-agent` — selecionar agente, sync, validar, uninstall |
| **Validação** | Suite de contratos + testes smoke em fixture; a CI nunca exige deploy real em `%USERPROFILE%` para ficar verde |

Após o sync, o router publicado prefere **subagentes especialistas em paralelo** para trabalho multi-facetado (esta sessão permanece como pai). Caps: filhos `*-developer` **≤ 2**; paralelo `orchestrate-*` **≤ 4** (em ondas se houver mais). Resumo humano: [docs/SPAWN.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/SPAWN.md); contrato do agente: `core/skills/_shared/agents/SPAWN.md`. Superfícies de idioma: `core/skills/_shared/agents/LANGUAGE.md` (chat + artefatos = idioma do chat; spawn/receipts **en-US**).

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
| `{{SDD_ROOT}}` | Estado SDD sob InstallRoot (`sessions/`, `preferences.json`, `manifest.json` v2, árvores de features **globais** opcionais) |
| `{{GUARDRAILS_PATH}}` | Path do arquivo de policy de guardrails para o agente de destino |

Em runtime, as skills preferem **`effective_SDD_ROOT`** consciente do host (`<InstallRoot>/sdd`) a um `{{SDD_ROOT}}` baked de outro agente — ver [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) e [core/sdd/STORAGE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/core/sdd/STORAGE.md).

**Artefatos repositório vs global:** no modo **repositório**, Classic `features/` + `memory-bank/` ficam no cwd do projeto da aplicação; no modo **global**, a mesma árvore fica sob `{{SDD_ROOT}}/<repo-id>/`. A pasta `sdd/` do InstallRoot sempre guarda sessions, prefs e o manifesto por repo — não a árvore de features do modo repositório.

## Pontos de entrada

| Script | Propósito |
|--------|-----------|
| `scripts/toolkit.ps1` | Smart Manager (menu interativo) |
| `scripts/sync-agent.ps1` | Publica o core em um InstallRoot de agente |
| `scripts/validate-agent.ps1` | Suite do core + teste smoke de um agente |
| `scripts/validation/validate-core.ps1` | Apenas contratos do repositório (sem escrita no ambiente do agente) |
| `.github/workflows/validate-toolkit.yml` | CI: validate-core, asserts de uninstall, dez testes smoke de agente |

As árvores de instalação por agente (Cursor, Claude, Codex, …) estão na documentação completa de arquitetura e de adaptadores — não são duplicadas aqui. Veja [Adaptadores](../adapters/).

## Documentação completa no GitHub

- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — camadas, placeholders, pontos de entrada, layouts de instalação por agente, CI
- [docs/overview.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/overview.md) — problema, fluxo do operador, restrições de design
- [docs/ADAPTERS.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ADAPTERS.md) — registry, pontos de publicação, tabelas de InstallRoot
