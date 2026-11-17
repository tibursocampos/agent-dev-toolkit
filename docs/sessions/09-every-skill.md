# 09 — Every skill

Fifty-two invocable skills. Shared packs under `core/skills/_shared/` are not skills. The architect, database, security, repo-analyst, and shell-runner files under `core/agents/` are roster roles spawned by O1 or the router, not slash skills.

The long form of a skill is the session linked on its heading. This page is the index that still says what the skill does, what it writes, and which skill it calls next.

## Delivery

### `adt-epic-planner`

Facilitates active discovery and decomposes an initiative into outcome-based features in one navigable `EPIC.md`. It is optional and does not create stories, PRDs, or PLANs. O1 can use one explicitly selected feature ID as context without requiring EPIC promotion or a separate handoff. Detail: [01](01-orchestrated-delivery.md).

### `memory-bank-init`

Creates or refreshes `memory-bank/` at the repository root or the global classic path. Never under `features/NNN-slug/`. Modes: `create`, `refresh`, `refresh-light`. Runs a read-only inventory, then fills templates. Confirms before write. Stops when the bank is done and does not start O1. Called at Orchestrated Delivery Step 0 and after O3 changes application files (`refresh-light`). Detail: [01](01-orchestrated-delivery.md).

### `orchestrate-analyze`

O1. Understands the demand, investigates only concrete questions, and creates justified stories. Memory Bank, specialist folders, and sidecars are optional context. No backlog approval gate. Writes canonical feature/story artifacts as useful; does not write PRD, PLAN, or code. Detail: [01](01-orchestrated-delivery.md).

### `orchestrate-deliver`

O2. Prepares PRD and PLAN for each selected story. Drafting and saving are preparation; one explicit approval covers the complete explicitly listed PLAN set before implementation. Only material questions block the affected work; independent stories may proceed. Internal spec/plan calls do not draw a competing progress table. Detail: [01](01-orchestrated-delivery.md), contracts in [02](02-classic-sdd.md).

### `orchestrate-develop`

O3. Dispatches one child per eligible PLAN step, serially. It reconciles each result into the PLAN before the next dispatch and resumes from persisted progress and partial work. Uses the selected `step_by_step` or `continuous` cadence. No SESSION flags, claims, or CONTINUITY progress mirror are required. Detail: [01](01-orchestrated-delivery.md).

### `sdd-spec`

Defines behavior, scope, acceptance, relevant contracts, and material questions in a PRD. Draft/write is preparation with no separate approval gate. IDs and optional structure are useful but not authorization grammar. Does not write a PLAN in this session. Detail: [02](02-classic-sdd.md).

### `sdd-plan`

Creates one executable PLAN from the PRD or a sufficiently specified demand. Checklist decomposition is optional; PLAN owns dependencies, acceptance, validation, blockers, and the single progress table. Presents the complete PLAN for one approval before implementation; direct planning ends at handoff. Detail: [02](02-classic-sdd.md).

### `sdd-develop`

Implements the approved PLAN using `step_by_step` or `continuous` cadence. PLAN is the only persisted progress source; SESSION flags and claims are not prerequisites. O3 children implement one step at a time. Detail: [02](02-classic-sdd.md).

### `read-sdd-artifact`

Read-only. Turns one FEATURE, STORY, PRD, or PLAN path under `features/` into `source_context`. Rejects traversal, absolute paths, and other kinds. No confirm gate. Consumers that already have the envelope skip an opaque re-read. Detail: [02](02-classic-sdd.md).

### `refine-story`

Standalone shaping of one bug, user story, or technical story. On a direct invoke, mode `feature`, `tech`, or `split` is asked in the chat language. An orchestrated call receives `mode=feature` or `mode=tech` and does not ask. Writes chat markdown, a scorecard, and optionally `STORY.md` or `docs/backlog/<slug>.md`. O1 uses the scorecard rubric file without calling this skill. O2 calls this skill when a question is still open. Detail: [03](03-backlog-shape.md).

### `requirement-review`

Challenges one feature or story before SDD. `--feature` checks the functional structure, splits acceptance criteria into atoms, and asks questions with a decision owner. `--tech` grounds named contracts and flows in the repository and records technical follow-ups for `sdd-spec`. Writes a review report and Q&A history under `REFINE/` after confirmation. `refine-story` calls it at step 4a. Detail: [03](03-backlog-shape.md).

### `split-story-checklist`

Optionally turns a story into a dependency checklist (`REFINE/tasks.md`). `sdd-plan` may derive steps directly from the PRD instead. A direct invoke with no steps returns to `/refine-story`. Does not create new story folders. Detail: [03](03-backlog-shape.md).

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

### `arduino-developer`

Configuration-aware Arduino sketches, libraries, and Arduino Core firmware. Requires evidence for the target, core/version, tooling, provenance, and validation boundary; native ESP-IDF and MicroPython work hand off to their dedicated skills. Detail: [04](04-implement-and-guidelines.md).

### `esp-idf-developer`

Native ESP-IDF C/C++ firmware using the project’s declared target, version, CMake configuration, `idf.py` workflow, and Component Manager metadata. Keeps host, compile, device, and HIL evidence separate. Detail: [04](04-implement-and-guidelines.md).

### `micropython-developer`

MicroPython firmware for identified ESP32 or ESP8266 targets. Keeps host CPython tooling/tests, deployment, and device-runtime evidence separate and does not generalize APIs across ports or builds. Detail: [04](04-implement-and-guidelines.md).

### `blip-plugin-developer`

Scaffolds a **new** Blip React plugin and records the profile. Does not implement the feature set. Hands UI implementation to `react-developer`, a backend to `dotnet-developer`, and a full spec to `sdd-spec`. A project-specific design brief can be written before substantial UI implementation. An existing `blip-ds` project starts at `react-developer` instead. Detail: [04](04-implement-and-guidelines.md).

## Review and change

### `code-review`

Review of a branch against guidelines and, when found, PRD/PLAN. Asks single versus multi-angle. Findings name a file and a line, severity `critical`, `important`, or `nice-to-have`. `advisory` is not a finding band. A `critical` finding stays blocking until a fix and a new review, at most three rounds. Decisions: Approved, Approved with reservations, Changes required. Does not edit code. First step when an O3 scope closes. Detail: [05](05-review-and-quality.md).

### `implementation-survey`

Describes what changed and how the implementation appears to work. The report opens with the external observable goal and does not approve. It is not a mode of `code-review`. Detail: [05](05-review-and-quality.md).

### `test-coverage`

.NET Coverlet report. Default 80% line coverage on changed production files. Writes `TestResults/CoverageReport/`. Does not block merge by itself; `code-review` applies the threshold. Called from `run-tests` only when the PLAN asks for coverage. Detail: [05](05-review-and-quality.md).

### `run-tests`

Runs the test command of each detected stack and returns `PASS` or `FAIL`. Does not edit code and does not replace `test-coverage`. Used at the end of an O3 scope, after `code-review`. Detail: [05](05-review-and-quality.md).

### `repair-dotnet-build`

Local `dotnet build` / `dotnet test`, or a pasted log. One error at a time. Proposes each fix and waits. Does not call a remote CI API and does not cover Node or Python. Detail: [05](05-review-and-quality.md).

### `refactor`

One safe refactor step with tests still green. Does not mix in features or bugfixes. No auto-commit. Detail: [05](05-review-and-quality.md).

### `performance-profile`

Finds a hot path, waits for a workflow choice, then proves the change with a micro-benchmark. Does not bypass a domain rule for speed. Detail: [05](05-review-and-quality.md).

### `framework-upgrade`

Modes `audit`, `plan`, `migrate`, `validate`. Packs on disk: `angular`, `dotnet`. Migrate needs a `confirm` answer. The skill id never includes a version number. Detail: [06](06-framework-upgrade.md).

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

### `adt-settings`

Shows or saves the general model and effort for subagents, or returns to inheriting. The saved pair only preselects the one-time session question; unsupported or unverified adapter options keep inheriting the parent pair.

### `commit`

Conventional Commit on a valid feature branch after the message is approved. Does not ask about memory bank or project docs, and does not start a refresh. Strips any `Co-authored-by` trailer. Does not open a pull request. Push or a pull request runs only when that same request already includes it. Detail: [08](08-git-and-docs.md).

### `push`

`git push -u origin HEAD` after the branch check. If a pull request was already requested, enters `open-github-pr`. Otherwise asks. Detail: [08](08-git-and-docs.md).

### `open-github-pr`

Creates the pull request with `gh`. Feature into `develop` uses squash when auto-merge is enabled. Release from `develop` into `master` or `main` uses rebase. Asks for a `confirm` answer on content and, separately, whether to enable auto-merge. Detail: [08](08-git-and-docs.md).

### `document-plan`

Asks documentation language once, then writes `docs/overview.md` and `docs/documentation-plan/plan.md`. Does not write feature PLANs. For this repository the language is English. Detail: [08](08-git-and-docs.md).

### `document-implement`

Executes one pending step of that documentation plan, then stops. Detail: [08](08-git-and-docs.md).

## Count

`CATALOG.md` groups the same 45 ids: Classic SDD 4, Backlog Refine 2, Orchestrated Delivery 4, developer routing and stack 14, Blip 1, operational 18, documentation 2.
