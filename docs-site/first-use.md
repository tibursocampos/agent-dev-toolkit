---
title: First use
---

# First use

Open the application repo in the agent after [Get started](get-started.md). The first command lists the skills that sync installed:

```text
/adt-help-skills
```

`adt-help-skills` reads `CATALOG.md` and `OPERATOR.md`. It does not invent ids. There are **52** skills. Folders under `core/skills/_shared/` are packs, not skills. Roster files under `core/agents/` are not skill ids.

The id is the same on every host. Cursor and Claude prefix `/`. Codex and ZCode prefix `$`. OpenCode calls the `skill` tool. The examples below use `/`.

For multi-story, brownfield, or unclear work, use [Orchestrated Delivery](orchestrated-delivery.md): `adt-orchestrate-analyze`, then `adt-orchestrate-prepare`, then `adt-orchestrate-implement`. Classic SDD (`adt-sdd-spec` → `adt-sdd-plan` → `adt-sdd-develop`) is also valid directly for a clear feature. The other rows are skills you call for one job. Session language, the parent, and optional compression are on [Using skills](using-skills.md).

## Delivery

| Skill | What it does | Example |
|-------|----------------|---------|
| `adt-epic-planner` | Optional discovery and decomposition for a multi-feature initiative; writes a navigable `EPIC.md` | `/adt-epic-planner` |
| `adt-memory-bank` | Create or refresh `memory-bank/`. Stops when the bank is written | `/adt-memory-bank` |
| `adt-orchestrate-analyze` | Classify, ask, set `needs_*`, staff specialists, approve the backlog | `/adt-orchestrate-analyze` |
| `adt-orchestrate-prepare` | Story files, then one PRD and one PLAN per approved story | `/adt-orchestrate-prepare - features/NNN-slug/` |
| `adt-orchestrate-implement` | One `adt-sdd-develop` child per PLAN step, then review, tests, and security | `/adt-orchestrate-implement - features/NNN-slug/` |
| `adt-sdd-spec` | One PRD. Direct use when one story is already clear | `/adt-sdd-spec - features/NNN-slug/US01/STORY.md` |
| `adt-sdd-plan` | One PLAN beside that PRD | `/adt-sdd-plan - features/NNN-slug/US01/PRD/PRD_001_slug.md` |
| `adt-sdd-develop` | Exactly one PLAN step | `/adt-sdd-develop - features/NNN-slug/US01/PLAN/PLAN_001_slug.md - Step 1` |
| `adt-read-sdd-artifact` | One FEATURE, STORY, PRD, or PLAN path into `source_context` | `/adt-read-sdd-artifact - features/NNN-slug/FEATURE.md` |
| `adt-refine-story` | One bug, user story, or technical story | `/adt-refine-story` |
| `adt-requirement-review` | Challenge one feature or story before SDD: `--feature` or `--tech` | `/adt-requirement-review --feature - features/NNN-slug/US01/STORY.md` |
| `adt-split-story-checklist` | A dependency checklist under an existing story | `/adt-split-story-checklist` |
| `adt-delivery-flow` | Coordinate refinement, planning and implementation | `/adt-delivery-flow` |
| `adt-delivery-refine` | Refine the demand in the feature plan | `/adt-delivery-refine` |
| `adt-delivery-plan` | Complete the same plan for approval | `/adt-delivery-plan` |
| `adt-delivery-implement` | Execute the approved plan, validate and run code review | `/adt-delivery-implement` |

For an initiative, you can create an EPIC and then start O1 for one selected feature: `/adt-orchestrate-analyze - EPIC.md feature001`. O1 reads that feature section and relevant shared context/dependencies; the EPIC is optional, and O1 keeps its usual gates.

## Implementation

| Skill | What it does | Example |
|-------|----------------|---------|
| `adt-developer` | Stack router, or a small script or HTML change | `/adt-developer` |
| `adt-arduino-developer` | Arduino sketches, libraries, and board-specific firmware | `/adt-arduino-developer` |
| `adt-dotnet-developer` | Small or medium .NET | `/adt-dotnet-developer` |
| `adt-esp-idf-developer` | Native ESP-IDF C/C++ firmware | `/adt-esp-idf-developer` |
| `adt-java-developer` | Small or medium Java | `/adt-java-developer` |
| `adt-javascript-developer` | Small or medium Node or DOM | `/adt-javascript-developer` |
| `adt-python-developer` | Small or medium Python | `/adt-python-developer` |
| `adt-react-developer` | Small or medium React web | `/adt-react-developer` |
| `adt-react-native-developer` | Small or medium React Native or Expo | `/adt-react-native-developer` |
| `adt-angular-developer` | Small or medium Angular | `/adt-angular-developer` |
| `adt-vue-developer` | Small or medium Vue 3 | `/adt-vue-developer` |
| `adt-blazor-developer` | Small or medium Blazor UI | `/adt-blazor-developer` |
| `adt-electron-developer` | Small or medium Electron | `/adt-electron-developer` |
| `adt-blip-plugin-developer` | Scaffold a new Blip React plugin | `/adt-blip-plugin-developer` |
| `adt-micropython-developer` | MicroPython device firmware | `/adt-micropython-developer` |

## Review, platform, git

| Skill | What it does | Example |
|-------|----------------|---------|
| `adt-code-review` | Review a branch. Does not edit code | `/adt-code-review` |
| `adt-code-explain` | Compare selected changes or explain existing code without a diff; no review verdict | `/adt-code-explain` |
| `adt-test-coverage` | .NET Coverlet. Default 80% | `/adt-test-coverage` |
| `adt-run-tests` | Detected-stack tests. Does not edit code | `/adt-run-tests` |
| `adt-repair-dotnet-build` | Local build or test, or a pasted log | `/adt-repair-dotnet-build` |
| `adt-refactor` | One safe refactor step | `/adt-refactor` |
| `adt-performance-profile` | A hot path, then a micro-benchmark | `/adt-performance-profile` |
| `adt-framework-upgrade` | `audit`, then `plan`, `migrate`, `validate` | `/adt-framework-upgrade` |
| `adt-api-standards` | HTTP shape, versioning, errors, naming | `/adt-api-standards` |
| `adt-api-integrate` | Typed client and DTOs from OpenAPI | `/adt-api-integrate` |
| `adt-i18n-manager` | UI strings into `.resx` or `.json` | `/adt-i18n-manager` |
| `adt-containerize` | Dockerfile, `.dockerignore`, compose | `/adt-containerize` |
| `adt-ef-add-migration` | `dotnet ef migrations add` after discovery | `/adt-ef-add-migration` |
| `adt-scaffold-message-handler` | A queue consumer after the requirements | `/adt-scaffold-message-handler` |
| `adt-commit` | A Conventional Commit on a feature branch | `/adt-commit` |
| `adt-push` | `git push -u origin HEAD` | `/adt-push` |
| `adt-open-github-pr` | A pull request with `gh` | `/adt-open-github-pr` |
| `adt-help-skills` | The installed catalog, `CATALOG.md` and `OPERATOR.md` | `/adt-help-skills` |
| `adt-settings` | Show or save the general model and effort for subagents, or return to inheriting | `/adt-settings` |
| `adt-document-plan` | `docs/overview.md` and the documentation plan | `/adt-document-plan` |
| `adt-document-implement` | One pending documentation step | `/adt-document-implement` |

That is 16 delivery skills, 15 implementation skills, and 21 review/platform/git skills: 52 total. Next, for a feature: [Orchestrated Delivery](orchestrated-delivery.md).
