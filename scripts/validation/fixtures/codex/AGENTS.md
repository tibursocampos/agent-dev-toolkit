# Agent router (L0 index) - agent-dev-toolkit

Lean **L0** router for agents after install under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/`. **Pointers only** — do not paste guideline or skill bodies here. Prefer `/<skill>` (or host equivalent); load shared docs on demand.

**Skill map:** Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md` or invoke `/help-skills`. Do not invent skill names.


## Codex dual-root paths (installed)

Codex InstallRoot `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex` uses dual roots: plugin skills vs InstallRoot rules. Prefer absolute paths below.

| Surface | Absolute path |
|---------|---------------|
| InstallRoot (product / AGENTS / rules parent) | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex |
| Plugin skills TOOLKIT_ROOT | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin |
| Rules (Publish-Policy) | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules |
| Guardrails | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md |
| Skills catalog | E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md |

Do not resolve skill `_shared` paths under InstallRoot/skills or InstallRoot/rules — they live under the plugin skills TOOLKIT_ROOT. Rules and guardrails live under InstallRoot/rules only.

## Language
| Context | Rule |
|---------|------|
| SDD agent artifacts (`features/**` — FEATURE/STORY/PRD/PLAN/CONTINUITY) | Brazilian Portuguese (pt-BR) — `sdd-artifact-language-pt-br.md` |
| Source code, tests, commits, identifiers | English always |
| Project docs (repo documentation folder, README deliverables) | Ask pt-BR or English in skill before writing |
| User-facing chat replies | Brazilian Portuguese (pt-BR) — `user-language-pt-br.md` |

## Formas (workflows)

Three coexisting **Formas**. Classic / Forma C writes land under `features/NNN-slug/` (see `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md`). Decision tree: `/help-skills` + CATALOG Formas section.

| Forma | When | Pipeline |
|-------|------|----------|
| **A** Classic SDD | One feature, clear path | `sdd-spec` → `sdd-plan` → `sdd-develop` |
| **B** Backlog prep | Informal item before SDD | `refine-story` → `split-story-checklist` → A or C |
| **C** Orchestrated | Multi-story / brownfield / specialists | `orchestrate-analyze` → `orchestrate-deliver` → (`orchestrate-develop` \| `sdd-develop`) |

**Checkpoint:** one `sdd-develop` session = one PLAN step. Forma C Step 0 = Memory Bank Gate (`E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md`). O3 parent does **not** implement; children reuse `sdd-develop`.

**Enforcement:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`, `sdd-pipeline-guards.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/SESSION.md`.

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
| Pipeline / modes | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage / manifest | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/STORAGE.md` |
| Session gates | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/SESSION.md` |
| Memory-bank (Forma C) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/sdd-artifacts/MEMORY-BANK.md` |

## Agents / spawn (lazy)

| Topic | Path |
|-------|------|
| Spawn contract (native vs fallback) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SPAWN.md` |
| Roster / `needs_*` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/ROSTER.md` |
| Receipt schema | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/RECEIPT.md` |
| Task `model` param | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/SUBAGENT-MODEL.md` |
| Stack → `*-developer` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/agents/ROUTING.md` |

## Rules (always-on)

Published under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/` after sync-agent (source policy under `core/policy/` where applicable).

| Rule | Path |
|------|------|
| Guardrails (git, write, gates) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md` |
| AI stealth | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/ai-stealth.md` |
| SDD pipeline | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/sdd-pipeline-guards.md` |
| Context management | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/context-management.md` |
| SDD artifact language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/sdd-artifact-language-pt-br.md` |
| User chat language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/user-language-pt-br.md` |
| Branch / commits | `branch-validation.md`, `conventional-commits.md` |
| Caveman Mode | `caveman-mode.md` |

## Skills catalog

Agent SoT: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/plugin/skills/_shared/skills-catalog/CATALOG.md`. Invoke `/help-skills` to present it. Prefer `/<name>`. Compat: `use skill <name>` may still work.

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
