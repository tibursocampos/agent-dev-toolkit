---
title: Using skills
---

# Using skills

Invoke skills by **id** (kebab-case under `core/skills/`). The id is the same on every host. The prefix is host-specific (`/`, `$`, `use skill`, or the OpenCode `skill` tool). Compat on many hosts: `use skill <id>`, or natural language that matches the skill description.

After any sync, invoke **`help-skills`**. It reads the installed catalog (`CATALOG.md` and `OPERATOR.md`). There are **42** invocable skills. Folders under `core/skills/_shared/` are packs, not skills. The architect, database, security, repo-analyst, and shell-runner files under `core/agents/` are roster roles, not skill ids.

Codex `/hooks` and Grok `/hooks-trust` are hooks-trust screens. They are not skill shortcuts. Codex has no `$skill --menu` flag. The `$` / `/skills` picker is the product menu.

Install: [Get started](get-started.md). One example of each skill: [First use](first-use.md). The feature path: [Orchestrated Delivery](orchestrated-delivery.md). Commands for sync, validate, and uninstall: [CLI](cli.md).

## Prerequisites

1. Sync at least one agent ([Get started](get-started.md)).
2. Open a **consumer** project in that agent.
3. Optional: run `validate-agent.ps1` against a fixture or a live InstallRoot.

## Where a skill runs

Install roots and publish layouts are on [Adapters](adapters.md). Sync, validate, and uninstall commands are on [CLI](cli.md).

The id is the same on every host. Cursor and Claude prefix `/`. Codex and ZCode prefix `$`. OpenCode calls the `skill` tool. Antigravity accepts `use skill <id>` or `/id`. After a Copilot sync, run `/skills reload`.

## Which skill

```text
Feature
  └─ orchestrate-analyze
        ├─ classifies, asks, sets needs_*, specialists, story gates, sim
        ├─ trivial one-file → /developer (only if you pick that shortcut)
        ├─ one already-clear story → sdd-spec
        └─ approved backlog → orchestrate-deliver
              └─ story files, sdd-spec, contest the PRD, sdd-plan → orchestrate-develop
                    └─ one sdd-develop step per child → code-review, run-tests, security
```

### Orchestrated Delivery

```text
orchestrate-analyze
orchestrate-deliver - features/NNN-slug/
orchestrate-develop - features/NNN-slug/
```

Analyze classifies, asks, sets `needs_*`, calls specialists when flags require them, and waits for backlog **sim**. Story folders wait until the feature has no open question. Deliver checks each story’s files, runs `sdd-spec`, contests that PRD, and runs `sdd-plan`. Develop runs one `sdd-develop` step per child. Gates, folders, and confirmations: [Orchestrated Delivery](orchestrated-delivery.md).

When analyze sets greenfield or `needs_domain` and no ARCH style exists, the **architect** roster role returns a draft. You answer **sim** before the style is approved. Brownfield mirrors the existing style. The parent stays coordinator.

On the four open-question gates, any unanswered question, including **MINOR**, stops the next artifact (`open_question`). Outside those gates, open clarification **B** or **I** stops PRD and PLAN writes (`NEEDS_CLARIFICATION`) and **MINOR** may remain. Readiness is not `step_confirmed`.

### Direct Classic SDD

Use this when one story is already clear. The same three skills run inside deliver and develop. Direct context does not require a memory bank. A missing specialist folder is a question. Orchestrated calls return to O1 instead.

| Order | Skill | Output |
|-------|--------|--------|
| 1 | `sdd-spec` | `features/NNN-slug/USnn/PRD/NNN_slug.md` |
| 2 | `sdd-plan` | `features/NNN-slug/USnn/PLAN/PLAN_NNN_slug.md` |
| 3 | `sdd-develop` | One PLAN step: code, tests, PLAN progress |
| — | `read-sdd-artifact` | Read-only `source_context` |

Default story folder when unspecified is `US01` (`TSnn` for a technical story). Root-level `PRD/` or `PLAN/` folders are invalid.

```text
sdd-spec
sdd-plan - features/NNN-slug/US01/PRD/NNN_slug.md
sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
read-sdd-artifact - features/NNN-slug/US01/PRD/NNN_slug.md
```

`sdd-spec` writes what and why, a stable `REQ-NNN`, out of scope, then waits for **sim** / **ajustar** / **cancelar**. It runs `scripts/validation/validate-prd.ps1`. Brownfield also writes `features/NNN-slug/CHANGE.md` and runs `validate-change.ps1`. It does not write a PLAN in the same session.

`sdd-plan` requires a canonical PRD whose status is ready for planning. The PLAN number matches the PRD and lives in the same story folder. Each step is one later `sdd-develop` session. SQL, DDL, JSON, and OpenAPI stay in a canonical file. The PLAN cites that path. **sim** before write. `validate-plan` must pass before `/sdd-develop`.

`sdd-develop` needs the canonical PLAN path and a step id. One session completes one step. After **sim**, `scripts/session/Invoke-DevelopSessionGate.ps1` stores `step_confirmed`. When a claim is required, `scripts/ledger/Invoke-PlanLedgerClaim.ps1 -Action claim` runs. Use a feature branch (`feature/<slug>` or `feat/<id>`). Load one guideline file for the step. When the step claims acceptance coverage, or evidence level is `cheap` or higher, update `EVD/` and `STATE.md` and run `validate-evidence.ps1`. Levels: `off`, `cheap`, `standard`, `strict`. When the step closes the feature wave, append `TRACE.jsonl` and run `validate-trace.ps1 -RequireArchiveComplete`. OpenSpec, `.specs/`, and SQLite are not the trace source of truth.

`read-sdd-artifact` has no **sim** gate. Kinds allowed: FEATURE, STORY, PRD, PLAN. Reject reasons: `path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path`.

Preflight `Invoke-PrdPlanChangePreflight.ps1` is an O2 check on top of `validate-prd`, `validate-plan`, and `validate-change`. It is not a fourth skill.

### One product item

O1 already applies the scorecard. Invoke `refine-story` when shaping a single backlog item, or when deliver stopped on open **B** / **I**.

Mode is mandatory. If you omit it, the skill asks once.

| Mode | Invoke | Default item |
|------|--------|----------------|
| feature | `feature`, `1` | User story or bug |
| tech | `tech`, `technical`, `2` | Technical story |
| split | `split`, `3` | Any type, then checklist handoff |

```text
refine-story - feature
refine-story - tech
refine-story - split
split-story-checklist - features/NNN-slug/US01/STORY.md
```

Persistence, in order: `features/NNN-slug/USnn/STORY.md` or `TSnn/STORY.md`, optional `REFINE/` (including `REFINE/qa-history.md`), or the shortcut `docs/backlog/<slug>.md` after a documentation-language question. The skill does not create tracker cards.

While an open question remains at the feature, story-file, PRD, or PLAN gate, including **MINOR**, do not hand off to `sdd-spec`. Outside those gates, **MINOR** may remain. Ready for a spec is not `step_confirmed`.

`split-story-checklist` needs structured **Steps** already, unless `sdd-plan` calls it with `source=prd`. Then it builds groups from the PRD. It writes SMART tasks under the existing story (`REFINE/tasks.md` by default). It does not create new `USnn` or `TSnn` folders. At most five implementation groups. A direct invoke asks documentation language once, in the chat language, before write. An orchestrated call does not ask. A `trivial` feature does not get a tasks file only to satisfy a gate, except when the caller is `sdd-plan`, which still gets one step. `medium` and `complex` need the checklist before handoff.

### Small stack change

```text
developer
```

`developer` checks a UI brief, then the stack table. The first hit wins.

| Signal | Skill |
|--------|--------|
| New Blip plugin, no existing `blip-ds` project | `blip-plugin-developer` |
| `package.json` has `blip-ds` and `iframe-message-proxy` | `react-developer` |
| Blazor markers | `blazor-developer` |
| `electron`, `electron-builder`, or `electron-vite` | `electron-developer` |
| `vue` (and not React or Angular) | `vue-developer` |
| `react-native` or `expo` | `react-native-developer` |
| `react` | `react-developer` |
| `@angular/core` or `angular` | `angular-developer` |
| `package.json` with none of the above | `javascript-developer` |
| `.csproj` / `.sln` without Blazor markers | `dotnet-developer` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle` | `java-developer` |
| `.py`, `requirements.txt`, `pyproject.toml` | `python-developer` |

Isolated HTML or shell scripts stay in `/developer`. A large scope hands off to `/sdd-spec`. O3 does not call `*-developer` for a PLAN step.

Each stack skill is small-to-medium work. Confirm with **sim** before writes. One outcome, then stop.

| Skill | Scope | Hands off when scope grows |
|-------|--------|----------------------------|
| `dotnet-developer` | .NET | `/sdd-spec` |
| `java-developer` | JVM. Spring Boot is the default the skill names | `/sdd-spec` |
| `javascript-developer` | Node or DOM. There is no `node-developer` id | `/sdd-spec` |
| `python-developer` | FastAPI or Flask, pytest | `/sdd-spec` |
| `react-developer` | React web | `/react-native-developer` for mobile |
| `react-native-developer` | React Native or Expo | `/react-developer` for web |
| `angular-developer` | Angular | UI brief to `impeccable` when missing |
| `vue-developer` | Vue 3, Composition API, Pinia, Vitest | UI brief to `impeccable` when missing |
| `blazor-developer` | WASM, Server, Hybrid | `/dotnet-developer` for the API |
| `electron-developer` | Main, preload, renderer, IPC, packaging | Security and CSP load first when IPC changes |
| `blip-plugin-developer` | Scaffolds a new Blip React plugin | UI to `react-developer`. It does not implement the feature set |
| `impeccable` | Design commands | Writes `docs/DESIGN-BRIEF.md` after confirm and stops |

`impeccable` triggers: `/impeccable`, `/impeccable <command>`, `/impeccable-shape`, `/impeccable-audit`. `teach` is a deprecated alias of `init`. If `PRODUCT.md` is missing, run `init` first. Register is `brand` or `product`. Commands that ship in-repo include `init`, `shape`, `craft`, `critique`, `audit`, `harden`, `polish`, `onboard`. After **sim** on `shape` or `craft`, the next chat is the stack skill named by `target_stack`.

Guidelines live in `core/skills/_shared/code-guidelines/`. Load one file.

| Layer | Question | File |
|-------|----------|------|
| A | Which style | `principles/architecture-selection.md` |
| B | What the style requires | One of `architecture/vertical-slice.md`, `concentric-dependency.md`, `ddd-tactical.md`, `event-driven.md` |
| C | How this stack does it | The matching `*-guidelines` pack |

Greenfield proposes a style and writes the final ARCH only after **sim**. Brownfield mirrors. Vertical slice is the proposal for CRUD-heavy greenfield. Clean Architecture, onion, and hexagonal are the same concentric rule.

### After implementation

```text
code-review
run-tests
test-coverage
commit
push
open-github-pr
```

`code-review` asks single versus multi-angle. There is no default. Angles: quality, acceptance, security (at most three children when `subagents=native`). Decisions: **Approved**, **Approved with reservations**, **Changes required**. The skill does not edit code. After the report it asks **sim** / **pular** for a fix, a re-review, a bank refresh, and project docs. When an O3 scope closes, `run-tests` runs next, then the security pass, then `/commit` and `/push`.

`run-tests` runs the test command of each detected stack and returns `PASS` or `FAIL`. It does not edit code. A check the repo does not have is `SKIPPED`.

`test-coverage` is .NET Coverlet. Default threshold **80**. It writes `TestResults/CoverageReport/`. It does not block merge by itself. `code-review` applies the threshold. A fail hands to `/dotnet-developer` or `/sdd-develop`. A broken build hands to `/repair-dotnet-build`. `run-tests` calls it only when the PLAN asks for coverage.

`repair-dotnet-build` uses a local `dotnet build` / `dotnet test`, or a pasted log. It does not call a remote CI API. One error at a time, .NET only. Each proposed edit waits for confirmation.

`refactor` is one safe step with tests still green. It does not mix in features or bugfixes. No auto-commit.

`performance-profile` audits first, waits for a workflow choice, then proves the change with a micro-benchmark.

`framework-upgrade` modes: `audit`, `plan`, `migrate`, `validate`. Packs on disk: `angular`, `dotnet`. If the mode is omitted, the skill asks once. `migrate` needs **sim**. The skill id never includes a version number (`dotnet10-upgrade` and `framework-upgrade-vN` are forbidden). `targetVersion` must be greater than `currentVersion`.

### Platform skills

These sit beside delivery. When the change is a PLAN step, finish the skill and return to `/sdd-develop` on the next step in a new chat.

```text
api-standards
api-standards - versioning
api-integrate - <openapi>
i18n-manager
containerize
ef-add-migration
scaffold-message-handler
```

`api-standards` covers REST shape, versioning, errors, naming, and security hygiene. Optional focus: `rest`, `versioning`, `errors`, `naming`, `security`. Typed clients are `api-integrate` (OpenAPI or Swagger). No secrets in source.

`i18n-manager` extracts UI literals into `.resx` or `.json` and replaces them with keys. It waits for a workflow choice before writing. It does not localize logs or configuration.

`containerize` writes a multi-stage Dockerfile, `.dockerignore`, and compose for local dependencies. It waits for a workflow choice. Files that will be committed do not contain secrets.

`ef-add-migration` discovers the startup project, DbContext, and migrations folder, then runs `dotnet ef migrations add`. An inferred name is confirmed first. Use it on the consumer repo.

`scaffold-message-handler` collects queue, contract, retry, and idempotency before writing a consumer. It detects MassTransit, RabbitMQ, or Azure Service Bus from the consumer repo. It does not ship a corporate template.

### Git and repository docs

`commit`, `push`, and `open-github-pr` stay in full prose. Allowed heads: `feature/<slug>` or `feat/<id>` (one segment). Blocked: `main`, `master`, `develop`, nested `feature/a/b`. None of them force-push `main`, `master`, or `develop`.

```text
commit
push
open-github-pr
document-plan
document-implement
help-skills
```

`commit` drafts a Conventional Commit (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) and waits for the exact text. Subject and body are English. If `memory-bank/` exists, it asks refresh-light: **sim** / **pular**. If project docs exist, it asks whether to update them. **sim** on the bank runs `memory-bank-init` refresh-light. After the commit, a `Co-authored-by` trailer is stripped until it is gone.

`push` runs `git push -u origin HEAD` after the branch check. If this conversation already asked for a pull request, it loads `open-github-pr`. Otherwise it asks.

`open-github-pr` owns `gh pr create`. Feature (current `feature/*` or `feat/*`) targets `develop` with `--squash` when auto-merge is enabled. Release (`develop` to `master` or `main`) uses `--rebase`. Content **sim** / **ajustar** / **cancelar** is separate from the auto-merge question (**sim** / **não**). If the branch is not on `origin`, hand off to `/push` first.

`document-plan` asks documentation language once, then writes `docs/overview.md` and `docs/documentation-plan/plan.md`. It does not write feature PLANs. For this toolkit the language is English. `document-implement` executes one pending step, then stops.

`help-skills` prints the static catalog. It does not invent ids. There is no `open-pr` id. The id is `open-github-pr`.

One example of each id is on [First use](first-use.md).

## Session behavior

These rules apply in every chat after sync. They are preferences and policy. Source: `core/skills/_shared/agents/LANGUAGE.md`, `core/policy/orchestrator-session.md`, `core/policy/caveman-mode.md`, `scripts/_lib/Initialize-SddPreferences.ps1`.

### Language

| Surface | Language |
|---------|----------|
| What you read (chat, host plans) | The language of this chat |
| Feature artifacts (FEATURE, STORY, PRD, PLAN, ARCH, SEC, CONTINUITY, CHANGE prose) | Same resolution as below |
| Child prompts, specialist context, receipts | English (`en-US`) |
| Identifiers, paths, skill ids, commits, tests | English |

Artifact language, once per write: invocation override, else `preferences.json` `artifact_language` when it is not null, else manifest `artifact_language` when it is not null, else the chat language. `null` means no override.

`core/policy/user-language-pt-br.md` and `core/policy/sdd-artifact-language-pt-br.md` ship as install defaults for a Brazilian Portuguese session. When the chat or preferences name another language, `LANGUAGE.md` wins. Child handoffs carry a path and a short excerpt.

### Parent orchestrator

Default `orchestrator_mode` is `always`. The parent keeps goals, gates, paths, and receipts. Specialists write notes or code. Commands: `orchestrator always`, `orchestrator adaptive`, `orchestrator status` (aliases `orchestrate` and `parent`).

`adaptive` may keep a single-path question or a one-file edit in the parent. Any wider change is spawned. If the host has `subagents=none`, the same work stays in the parent. The session does not fail because Task is missing.

Task `model` is omitted so the child uses the parent session model (`core/skills/_shared/agents/SUBAGENT-MODEL.md`).

### Optional chat compression

`caveman_mode` defaults to **off**. It only shortens chat prose. It does not change skill steps, gates, or documentation.

Commands: `caveman on`, `caveman off`, `caveman status`, `caveman lite`, `caveman full`, `caveman ultra`. `stop caveman` and `normal mode` turn it off.

`help-skills`, `read-sdd-artifact`, `commit`, `push`, and `open-github-pr` never compress. Gates, drafts, paths, and `(sim / ajustar / cancelar)` stay clear. Policy file: `core/policy/caveman-mode.md`. The idea is credited on [Credits](credits.md).

### Other preference keys

| Key | Default | Effect |
|-----|---------|--------|
| `orchestrator_mode` | `always` | Parent stays orchestrator |
| `caveman_mode` | `false` | Chat compression off |
| `caveman_level` | `full` | Intensity if compression is turned on |
| `artifact_language` | `null` | No locale override |
| `verify_mode` | `false` | O3 does not spawn a read-only verifier after each implementer |

`verify_mode: true` is a second child after a successful `sdd-develop` step. It is separate from the evidence script (`validate-evidence`).

## Re-sync

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Managed files are overwritten. Alien files in the agent home stay.
