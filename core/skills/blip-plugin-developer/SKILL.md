---
name: blip-plugin-developer
description: Scaffold a new Blip React plugin (create-blip-extension), config:plugin, and SDD handoff to react-developer. Use for new Blip plugins or when invoking /blip-plugin-developer.
---


## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

## Trigger

- User asks for `/blip-plugin-developer`, `blip plugin`, or a **new** Blip React extension
- User wants scaffold + documentation setup before implementation

For **existing** Blip plugin repos ( `blip-ds` in `package.json` ), use `/react-developer` instead.

## Outcome

A correctly scaffolded Blip plugin repo with `config:plugin` applied, profile documented, SDD path chosen, and clear handoff to implementation skills.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Integration overview | `docs/blip-plugin-integration.md` (in target or toolkit repo) |
| Architecture | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/plugin-architecture.md` |
| Design system | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/design-system.md` |
| Iframe messages | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/blip-iframe-messages.md` |
| Auth (Full profile) | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/auth-and-permissions.md` |
| External API | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/external-api-integration.md` |
| Deploy / CI | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/deploy-and-ci.md` |
| React guidelines | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/` — only files needed for scaffold UI |
| Frontend practices | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| Design brief template | `{{TOOLKIT_ROOT}}/skills/impeccable/reference/DESIGN-BRIEF-TEMPLATE.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Branch / commit | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |

**Never by default:** do not preload the full `blip-guidelines/` pack, all `react-guidelines/`, or impeccable command refs. Load architecture + design-system for scaffold; fan-out to auth/iframe/API/deploy only when that profile step runs.

**Progressive load:** integration overview / architecture first; then the Blip row for the active scaffold step.

## Must not (defaults)

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Use `cra-template-blip-plugin` (microbundle) as scaffold default
- Scaffold from any unofficial template URL unless the user provides it
- Skip `npm run config:plugin`
- Skip `sdd-spec` when starting SDD from scratch
- Hand off to Antigravity-only personas
- Mix backend API implementation into the plugin scaffold session
- Prefer org-only CI templates over what the repo already uses

## Working rule

Work with the **local Git repo** and the **detected stack** (`package.json`, existing CI under `.github/workflows`, `azure-pipelines.yml`, etc.). Do not assume remote template clones or org-specific pipelines.

## Process

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### Phase 1 - Scaffold (infrastructure first)

Ask the user **(pt-BR)**:

1. "Onde deseja criar o projeto do plugin? (diretório atual `./` ou informe caminho e nome `<plugin-name>`)"
2. "Qual perfil? **Lite** (página única, sem auth) ou **Full** (multi-rota, AuthProvider, buckets)?"
3. "O plugin consome API REST externa (ex.: .NET) ou apenas resources Blip?"
4. "Template: `npm create blip-extension@latest` (oficial) ou URL de template fornecida por você?"

Wait for answers before running scaffold commands.

**Official scaffold (default):**

```powershell
npm create blip-extension@latest <plugin-name>
cd <plugin-name>
npm install
npm run config:plugin
```

**User-provided template:** only when the user supplies a URL or path. Clone/use that source; do not invent an internal template.

- `config:plugin` replaces `PLUGIN_NAME` in charts and `appsettings.json`
- Remove template `.git` only if the user wants a fresh repo history (`Remove-Item -Recurse -Force .git` on Windows)
- Update `.gitignore` for agent artifacts (`/features/`, safety-net `/PRD/`, `/PLAN/` if desired locally)

**Portal checklist (document for user):**

- Blip portal -> advanced settings -> Plugins JSON
- Register local URL `http://localhost:3000` for dev smoke
- Never commit API keys or portal tokens

**Validate before Phase 2:**

```powershell
npm run build
```

Document manual smoke: `npm start` -> open inside Blip portal -> verify iframe height and toast.

### Phase 2 - Documentation flow

Ask **(pt-BR)**: "Qual fluxo de documentação? (Classic SDD *(formerly Forma A)*, Orchestrated Delivery *(formerly Forma C)*, PRD/brief existente, ou escopo informal?)"

| Choice | Next command (new session each step) |
|--------|--------------------------------------|
| **Classic SDD** *(formerly Forma A)* | `/sdd-spec` -> `/sdd-plan` -> `/sdd-develop` |
| **Orchestrated Delivery** *(formerly Forma C)* | `/orchestrate-analyze` -> `/orchestrate-deliver` -> develop |
| **Existing PRD/brief** | Skip spec; proceed to `sdd-plan` with provided doc |
| **Informal / small** | Document scope in `README.md`; handoff directly to implementation / `developer` |

**Do not** jump to `sdd-plan` without a PRD/spec when starting SDD from scratch.

Record profile (Lite/Full) and API type (Blip resources vs external REST) in PRD or README.

### Phase 3 - Handoff (implementation)

Ask **(pt-BR)** what to implement next. Route by scope:

| Scope | Next step |
|-------|-----------|
| Net-new UI / redesign | `/impeccable shape` -> `docs/DESIGN-BRIEF.md` with `target_stack: react` and Blip/BDS notes in section 9 |
| Plugin implementation | `/react-developer` (auto-loads `blip-guidelines/` when `blip-ds` present) |
| Backend API (.NET) | `/dotnet-developer` in **separate repo** - not in plugin scaffold session |

**DESIGN-BRIEF:** use template at `{{TOOLKIT_ROOT}}/skills/impeccable/reference/DESIGN-BRIEF-TEMPLATE.md`. One session = design **or** implementation, not both.

**External API:** if Phase 1 answer was REST backend, remind user to read `external-api-integration.md` during `react-developer` sessions.

## Complexity profiles

Choose by technical criteria only — not by historic repo names.

| Profile | Criteria |
|---------|----------|
| **Lite** | Single route, BDS web components, no AuthProvider, minimal or no permission gates |
| **Full** | Multi-route, AuthProvider, buckets, `blip-ds-react` (or equivalent wrappers), segment tracking as needed |

Load `auth-and-permissions.md` only for Full profile.

## Handoff

| Situation | Next |
|-----------|------|
| Implement UI/features | `/react-developer` |
| Design new screens | `/impeccable shape` |
| Backend API | `/dotnet-developer` (separate repo) |
| Full SDD feature | `/sdd-spec` |
| Commit (after implementation) | `/commit` |

## Related docs

Toolkit maintainer doc: `docs/blip-plugin-integration.md`
