---
title: Using skills
---

# Using skills

Invoke skills by **id** (kebab-case under `core/skills/`). The id is the same on every host. The prefix is host-specific (`/`, `$`, `use skill`, or the OpenCode `skill` tool). Compat on many hosts: `use skill <id>`, or natural language that matches the skill description.

After any sync, invoke **`adt-help-skills`**. It reads the installed catalog (`CATALOG.md` and `OPERATOR.md`). There are **52** invocable skills. Folders under `core/skills/_shared/` are packs, not skills. The architect, database, security, repo-analyst, and shell-runner files under `core/agents/` are roster roles, not skill ids.

Host routing is adapter-specific: Copilot has `router=false`, so the `core/router/AGENTS.md` guidance is embedded in its generated `copilot-instructions.md`; this is not a separate skill id or live-host proof.

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

Choose the flow first: [Choosing the flow](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/guides/flow-selection.md).

```text
Feature
  └─ adt-orchestrate-analyze
        ├─ understands the outcome, asks material questions, investigates proportionally
        ├─ trivial one-file → /adt-developer (only if you pick that shortcut)
        ├─ one already-clear story → adt-sdd-spec
        └─ selected stories → adt-orchestrate-prepare → one complete PLAN approval before implementation
              └─ PRD + PLAN per selected story → one approval of the complete PLAN set
                    └─ one adt-sdd-develop step per child → adt-run-tests, adt-code-review, adt-run-tests (after review changes), security
```

### Orchestrated Delivery

```text
adt-orchestrate-analyze
adt-orchestrate-prepare - features/NNN-slug/
adt-orchestrate-implement - features/NNN-slug/
```

Analyze investigates proportionally and uses specialists for concrete questions. Deliver prepares PRDs and PLANs for selected stories and presents the complete, explicitly listed PLAN set for one approval before implementation. Develop dispatches serially, one PLAN step per child, reconciling each result before the next. Memory Bank and sidecars are optional context. Details: [Orchestrated Delivery](orchestrated-delivery.md).

Gate legend (id = Portuguese label shown in the pt-BR install): `confirm` = sim, `adjust` = ajustar, `cancel` = cancelar, `skip` = pular, `decline` = não. Labels are localized; ids stay English. Details: [Questions and confirmations](questions.md).

Use the **architect** roster role when a concrete architecture question needs specialist input. Resolve a decision with the operator only when it materially affects behavior, acceptance, scope, or implementation. Greenfield, missing style, or brownfield classification alone does not require an ARCH approval or mirror. The parent stays coordinator.

For Classic SDD and O1/O2/O3, only an unanswered material question blocks affected work. Minor questions remain visible, and independent stories may continue. The PLAN is the only persisted implementation progress source. Backlog Refine and other skills keep their own contracts.

### Direct Classic SDD

Use this when one feature has a clear path. Classic SDD is standalone and does not require O1, a specialist folder, or a Memory Bank. O2 internal calls suppress their own progress table.

| Order | Skill | Output |
|-------|--------|--------|
| 1 | `adt-sdd-spec` | `features/NNN-slug/USnn/PRD/NNN_slug.md` |
| 2 | `adt-sdd-plan` | `features/NNN-slug/USnn/PLAN/PLAN_NNN_slug.md` |
| 3 | `adt-sdd-develop` | One PLAN step: code, tests, PLAN progress |
| — | `adt-read-sdd-artifact` | Read-only `source_context` |

Default story folder when unspecified is `US01` (`TSnn` for a technical story). Root-level `PRD/` or `PLAN/` folders are invalid.

```text
adt-sdd-spec
adt-sdd-plan - features/NNN-slug/US01/PRD/NNN_slug.md
adt-sdd-develop - features/NNN-slug/US01/PLAN/PLAN_NNN_slug.md - Step 1
adt-read-sdd-artifact - features/NNN-slug/US01/PRD/NNN_slug.md
```

`adt-sdd-spec` defines expected behavior, scope, acceptance, relevant contracts, and material questions in a PRD. Drafting and saving are preparation; there is no separate PRD write approval. Identifiers and exact document grammar help traceability but are not authorization gates. Brownfield context belongs in the PRD or PLAN when relevant. The skill does not write a PLAN in the same session.

`adt-sdd-plan` derives executable steps directly from the PRD or a sufficiently specified demand. `adt-split-story-checklist` is optional. The PLAN owns dependencies, acceptance, validation evidence, blockers, next action, and the single progress table. Present the complete PLAN for one explicit approval before implementation. Direct planning ends with a handoff; it does not start implementation automatically.

`adt-sdd-develop` uses the approved PLAN's `step_by_step` or `continuous` cadence. Before each step, check PLAN approval, dependencies, scope, acceptance, and relevant evidence. The PLAN is the only progress source; SESSION flags and claims are not prerequisites. Record one canonical state/evidence update per step. Group validation when it provides clearer evidence than running tests after each step.

`adt-read-sdd-artifact` has no **sim** gate. Kinds allowed: FEATURE, STORY, PRD, PLAN. Reject reasons: `path_traversal`, `outside_features`, `absolute_path_forbidden`, `unsupported_kind`, `not_found`, `empty_path`, `invalid_portable_path`.

Classic SDD and O2 use substantive checks of behavior, acceptance, scope, dependencies, and required validation. Generic PRD/PLAN/CHANGE validators may be used as optional diagnostics; document titles, section counts, and optional sidecars do not authorize advancement.

### One product item

O1 creates justified stories without requiring a separate scorecard or refine call. Invoke `adt-refine-story` when shaping a single backlog item independently of a feature flow.

Mode is mandatory. If you omit it, the skill asks once.

| Mode | Invoke | Default item |
|------|--------|----------------|
| feature | `feature`, `1` | User story or bug |
| tech | `tech`, `technical`, `2` | Technical story |
| split | `split`, `3` | Any type, then checklist handoff |

```text
adt-refine-story - feature
adt-refine-story - tech
adt-refine-story - split
adt-split-story-checklist - features/NNN-slug/US01/STORY.md
```

### Challenge a requirement

Run `adt-requirement-review` before SDD when a feature or story still has open questions, or when a technical story must be checked against the repository. Mode is mandatory: `--feature` checks functional gaps and acceptance criteria; `--tech` checks contracts and flows against the repository. The skill asks once if you omit the mode.

```text
adt-requirement-review --feature - features/NNN-slug/US01/STORY.md
adt-requirement-review --tech - features/NNN-slug/US01/STORY.md
```

After an explicit **sim**, the review writes a report and appends to the question history under `REFINE/` beside the story. The status is `READY` or `NEEDS_CLARIFICATION`. `adt-refine-story` calls this review at step 4a, before it hands off to `adt-sdd-spec`.

Persistence, in order: `features/NNN-slug/USnn/STORY.md` or `TSnn/STORY.md`, optional `REFINE/` (including `REFINE/qa-history.md`), or the shortcut `docs/backlog/<slug>.md` after a documentation-language question. The skill does not create tracker cards.

For Classic SDD and O1/O2/O3, resolve an open question before dependent work only when it materially affects behavior, acceptance, scope, access, or implementation. Minor questions remain visible and do not stop unrelated work.

`adt-split-story-checklist` optionally creates SMART tasks under the existing story (`REFINE/tasks.md` by default). It does not create new `USnn` or `TSnn` folders. `adt-sdd-plan` may derive steps directly from a PRD; a missing checklist never blocks planning at any complexity level.

### Small stack change

```text
adt-developer
```

`adt-developer` checks a UI brief, then the stack table. The first hit wins.

| Signal | Skill |
|--------|--------|
| New Blip plugin, no existing `blip-ds` project | `adt-blip-plugin-developer` |
| `package.json` has `blip-ds` and `iframe-message-proxy` | `adt-react-developer` |
| Blazor markers | `adt-blazor-developer` |
| `electron`, `electron-builder`, or `electron-vite` | `adt-electron-developer` |
| `vue` (and not React or Angular) | `adt-vue-developer` |
| `react-native` or `expo` | `adt-react-native-developer` |
| `react` | `adt-react-developer` |
| `@angular/core` or `angular` | `adt-angular-developer` |
| `package.json` with none of the above | `adt-javascript-developer` |
| `.csproj` / `.sln` without Blazor markers | `adt-dotnet-developer` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle` | `adt-java-developer` |
| Explicit Arduino Core/framework evidence, Arduino metadata, or configured `framework = arduino` | `adt-arduino-developer` |
| Native ESP-IDF evidence (`idf_component.yml`, Component Manager lockfile, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`/`sdkconfig.defaults`, or `idf.py` scripts) | `adt-esp-idf-developer` |
| Declared MicroPython runtime or firmware workflow with runtime, target, or port evidence | `adt-micropython-developer` |
| CPython host applications, tools, or tests (including host code that communicates with firmware) | `adt-python-developer` |
| `.py`, `main.py`, or a board-family name without framework/runtime/toolchain evidence | `/adt-developer` (ask for framework/core/runtime/version/toolchain evidence; do not infer) |
| Python without runtime/target/port evidence when APIs or deployment could differ | `/adt-developer` (ask for runtime, target, and port evidence; ambiguity is intentional) |
| `requirements.txt` or `pyproject.toml` with host-runtime evidence | `adt-python-developer` |

Isolated HTML or shell scripts stay in `/adt-developer`. A large scope hands off to `/adt-sdd-spec`. O3 does not call `adt-*-developer` for a PLAN step.

Each stack skill is small-to-medium work. Confirm with **sim** before writes. One outcome, then stop.

| Skill | Scope | Hands off when scope grows |
|-------|--------|----------------------------|
| `adt-dotnet-developer` | .NET | `/adt-sdd-spec` |
| `adt-java-developer` | JVM. Spring Boot is the default the skill names | `/adt-sdd-spec` |
| `adt-javascript-developer` | Node or DOM. There is no `node-developer` id | `/adt-sdd-spec` |
| `adt-python-developer` | FastAPI or Flask, pytest | `/adt-sdd-spec` |
| `adt-react-developer` | React web | `/adt-react-native-developer` for mobile |
| `adt-react-native-developer` | React Native or Expo | `/adt-react-developer` for web |
| `adt-angular-developer` | Angular | Create a brief when substantial visual decisions are needed |
| `adt-vue-developer` | Vue 3, Composition API, Pinia, Vitest | Create a brief when substantial visual decisions are needed |
| `adt-blazor-developer` | WASM, Server, Hybrid | `/adt-dotnet-developer` for the API |
| `adt-electron-developer` | Main, preload, renderer, IPC, packaging | Security and CSP load first when IPC changes |
| `adt-blip-plugin-developer` | Scaffolds a new Blip React plugin | UI to `adt-react-developer`. It does not implement the feature set |
For net-new UI or a substantial visual redesign, record audience, hierarchy, visual direction, responsive behavior, component states, and accessibility in `docs/DESIGN-BRIEF.md` before implementation. General guidance is in `core/skills/_shared/frontend-guidelines/frontend-practices.md`.

Guidelines live in `core/skills/_shared/code-guidelines/`. Load one file.

| Layer | Question | File |
|-------|----------|------|
| A | Which style | `principles/architecture-selection.md` |
| B | What the style requires | One of `architecture/vertical-slice.md`, `concentric-dependency.md`, `ddd-tactical.md`, `event-driven.md` |
| C | How this stack does it | The matching `*-guidelines` pack |

When a concrete architecture choice materially affects behavior or implementation, present the choice and resolve it before dependent work. Greenfield or brownfield classification alone does not require architecture approval or a mirrored ARCH. Existing code is evidence of current conventions, not a requirement to create a separate architecture note. Vertical slice remains one option for CRUD-heavy greenfield. Clean Architecture, onion, and hexagonal are the same concentric rule.

### After implementation

```text
adt-run-tests
adt-code-review
adt-run-tests (after review changes, or record no rerun required)
security
adt-test-coverage
adt-commit
adt-push
adt-open-github-pr
```

`adt-code-review` asks single versus multi-angle. There is no default. Angles: quality, acceptance, security (at most three children when `subagents=native`). Finding bands are `critical`, `important`, and `nice-to-have`. Decisions: **Approved**, **Approved with reservations**, **Changes required**. The skill does not edit code. After the report it asks **sim** / **pular** only for a fix and a re-review. It does not ask about a memory bank, project docs, or a pull request. `adt-code-explain` is separate: it compares changes when both endpoints resolve, asks for a missing endpoint, or explains existing code from a resolvable topic, symbol, file, or folder without a diff. It cites opened code and separates observations from inferences; it does not issue a review verdict. When an O3 scope closes, the order is `adt-run-tests`, `adt-code-review`, `adt-run-tests` after review changes (or record no rerun required), the `security` pass, then `/adt-commit` and `/adt-push`.

`adt-run-tests` runs the test command of each detected stack and returns `PASS` or `FAIL`. It does not edit code. A check the repo does not have is `SKIPPED`.

`adt-test-coverage` is .NET Coverlet. Default threshold **80**. It writes `TestResults/CoverageReport/`. It does not block merge by itself. `adt-code-review` applies the threshold. A fail hands to `/adt-dotnet-developer` or `/adt-sdd-develop`. A broken build hands to `/adt-repair-dotnet-build`. `adt-run-tests` calls it only when the PLAN asks for coverage.

`adt-repair-dotnet-build` uses a local `dotnet build` / `dotnet test`, or a pasted log. It does not call a remote CI API. One error at a time, .NET only. Each proposed edit waits for confirmation.

`adt-refactor` is one safe step with tests still green. It does not mix in features or bugfixes. No auto-commit.

`adt-performance-profile` audits first, waits for a workflow choice, then proves the change with a micro-benchmark.

`adt-framework-upgrade` modes: `audit`, `plan`, `migrate`, `validate`. Packs on disk: `angular`, `dotnet`. If the mode is omitted, the skill asks once. `migrate` needs **sim**. The skill id never includes a version number (`dotnet10-upgrade` and `framework-upgrade-vN` are forbidden). `targetVersion` must be greater than `currentVersion`.

### Platform skills

These sit beside delivery. When the change is a PLAN step, finish the skill and return to `/adt-sdd-develop` for the relevant step. Each step needs its own invocation, but not a new operator chat.

```text
adt-api-standards
adt-api-standards - versioning
adt-api-integrate - <openapi>
adt-i18n-manager
adt-containerize
adt-ef-add-migration
adt-scaffold-message-handler
```

`adt-api-standards` covers REST shape, versioning, errors, naming, and security hygiene. Optional focus: `rest`, `versioning`, `errors`, `naming`, `security`. Typed clients are `adt-api-integrate` (OpenAPI or Swagger). No secrets in source.

`adt-i18n-manager` extracts UI literals into `.resx` or `.json` and replaces them with keys. It waits for a workflow choice before writing. It does not localize logs or configuration.

`adt-containerize` writes a multi-stage Dockerfile, `.dockerignore`, and compose for local dependencies. It waits for a workflow choice. Files that will be committed do not contain secrets.

`adt-ef-add-migration` discovers the startup project, DbContext, and migrations folder, then runs `dotnet ef migrations add`. An inferred name is confirmed first. Use it on the consumer repo.

`adt-scaffold-message-handler` collects queue, contract, retry, and idempotency before writing a consumer. It detects MassTransit, RabbitMQ, or Azure Service Bus from the consumer repo. It does not ship a corporate template.

### Git and repository docs

`adt-commit`, `adt-push`, and `adt-open-github-pr` stay in full prose. Allowed heads: `feature/<slug>` or `feat/<id>` (one segment). Blocked: `main`, `master`, `develop`, nested `feature/a/b`. None of them force-push `main`, `master`, or `develop`.

```text
adt-commit
adt-push
adt-open-github-pr
adt-document-plan
adt-document-implement
adt-help-skills
```

`adt-commit` drafts a Conventional Commit (`feat`, `fix`, `docs`, `style`, `adt-refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) and waits for the exact text. Subject and body are English. It does not ask about memory bank or project docs. After the commit, a `Co-authored-by` trailer is stripped until it is gone. Push or a pull request runs only when that same request already includes it.

`adt-push` runs `git push -u origin HEAD` after the branch check. If this conversation already asked for a pull request, it loads `adt-open-github-pr`. Otherwise it asks.

`adt-open-github-pr` owns `gh pr create`. Feature (current `feature/*` or `feat/*`) targets `develop` with `--squash` when auto-merge is enabled. Release (`develop` to `master` or `main`) uses `--rebase`. The content gate (ids `confirm`, `adjust`, `cancel`) is separate from the auto-merge question (ids `confirm`, `decline`). Labels are localized. If the branch is not on `origin`, hand off to `/adt-push` first.

`adt-document-plan` asks documentation language once, then writes `docs/overview.md` and `docs/documentation-plan/plan.md`. It does not write feature PLANs. For this toolkit the language is English. `adt-document-implement` executes one pending step, then stops.

`adt-help-skills` prints the static catalog. It does not invent ids. There is no `open-pr` id. The id is `adt-open-github-pr`.

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

Gate answers are read by meaning, in any language; silence, an ambiguous reply, or a lone emoji is not approval.

### Parent orchestrator

adaptive: trivial work (3/6/150 limits) may stay in the parent. always: delegates everything except qa_checklist. Full table: `core/policy/orchestrator-session.md` "Modes".
### Optional chat compression

First interactive sync asks whether Caveman response compression is on or off; **on** is the default. Non-interactive first sync defaults to `caveman_mode: true`. It only shortens chat prose. It does not change skill steps, gates, or documentation.

Commands: `caveman on`, `caveman off`, `caveman status`, `caveman lite`, `caveman full`, `caveman ultra`. `stop caveman` and `normal mode` turn it off.

`adt-help-skills`, `adt-read-sdd-artifact`, `adt-commit`, `adt-push`, and `adt-open-github-pr` never compress. Gates, drafts, paths, and gate options (ids `confirm`, `adjust`, `cancel`; the pt-BR install shows sim / ajustar / cancelar) stay clear. Policy file: `core/policy/caveman-mode.md`. The idea is credited on [Credits](credits.md).

### Subagent model and effort

Use `adt-settings` to inspect or save one general model and effort pair for subagents, or to return to inheriting. The default is to inherit both values from the parent. A saved pair only preselects the one-time session question; it does not change a session after that question has been answered.

Available pairs come from the effective adapter row in `SUBAGENT-OPTIONS.md`. When an adapter has no proven mechanism for applying the pair, the host inherits the parent values.

| Adapter | Status |
|---------|--------|
| Claude | documented, not verified at runtime |
| Codex | documented, not verified at runtime |
| Cursor | documented, not verified at runtime |
| Hermes | documented, not verified at runtime |
| Copilot | documented, not verified at runtime |

Update an adapter's status only after real evidence is recorded for it.

### Other preference keys

| Key | Default | Effect |
|-----|---------|--------|
| `orchestrator_mode` | `adaptive` | Parent orchestrates; trivial work may stay in the parent |
| `subagent_models.default` | absent (inherit) | Optional `{model, effort}` pair used as a preselection |
| `caveman_mode` | `true` on first sync | Chat compression on; interactive sync may set it off |
| `caveman_level` | `full` | Intensity if compression is turned on |
| `artifact_language` | `null` | No locale override |
| `verify_mode` | `false` | O3 does not spawn a read-only verifier after each implementer |

`verify_mode: true` is a second child after a successful `adt-sdd-develop` step. It is separate from the evidence script (`validate-evidence`).

## Re-sync

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent claude -InstallRoot "$env:USERPROFILE\.claude" -AllowUserHome
```

Managed files are overwritten. Alien files in the agent home stay.
