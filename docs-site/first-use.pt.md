---
title: Primeiro uso
---

# Primeiro uso

Abra o repositório da aplicação no agente depois de [Começar](get-started.md). O primeiro comando lista as skills que o sync instalou:

```text
/help-skills
```

`help-skills` lê `CATALOG.md` e `OPERATOR.md`. Ela não inventa ids. Há **42** skills. Pastas em `core/skills/_shared/` são packs, não skills. Arquivos de roster em `core/agents/` não são ids de skill.

O id é o mesmo em todo host. Cursor e Claude usam o prefixo `/`. Codex e ZCode usam `$`. OpenCode chama a ferramenta `skill`. Os exemplos abaixo usam `/`.

Uma feature segue a [Entrega orquestrada](orchestrated-delivery.md): `orchestrate-analyze`, depois `orchestrate-deliver`, depois `orchestrate-develop`. As outras linhas são skills para um trabalho. Idioma da sessão, o pai e a compressão opcional estão em [Usando skills](using-skills.md).

## Entrega

| Skill | O que faz | Exemplo |
|-------|-----------|---------|
| `memory-bank-init` | Cria ou atualiza `memory-bank/`. Para quando o bank está escrito | `/memory-bank-init` |
| `orchestrate-analyze` | Classifica, pergunta, define `needs_*`, aloca especialistas, aprova o backlog | `/orchestrate-analyze` |
| `orchestrate-deliver` | Arquivos da story, depois um PRD e um PLAN por story aprovada | `/orchestrate-deliver - features/NNN-slug/` |
| `orchestrate-develop` | Um filho `sdd-develop` por passo do PLAN, depois revisão, testes e security | `/orchestrate-develop - features/NNN-slug/` |
| `sdd-spec` | Um PRD. Uso direto quando uma story já está clara | `/sdd-spec - features/NNN-slug/US01/STORY.md` |
| `sdd-plan` | Um PLAN ao lado desse PRD | `/sdd-plan - features/NNN-slug/US01/PRD/PRD_001_slug.md` |
| `sdd-develop` | Exatamente um passo do PLAN | `/sdd-develop - features/NNN-slug/US01/PLAN/PLAN_001_slug.md - Step 1` |
| `read-sdd-artifact` | Um caminho FEATURE, STORY, PRD ou PLAN em `source_context` | `/read-sdd-artifact - features/NNN-slug/FEATURE.md` |
| `refine-story` | Um bug, user story ou story técnica | `/refine-story` |
| `split-story-checklist` | Um checklist de dependências sob uma story existente | `/split-story-checklist` |

## Implementação

| Skill | O que faz | Exemplo |
|-------|-----------|---------|
| `developer` | Roteador de stack, ou um script ou HTML pequeno | `/developer` |
| `dotnet-developer` | .NET pequeno ou médio | `/dotnet-developer` |
| `java-developer` | Java pequeno ou médio | `/java-developer` |
| `javascript-developer` | Node ou DOM pequeno ou médio | `/javascript-developer` |
| `python-developer` | Python pequeno ou médio | `/python-developer` |
| `react-developer` | React web pequeno ou médio | `/react-developer` |
| `react-native-developer` | React Native ou Expo pequeno ou médio | `/react-native-developer` |
| `angular-developer` | Angular pequeno ou médio | `/angular-developer` |
| `vue-developer` | Vue 3 pequeno ou médio | `/vue-developer` |
| `blazor-developer` | UI Blazor pequena ou média | `/blazor-developer` |
| `electron-developer` | Electron pequeno ou médio | `/electron-developer` |
| `blip-plugin-developer` | Andaime de um plugin Blip React novo | `/blip-plugin-developer` |
| `impeccable` | Design. Escreve `docs/DESIGN-BRIEF.md` e para | `/impeccable` |

## Revisão, plataforma, git

| Skill | O que faz | Exemplo |
|-------|-----------|---------|
| `code-review` | Revisa um branch. Não edita código | `/code-review` |
| `test-coverage` | Coverlet .NET. Padrão 80% | `/test-coverage` |
| `run-tests` | Testes da stack detectada. Não edita código | `/run-tests` |
| `repair-dotnet-build` | Build ou teste local, ou um log colado | `/repair-dotnet-build` |
| `refactor` | Um passo seguro de refactor | `/refactor` |
| `performance-profile` | Um caminho quente, depois um micro-benchmark | `/performance-profile` |
| `framework-upgrade` | `audit`, depois `plan`, `migrate`, `validate` | `/framework-upgrade` |
| `api-standards` | Forma HTTP, versão, erros, nomes | `/api-standards` |
| `api-integrate` | Cliente tipado e DTOs a partir de OpenAPI | `/api-integrate` |
| `i18n-manager` | Strings de UI para `.resx` ou `.json` | `/i18n-manager` |
| `containerize` | Dockerfile, `.dockerignore`, compose | `/containerize` |
| `ef-add-migration` | `dotnet ef migrations add` depois da descoberta | `/ef-add-migration` |
| `scaffold-message-handler` | Um consumidor de fila depois dos requisitos | `/scaffold-message-handler` |
| `commit` | Um Conventional Commit em um branch de feature | `/commit` |
| `push` | `git push -u origin HEAD` | `/push` |
| `open-github-pr` | Um pull request com `gh` | `/open-github-pr` |
| `help-skills` | O catálogo instalado, `CATALOG.md` e `OPERATOR.md` | `/help-skills` |
| `document-plan` | `docs/overview.md` e o plano de documentação | `/document-plan` |
| `document-implement` | Um passo pendente de documentação | `/document-implement` |

São 10 + 13 + 19 = 42. Para uma feature, siga para [Entrega orquestrada](orchestrated-delivery.md).
