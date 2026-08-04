# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `{{TOOLKIT_ROOT}}/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer `/<skill>` (or host equivalent); load shared docs on demand.

**Skill map:** Read `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md` or invoke `/help-skills`. Do not invent skill names.

## Language

| Context | Rule |
|---------|------|
| SDD agent artifacts (`features/**` — FEATURE/STORY/PRD/PLAN/CONTINUITY) | Brazilian Portuguese (pt-BR) — `sdd-artifact-language-pt-br.mdc` |
| Source code, tests, commits, identifiers | English always |
| Project docs (repo documentation folder, README deliverables) | Ask pt-BR or English in skill before writing |
| User-facing chat replies | Brazilian Portuguese (pt-BR) — `user-language-pt-br.mdc` |

## Formas (workflows)

Three coexisting **Formas**. Classic / Forma C writes land under `features/NNN-slug/` (see `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: `/help-skills` + CATALOG Formas section.

| Forma | When | Pipeline |
|-------|------|----------|
| **A** Classic SDD | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **B** Backlog prep | Informal item before SDD | `refine-story` → `split-story-checklist` → A or C |
| **C** Orchestrated | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

**Checkpoint:** one `sdd-develop` session = one PLAN step. Forma C Step 0 = Memory Bank Gate (`{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`.

**Enforcement:** `{{GUARDRAILS_PATH}}`, `sdd-pipeline-guards.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`.

### Shortcut - small work

| Need | Skill |
|------|--------|
| Skill map / catalog | `help-skills` — `/help-skills` |
| Stack router / ad-hoc | `developer` — `/developer` |
| Explicit .NET | `dotnet-developer` — `/dotnet-developer` |
| Explicit Java | `java-developer` — `/java-developer` |
| Frontend UI design | `impeccable` — `/impeccable` → `DESIGN-BRIEF.md` → stack `*-developer` |
| Blip React plugin | `blip-plugin-developer` — `/blip-plugin-developer` → `react-developer` |

### Optional flows (index)

| Flow | Entry skills |
|------|----------------|
| Repo documentation (RAG) | `document-plan` → `document-implement` |
| Build / test | `repair-dotnet-build` → optional `commit` / `push` |
| EF migration | `ef-add-migration` |
| Message consumer | `scaffold-message-handler` |

## SDD contracts (lazy)

| Topic | Path |
|-------|------|
| Pipeline / modes | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage / manifest | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md` |
| Memory-bank (Forma C) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |

## Agents / spawn (lazy)

| Topic | Path |
|-------|------|
| Spawn contract (native vs fallback) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Roster / `needs_*` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `{{TOOLKIT_ROOT}}/skills/_shared/agents/RECEIPT.md` |
| Task `model` param | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published under `{{TOOLKIT_ROOT}}/rules/` after sync-agent (source policy under `core/policy/` where applicable).

| Rule | Path |
|------|------|
| Guardrails (git, write, gates) | `{{GUARDRAILS_PATH}}` |
| AI stealth | `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc` |
| SDD pipeline | `{{TOOLKIT_ROOT}}/rules/sdd-pipeline-guards.mdc` |
| Context management | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| SDD artifact language | `{{TOOLKIT_ROOT}}/rules/sdd-artifact-language-pt-br.mdc` |
| User chat language | `{{TOOLKIT_ROOT}}/rules/user-language-pt-br.mdc` |
| Branch / commits | `branch-validation.mdc`, `conventional-commits.mdc` |
| Caveman Mode | `caveman-mode.mdc` |

## Skills catalog

Agent SoT: `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md`. Invoke `/help-skills` to present it. Prefer `/<name>`. Compat: `use skill <name>` may still work.

| Group | Examples |
|-------|----------|
| Catalog | `help-skills` |
| Classic SDD | `sdd-spec`, `sdd-plan`, `sdd-develop` |
| Forma C | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` |
| Stack developers | `developer`, `dotnet-developer`, `java-developer`, `react-developer`, `react-native-developer`, `angular-developer`, `vue-developer`, `blazor-developer`, `electron-developer`, `javascript-developer`, `python-developer`, `blip-plugin-developer` |
| Ops / quality | `code-review`, `repair-dotnet-build`, `test-coverage`, `commit`, `push`, `open-github-pr`, `refactor`, `performance-profile`, `containerize`, `i18n-manager`, `api-integrate` |
| Design / docs / backlog | `impeccable`, `document-plan`, `document-implement`, `refine-story`, `split-story-checklist`, `ef-add-migration`, `scaffold-message-handler` |

## Post-sync validation

Neutral host sync (not Cursor-only):

```powershell
.\scripts\sync-agent.ps1 -Agent <agent-id>
.\scripts\validation\validate-all.ps1
```

Or interactive: `.\scripts\toolkit.ps1`
