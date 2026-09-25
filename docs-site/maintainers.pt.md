---
title: Mantenedores
---

# Mantenedores

O **agent-dev-toolkit** é um toolkit público e somente leitura. Qualquer pessoa pode clonar ou fazer fork e usá-lo localmente. Contribuições upstream não são aceitas. Não abra pull requests esperando revisão ou merge neste repositório.

Licença: MIT © 2026 Raphael Campos.

## Para quem é

| Público | Intenção | Começo |
|---------|----------|--------|
| **Visitante** | Entender o toolkit, clonar ou fazer fork, ler a política | [Início](index.md), [Começar](get-started.md), esta página |
| **Operador** | Sincronizar skills no home de um agente, rodar validação | [Começar](get-started.md), [Adaptadores](adapters.md), [Usando skills](using-skills.md) |
| **Mantenedor** | Mudar este repositório (acesso de escrita) | A seção abaixo. Check obrigatório **`ci-ok`** em `pull_request` para `develop`, `master` e `main` (`.github/workflows/validate-toolkit.yml`). Origem de release: `.github/workflows/enforce-release-source.yml` |

| Tema | Onde |
|------|------|
| Clone / fork permitidos; sem PRs upstream | Esta página |
| Issues são só bugs | Esta página |
| Reporte de vulnerabilidade | Esta página |
| Licença | `LICENSE` (MIT) |
| Instalar, sync, desinstalar | [Começar](get-started.md) |
| Validação e CI | [Arquitetura](architecture.md) |

## Issues (só bugs)

GitHub Issues são para relatos de defeito: sync quebrado, falhas de validação, docs incorretos, erros de runtime.

- Não use Issues para pedidos de feature, RFCs ou propostas de contribuição.
- Não há fluxo de contribuição da comunidade via Issues ou pull requests.
- Vulnerabilidades de segurança seguem a seção de reporte abaixo. Elas não vão em Issues públicas.

Mantenha mudanças locais no seu fork ou numa cópia privada.

## Clone e fork

Você pode:

- Clonar ou fazer fork deste repo para uso pessoal ou de equipe
- Sincronizar skills nos homes dos seus agentes (`~/.cursor`, `~/.claude`, `~/.copilot` e as outras raízes) via `scripts/sync-agent.ps1`
- Customizar skills, política, adaptadores e docs no seu fork

Você não abre pull requests esperando revisão ou merge aqui, e não pede acesso de escrita para contribuições da comunidade.

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1
```

Home ao vivo (opt-in):

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome
```

## Só mantenedores

O desenvolvimento interno usa Git em branches com acesso de escrita.

| Branch | Papel |
|--------|--------|
| `feature/<slug>` ou `feat/<id>` | Branches de trabalho |
| `develop` | Integração |
| `master` / `main` | Release estável |

Pull requests são só de colaboradores. Prefira `/open-github-pr` (depois de `/commit` / `/push`), ou use `.github/PULL_REQUEST_TEMPLATE.md` na UI web. Trabalho de feature e correção aponta para **`develop`**. PRs de release são **`develop` → `master` ou `main`**, impostos por `.github/workflows/enforce-release-source.yml`. `.github/workflows/validate-toolkit.yml` roda em `pull_request` para `develop`, `master` e `main`. O check de CI obrigatório é **`ci-ok`**. Os jobs `validate` e `validate-ubuntu` alimentam esse check. A proteção de branch precisa exigir `ci-ok`, e não só o nome de job `validate`.

## Reportar uma vulnerabilidade

Não abra uma GitHub Issue pública para vulnerabilidades de segurança.

Use o primeiro canal disponível neste repositório:

1. **Reporte privado de vulnerabilidade no GitHub** — quando estiver ligado, use **Security → Advisories → Report a vulnerability**.
2. **Contato com os donos do repositório via GitHub** — se o reporte privado ainda não estiver ligado, fale com um dono pelo perfil no GitHub. Não invente uma caixa de e-mail de segurança.

Nenhum e-mail de segurança dedicado é publicado para este repositório.

Antes de tratar o canal 1 como disponível, os mantenedores:

1. Ligam **Private vulnerability reporting** (**Settings → Code security and analysis → Private vulnerability reporting**).
2. Confirmam que a aba Security mostra **Report a vulnerability** para quem não é colaborador.
3. Mantêm este arquivo honesto. Acrescentam uma caixa postal aqui só quando um endereço real existir.

Inclua:

- Uma descrição do problema e do impacto potencial
- Passos para reproduzir (uma prova de conceito se for seguro compartilhar em privado)
- Caminhos afetados (skills, scripts, adaptadores, docs) quando souber
- Seu contato preferido para retorno

Dê aos mantenedores um tempo razoável para avaliar um relato antes de qualquer divulgação pública.
