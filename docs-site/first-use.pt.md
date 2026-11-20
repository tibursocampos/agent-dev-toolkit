---
title: Primeiro uso
---

# Primeiro uso

Abra o repositório da aplicação no agente depois de [Começar](get-started.md). O primeiro comando lista as skills que o sync instalou:

```text
/adt-help-skills
```

`adt-help-skills` lê `CATALOG.md` e `OPERATOR.md`. Ela não inventa ids. Há **52** skills. Pastas em `core/skills/_shared/` são packs, não skills. Arquivos de roster em `core/agents/` não são ids de skill.

O id é o mesmo em todo host. Cursor e Claude usam o prefixo `/`. Codex e ZCode usam `$`. OpenCode chama a ferramenta `skill`. Os exemplos abaixo usam `/`.

Para trabalho com várias stories, brownfield ou pouco claro, use a [Entrega orquestrada](orchestrated-delivery.md): `adt-orchestrate-analyze`, depois `adt-orchestrate-prepare`, depois `adt-orchestrate-implement`. Classic SDD (`adt-sdd-spec` → `adt-sdd-plan` → `adt-sdd-develop`) também pode ser iniciado diretamente para uma feature clara. As outras linhas são skills para um trabalho. Idioma da sessão, o pai e a compressão opcional estão em [Usando skills](using-skills.md).

## Entrega

| Skill | O que faz | Exemplo |
|-------|-----------|---------|
| `adt-epic-planner` | Descoberta e decomposição opcional de uma iniciativa com várias features; cria um `EPIC.md` navegável | `/adt-epic-planner` |
| `adt-memory-bank` | Cria ou atualiza `memory-bank/`. Para quando o bank está escrito | `/adt-memory-bank` |
| `adt-orchestrate-analyze` | Classifica, pergunta, define `needs_*`, aloca especialistas, aprova o backlog | `/adt-orchestrate-analyze` |
| `adt-orchestrate-prepare` | Arquivos da story, depois um PRD e um PLAN por story aprovada | `/adt-orchestrate-prepare - features/NNN-slug/` |
| `adt-orchestrate-implement` | Um filho `adt-sdd-develop` por passo do PLAN, depois revisão, testes e security | `/adt-orchestrate-implement - features/NNN-slug/` |
| `adt-sdd-spec` | Um PRD. Uso direto quando uma story já está clara | `/adt-sdd-spec - features/NNN-slug/US01/STORY.md` |
| `adt-sdd-plan` | Um PLAN ao lado desse PRD | `/adt-sdd-plan - features/NNN-slug/US01/PRD/PRD_001_slug.md` |
| `adt-sdd-develop` | Exatamente um passo do PLAN | `/adt-sdd-develop - features/NNN-slug/US01/PLAN/PLAN_001_slug.md - Step 1` |
| `adt-read-sdd-artifact` | Um caminho FEATURE, STORY, PRD ou PLAN em `source_context` | `/adt-read-sdd-artifact - features/NNN-slug/FEATURE.md` |
| `adt-refine-story` | Um bug, user story ou story técnica | `/adt-refine-story` |
| `adt-requirement-review` | Desafia uma feature ou story antes do SDD: `--feature` ou `--tech` | `/adt-requirement-review --feature - features/NNN-slug/US01/STORY.md` |
| `adt-split-story-checklist` | Um checklist de dependências sob uma story existente | `/adt-split-story-checklist` |
| `adt-delivery-flow` | Coordena refinamento, planejamento e implementação | `/adt-delivery-flow` |
| `adt-delivery-refine` | Refina a demanda no plano da feature | `/adt-delivery-refine` |
| `adt-delivery-plan` | Completa o mesmo plano para aprovação | `/adt-delivery-plan` |
| `adt-delivery-implement` | Executa o plano aprovado, valida e faz revisão de código | `/adt-delivery-implement` |

Para uma iniciativa, você pode criar um EPIC e depois iniciar O1 para uma feature selecionada: `/adt-orchestrate-analyze - EPIC.md feature001`. O O1 lê a seção dessa feature e o contexto/dependências compartilhados relevantes; o EPIC é opcional e o O1 mantém seus gates usuais.

## Implementação

| Skill | O que faz | Exemplo |
|-------|-----------|---------|
| `adt-developer` | Roteador de stack, ou um script ou HTML pequeno | `/adt-developer` |
| `adt-arduino-developer` | Sketches, bibliotecas e firmware específico de placa Arduino | `/adt-arduino-developer` |
| `adt-dotnet-developer` | .NET pequeno ou médio | `/adt-dotnet-developer` |
| `adt-esp-idf-developer` | Firmware C/C++ nativo com ESP-IDF | `/adt-esp-idf-developer` |
| `adt-java-developer` | Java pequeno ou médio | `/adt-java-developer` |
| `adt-javascript-developer` | Node ou DOM pequeno ou médio | `/adt-javascript-developer` |
| `adt-python-developer` | Python pequeno ou médio | `/adt-python-developer` |
| `adt-react-developer` | React web pequeno ou médio | `/adt-react-developer` |
| `adt-react-native-developer` | React Native ou Expo pequeno ou médio | `/adt-react-native-developer` |
| `adt-angular-developer` | Angular pequeno ou médio | `/adt-angular-developer` |
| `adt-vue-developer` | Vue 3 pequeno ou médio | `/adt-vue-developer` |
| `adt-blazor-developer` | UI Blazor pequena ou média | `/adt-blazor-developer` |
| `adt-electron-developer` | Electron pequeno ou médio | `/adt-electron-developer` |
| `adt-blip-plugin-developer` | Andaime de um plugin Blip React novo | `/adt-blip-plugin-developer` |
| `adt-micropython-developer` | Firmware de dispositivo MicroPython | `/adt-micropython-developer` |

## Revisão, plataforma, git

| Skill | O que faz | Exemplo |
|-------|-----------|---------|
| `adt-code-review` | Revisa um branch. Não edita código | `/adt-code-review` |
| `adt-code-explain` | Compara mudanças selecionadas ou explica código existente sem diff; não emite veredito de revisão | `/adt-code-explain` |
| `adt-test-coverage` | Coverlet .NET. Padrão 80% | `/adt-test-coverage` |
| `adt-run-tests` | Testes da stack detectada. Não edita código | `/adt-run-tests` |
| `adt-repair-dotnet-build` | Build ou teste local, ou um log colado | `/adt-repair-dotnet-build` |
| `adt-refactor` | Um passo seguro de refactor | `/adt-refactor` |
| `adt-performance-profile` | Um caminho quente, depois um micro-benchmark | `/adt-performance-profile` |
| `adt-framework-upgrade` | `audit`, depois `plan`, `migrate`, `validate` | `/adt-framework-upgrade` |
| `adt-api-standards` | Forma HTTP, versão, erros, nomes | `/adt-api-standards` |
| `adt-api-integrate` | Cliente tipado e DTOs a partir de OpenAPI | `/adt-api-integrate` |
| `adt-i18n-manager` | Strings de UI para `.resx` ou `.json` | `/adt-i18n-manager` |
| `adt-containerize` | Dockerfile, `.dockerignore`, compose | `/adt-containerize` |
| `adt-ef-add-migration` | `dotnet ef migrations add` depois da descoberta | `/adt-ef-add-migration` |
| `adt-scaffold-message-handler` | Um consumidor de fila depois dos requisitos | `/adt-scaffold-message-handler` |
| `adt-commit` | Um Conventional Commit em um branch de feature | `/adt-commit` |
| `adt-push` | `git push -u origin HEAD` | `/adt-push` |
| `adt-open-github-pr` | Um pull request com `gh` | `/adt-open-github-pr` |
| `adt-help-skills` | O catálogo instalado, `CATALOG.md` e `OPERATOR.md` | `/adt-help-skills` |
| `adt-settings` | Consulta ou salva o modelo e o esforço gerais dos subagentes, ou volta a herdar | `/adt-settings` |
| `adt-document-plan` | `docs/overview.md` e o plano de documentação | `/adt-document-plan` |
| `adt-document-implement` | Um passo pendente de documentação | `/adt-document-implement` |

São 16 skills de entrega, 15 de implementação e 21 de revisão/plataforma/git: 52 no total. Para uma feature, siga para [Entrega orquestrada](orchestrated-delivery.md).
