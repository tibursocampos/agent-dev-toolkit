---
title: First use
---

# First use

Open the application repo in the agent after [Get started](get-started.md). The first command lists the skills that sync installed:

```text
/help-skills
```

`help-skills` reads `CATALOG.md` and `OPERATOR.md`. It does not invent ids. There are **41** skills. Folders under `core/skills/_shared/` are packs, not skills. Roster files under `core/agents/` are not skill ids.

The id is the same on every host. Cursor and Claude prefix `/`. Codex and ZCode prefix `$`. OpenCode calls the `skill` tool. The examples below use `/`.

A feature follows [Orchestrated Delivery](orchestrated-delivery.md): `orchestrate-analyze`, then `orchestrate-deliver`, then `orchestrate-develop`. The other rows are skills you call for one job. Session language, the parent, and optional compression are on [Using skills](using-skills.md).

## Delivery

| Skill | What it does | Example |
|-------|----------------|---------|
| `memory-bank-init` | Create or refresh `memory-bank/`. Stops when the bank is written | `/memory-bank-init` |
| `orchestrate-analyze` | Classify, ask, set `needs_*`, staff specialists, approve the backlog | `/orchestrate-analyze` |
| `orchestrate-deliver` | One PRD and one PLAN per approved story | `/orchestrate-deliver - features/NNN-slug/` |
| `orchestrate-develop` | One `sdd-develop` child per PLAN step | `/orchestrate-develop - features/NNN-slug/` |
| `sdd-spec` | One PRD. Direct use when one story is already clear | `/sdd-spec - features/NNN-slug/US01/STORY.md` |
| `sdd-plan` | One PLAN beside that PRD | `/sdd-plan - features/NNN-slug/US01/PRD/PRD_001_slug.md` |
| `sdd-develop` | Exactly one PLAN step | `/sdd-develop - features/NNN-slug/US01/PLAN/PLAN_001_slug.md - Step 1` |
| `read-sdd-artifact` | One FEATURE, STORY, PRD, or PLAN path into `source_context` | `/read-sdd-artifact - features/NNN-slug/FEATURE.md` |
| `refine-story` | One bug, user story, or technical story | `/refine-story` |
| `split-story-checklist` | A dependency checklist under an existing story | `/split-story-checklist` |

## Implementation

| Skill | What it does | Example |
|-------|----------------|---------|
| `developer` | Stack router, or a small script or HTML change | `/developer` |
| `dotnet-developer` | Small or medium .NET | `/dotnet-developer` |
| `java-developer` | Small or medium Java | `/java-developer` |
| `javascript-developer` | Small or medium Node or DOM | `/javascript-developer` |
| `python-developer` | Small or medium Python | `/python-developer` |
| `react-developer` | Small or medium React web | `/react-developer` |
| `react-native-developer` | Small or medium React Native or Expo | `/react-native-developer` |
| `angular-developer` | Small or medium Angular | `/angular-developer` |
| `vue-developer` | Small or medium Vue 3 | `/vue-developer` |
| `blazor-developer` | Small or medium Blazor UI | `/blazor-developer` |
| `electron-developer` | Small or medium Electron | `/electron-developer` |
| `blip-plugin-developer` | Scaffold a new Blip React plugin | `/blip-plugin-developer` |
| `impeccable` | Design. Writes `docs/DESIGN-BRIEF.md` and stops | `/impeccable` |

## Review, platform, git

| Skill | What it does | Example |
|-------|----------------|---------|
| `code-review` | Review a branch. Does not edit code | `/code-review` |
| `test-coverage` | .NET Coverlet. Default 80% | `/test-coverage` |
| `repair-dotnet-build` | Local build or test, or a pasted log | `/repair-dotnet-build` |
| `refactor` | One safe refactor step | `/refactor` |
| `performance-profile` | A hot path, then a micro-benchmark | `/performance-profile` |
| `framework-upgrade` | `audit`, then `plan`, `migrate`, `validate` | `/framework-upgrade` |
| `api-standards` | HTTP shape, versioning, errors, naming | `/api-standards` |
| `api-integrate` | Typed client and DTOs from OpenAPI | `/api-integrate` |
| `i18n-manager` | UI strings into `.resx` or `.json` | `/i18n-manager` |
| `containerize` | Dockerfile, `.dockerignore`, compose | `/containerize` |
| `ef-add-migration` | `dotnet ef migrations add` after discovery | `/ef-add-migration` |
| `scaffold-message-handler` | A queue consumer after the requirements | `/scaffold-message-handler` |
| `commit` | A Conventional Commit on a feature branch | `/commit` |
| `push` | `git push -u origin HEAD` | `/push` |
| `open-github-pr` | A pull request with `gh` | `/open-github-pr` |
| `help-skills` | The installed catalog, `CATALOG.md` and `OPERATOR.md` | `/help-skills` |
| `document-plan` | `docs/overview.md` and the documentation plan | `/document-plan` |
| `document-implement` | One pending documentation step | `/document-implement` |

That is 10 + 13 + 18 = 41. Next, for a feature: [Orchestrated Delivery](orchestrated-delivery.md).
