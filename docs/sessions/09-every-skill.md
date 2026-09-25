# 09 — Every skill

Forty-one invocable skills. Shared packs under `core/skills/_shared/` are not skills. The architect, database, security, repo-analyst, and shell-runner files under `core/agents/` are roster roles spawned by O1 or the router, not slash skills.

The long form of a skill is the session linked on its heading. This page is the index that still says what the skill does, what it writes, and which skill it calls next.

## Delivery

### `memory-bank-init`

Creates or refreshes `memory-bank/` at the repository root or the global classic path. Never under `features/NNN-slug/`. Modes: `create`, `refresh`, `refresh-light`. Runs a read-only inventory, then fills templates. Confirms before write. Stops when the bank is done and does not start O1. Called at Orchestrated Delivery Step 0 and after O3 changes application files (`refresh-light`). Detail: [01](01-orchestrated-delivery.md).

### `orchestrate-analyze`

O1. Classifies intent, asks a few high-cost questions, sets nature and `needs_*`, spawns specialists only when flags require them, drafts architecture for greenfield and waits for **sim**, merges stories with scorecard and promotion gates, and waits for backlog **sim**. Writes `FEATURE.md`, `CONTINUITY.md`, and `STORY.md`. Does not write PRD, PLAN, or code. Detail: [01](01-orchestrated-delivery.md).

### `orchestrate-deliver`

O2. Requires an approved backlog. For each story, runs the `sdd-spec` contract then the `sdd-plan` contract. Series writes in the parent after **sim**. Parallel children return drafts; the parent is the only writer. Stops on missing specialist folders or open clarification B/I. Brownfield also writes `CHANGE.md`. Preflight must pass before O3. Detail: [01](01-orchestrated-delivery.md), contracts in [02](02-classic-sdd.md).

### `orchestrate-develop`

O3. Builds a queue of pending PLAN steps. Spawns one `sdd-develop` child per step. Parent writes no application code. Execution mode `serial` (default), `parallel`, or `manual`. Pacing `step_by_step` (default) or `continuous`. After code changes, offers memory-bank refresh-light. When the feature is done, offers `code-review` or `commit`. Detail: [01](01-orchestrated-delivery.md).

### `sdd-spec`

Writes one PRD under `features/NNN-slug/.../PRD/`. What and why, stable `REQ-NNN`, out of scope, confirm before write, `validate-prd`. Brownfield also writes `CHANGE.md`. Does not write a PLAN in this session. Direct use can promote a cited markdown file without O1. Orchestrated use returns to O1 when specialist folders are missing. Detail: [02](02-classic-sdd.md).

### `sdd-plan`

Writes one PLAN beside that PRD. Every REQ maps to a step. Bodies of SQL and OpenAPI stay in canonical files; the PLAN cites them. Confirm before write. `validate-plan` must pass. Does not implement. Detail: [02](02-classic-sdd.md).

### `sdd-develop`

Implements exactly one PLAN step, updates that PLAN, runs targeted tests. Optional evidence files and TRACE when the wave closes. Does not start the next step. This is the contract O3 children follow. Detail: [02](02-classic-sdd.md).

### `read-sdd-artifact`

Read-only. Turns one FEATURE, STORY, PRD, or PLAN path under `features/` into `source_context`. Rejects traversal, absolute paths, and other kinds. No confirm gate. Consumers that already have the envelope skip an opaque re-read. Detail: [02](02-classic-sdd.md).

### `refine-story`

Standalone shaping of one bug, user story, or technical story. Mode `feature`, `tech`, or `split` is mandatory. Writes chat markdown, a scorecard, and optionally `STORY.md` or `docs/backlog/<slug>.md`. O1 uses the scorecard rubric file without calling this skill. O2 calls this skill when clarification B or I is still open. Detail: [03](03-backlog-shape.md).

### `split-story-checklist`

Turns an existing story’s steps into a dependency checklist (`REFINE/tasks.md`). Does not create new story folders. At most five groups. Asks documentation language before write. Trivial features do not get a tasks file only to satisfy a gate. Detail: [03](03-backlog-shape.md).

## Implementation

### `developer`

Router. UI brief check, then the stack table, then ad-hoc fallback for scripts and HTML. Large scope goes to `sdd-spec`. Trivial O1 triage may land here. It does not implement PLAN steps. Detail: [04](04-implement-and-guidelines.md).

### `dotnet-developer`

Small or medium .NET without a full PLAN. Loads one `dotnet-guidelines` style file. Build and tests. Scope growth returns to `sdd-spec`. Also the fix path when `test-coverage` fails on C#. Detail: [04](04-implement-and-guidelines.md).

### `java-developer`

Small or medium Java. Spring Boot is the default, not the only shape the skill names. Loads `java-guidelines` including one architecture overlay. Detail: [04](04-implement-and-guidelines.md).

### `javascript-developer`

Small or medium Node or DOM work. There is no `node-developer` id. Loads `javascript-guidelines`. Nest is recognized only as an existing project signal, not as a separate skill. Detail: [04](04-implement-and-guidelines.md).

### `python-developer`

Small or medium Python (FastAPI or Flask, pytest). Loads `python-guidelines` and one shared Layer B style file. Detail: [04](04-implement-and-guidelines.md).

### `react-developer`

Small or medium React web (hooks, tests). Reads `DESIGN-BRIEF.md` when present. Existing Blip plugins (`blip-ds`) also load `blip-guidelines`. Mobile work is `react-native-developer`. Detail: [04](04-implement-and-guidelines.md).

### `react-native-developer`

Small or medium React Native or Expo. Uses the React Native guideline pack, not the web React pack, and does not load Blip guidelines. Detail: [04](04-implement-and-guidelines.md).

### `angular-developer`

Small or medium Angular (standalone components, signals, RxJS). Loads `angular-guidelines` and HTML/CSS files as needed. Detail: [04](04-implement-and-guidelines.md).

### `vue-developer`

Small or medium Vue 3 (Composition API, Pinia, Vitest). Detail: [04](04-implement-and-guidelines.md).

### `blazor-developer`

Small or medium Blazor UI (WASM, Server, Hybrid). Backend API work in the same change hands to `dotnet-developer`. Detail: [04](04-implement-and-guidelines.md).

### `electron-developer`

Small or medium Electron (main, preload, renderer, IPC, packaging). Security and CSP load first when IPC changes. One renderer pack (React, Vue, or JS) is loaded, not all of them. Detail: [04](04-implement-and-guidelines.md).

### `blip-plugin-developer`

Scaffolds a **new** Blip React plugin and records the profile. Does not implement the feature set. Hands UI to `react-developer`, a new screen’s brief to `impeccable`, a backend to `dotnet-developer`, and a full spec to `sdd-spec`. An existing `blip-ds` project starts at `react-developer` instead. Detail: [04](04-implement-and-guidelines.md).

### `impeccable`

Design commands (`init`, `shape`, `craft`, `critique`, `audit`, `harden`, and others). Writes `docs/DESIGN-BRIEF.md` after confirm and stops. The next chat is the stack skill named by `target_stack`. Does not implement in the same session. Detail: [04](04-implement-and-guidelines.md).

## Review and change

### `code-review`

Review of a branch against guidelines and, when found, PRD/PLAN. Asks single versus multi-angle. Decisions: Approved, Approved with reservations, Changes required. Does not edit code. Suggested after O3; not a blocking gate. Detail: [05](05-review-and-quality.md).

### `test-coverage`

.NET Coverlet report. Default 80% line coverage on changed production files. Writes `TestResults/CoverageReport/`. Does not block merge by itself; `code-review` applies the threshold. Detail: [05](05-review-and-quality.md).

### `repair-dotnet-build`

Local `dotnet build` / `dotnet test`, or a pasted log. Proposes each fix and waits. Does not call a remote CI API. Detail: [05](05-review-and-quality.md).

### `refactor`

One safe refactor step with tests still green. Does not mix in features or bugfixes. No auto-commit. Detail: [05](05-review-and-quality.md).

### `performance-profile`

Finds a hot path, waits for a workflow choice, then proves the change with a micro-benchmark. Does not bypass a domain rule for speed. Detail: [05](05-review-and-quality.md).

### `framework-upgrade`

Modes `audit`, `plan`, `migrate`, `validate`. Packs on disk: `angular`, `dotnet`. Migrate needs **sim**. The skill id never includes a version number. Detail: [06](06-framework-upgrade.md).

## Platform

### `api-standards`

Agnostic HTTP design (shape, versioning, errors, naming, security hygiene). Does not generate clients and does not embed a company contract. Hands generation to `api-integrate`. Detail: [07](07-platform-skills.md).

### `api-integrate`

Typed client and DTOs from OpenAPI or Swagger. Waits for a workflow choice. No secrets in source. Standards questions return to `api-standards`. Detail: [07](07-platform-skills.md).

### `i18n-manager`

Extracts UI string literals into `.resx` or `.json` and replaces them with translation keys. Waits for a workflow choice before writing. Does not localize logs or configuration. Detail: [07](07-platform-skills.md).

### `containerize`

Multi-stage Dockerfile, `.dockerignore`, and compose for local dependencies. Waits for a workflow choice. No secrets in files that will be committed. Detail: [07](07-platform-skills.md).

### `ef-add-migration`

Discovers startup project, DbContext, and migrations folder, then `dotnet ef migrations add`. Confirms an inferred name. Consumer repo, not this toolkit, unless the toolkit is the subject. Detail: [07](07-platform-skills.md).

### `scaffold-message-handler`

Collects queue, contract, retry, and idempotency requirements before writing a consumer. Detects MassTransit, RabbitMQ, or Service Bus from the consumer repo. Does not ship a corporate template. Detail: [07](07-platform-skills.md).

## Git, catalog, docs

### `help-skills`

Prints the static catalog (`CATALOG.md`, and `OPERATOR.md` when the question is about confirmations). Does not invent ids and does not load every skill body. Detail: [08](08-git-and-docs.md).

### `commit`

Conventional Commit on a valid feature branch after the message is approved. Asks about memory-bank and project docs when those trees exist. Strips any `Co-authored-by` trailer. Does not open a pull request. Detail: [08](08-git-and-docs.md).

### `push`

`git push -u origin HEAD` after the branch check. If a pull request was already requested, enters `open-github-pr`. Otherwise asks. Detail: [08](08-git-and-docs.md).

### `open-github-pr`

Creates the pull request with `gh`. Feature into `develop` uses squash when auto-merge is enabled. Release from `develop` into `master` or `main` uses rebase. Asks for content **sim** and, separately, whether to enable auto-merge. Detail: [08](08-git-and-docs.md).

### `document-plan`

Asks documentation language once, then writes `docs/overview.md` and `docs/documentation-plan/plan.md`. Does not write feature PLANs. For this repository the language is English. Detail: [08](08-git-and-docs.md).

### `document-implement`

Executes one pending step of that documentation plan, then stops. Detail: [08](08-git-and-docs.md).

## Count

`CATALOG.md` groups the same 41 ids: Classic SDD 4, Backlog Refine 2, Orchestrated Delivery 4, developer routing and stack 11, Blip and design 2, operational 16, documentation 2.
