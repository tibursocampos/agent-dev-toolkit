# Skills catalog (agent SoT)

Lean skill map for agents after install. **Do not invent skills** — only names listed here exist as skill ids. Invoke by **skill id**; host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full host matrix: sibling `OPERATOR.md`.

**Load via skill `adt-help-skills`** (or Read this path). Operator nuances: sibling `OPERATOR.md` in this folder. Shared packs under `_shared/` are not invocable skills. There is **no** `architect` skill — architect is spawned from `adt-orchestrate-analyze` / the agent roster.

Installed path (after sync): `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md`

Total: **52** kebab skills.

## Tracks

| Track | Skills | When |
|-------|--------|------|
| **Classic SDD** | `adt-sdd-spec`, `adt-sdd-plan`, `adt-sdd-develop`, `adt-read-sdd-artifact` | One clear feature |
| **Backlog Refine** | `adt-refine-story`, `adt-requirement-review`, `adt-split-story-checklist` | Rough bug/story first; challenge before SDD |
| **Orchestrated Delivery** | `adt-epic-planner` (optional initiative discovery), `adt-memory-bank`, `adt-orchestrate-analyze`, `adt-orchestrate-prepare`, `adt-orchestrate-implement` | Optional initiative planning; multi-story / brownfield delivery |
| **ADT Delivery** | `adt-delivery-flow`, `adt-delivery-refine`, `adt-delivery-plan`, `adt-delivery-implement` | One evolving feature plan from refinement through implementation and code review |

**Track choice:** tracks are recommendations only. Classic SDD does **not** require Orchestrated Delivery first. Start with `/adt-sdd-spec` or `/adt-sdd-plan` whenever one feature has a clear path.

## Classic SDD

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-sdd-spec` | `adt-sdd-spec` | Create a PRD for a new feature or change |
| `adt-sdd-plan` | `adt-sdd-plan` | Executable PLAN from a PRD or sufficiently specified demand; one approval before implementation |
| `adt-sdd-develop` | `adt-sdd-develop` | Execute an approved PLAN step-by-step or continuously, using PLAN as the progress source |
| `adt-read-sdd-artifact` | `adt-read-sdd-artifact` | Normalize FEATURE/STORY/PRD/PLAN → `source_context` envelope |

## Backlog Refine — backlog prep

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-refine-story` | `adt-refine-story` | Refine bug/story into structured markdown + BDD |
| `adt-requirement-review` | `adt-requirement-review` | Challenge a feature or story before SDD: `--feature` (functional) or `--tech` (repository-grounded) |
| `adt-split-story-checklist` | `adt-split-story-checklist` | Dependency-aware task checklist (BE/FE/tests) |

## Orchestrated Delivery — orchestration

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-epic-planner` | `adt-epic-planner` | Discover a multi-feature initiative and persist one navigable `EPIC.md`; optional context for O1 |
| `adt-memory-bank` | `adt-memory-bank` | Create/refresh `memory-bank/` at repo or global root (Step 0; never under `features/NNN-slug/`) |
| `adt-orchestrate-analyze` | `adt-orchestrate-analyze` | Proportional triage, targeted specialist analysis, and justified backlog structure |
| `adt-orchestrate-prepare` | `adt-orchestrate-prepare` | Prepare PRD + PLAN per selected story; one approval for the complete listed PLAN set |
| `adt-orchestrate-implement` | `adt-orchestrate-implement` | Serial PLAN-step queue via `adt-sdd-develop`; reconcile each result before dispatch |

## ADT Delivery

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-delivery-flow` | `adt-delivery-flow` | Coordinate refinement, planning and implementation |
| `adt-delivery-refine` | `adt-delivery-refine` | Refine the demand in the feature plan |
| `adt-delivery-plan` | `adt-delivery-plan` | Complete the same plan for approval |
| `adt-delivery-implement` | `adt-delivery-implement` | Execute the approved plan, validate and run code review |

The flow uses one evolving `PLAN.md` and the existing `adt-code-review` skill; it does not use cold review.
ADT delivery does not use workflow hooks or per-step session gates by design.

## Developer routing and stack

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-developer` | `adt-developer` | Hybrid router: detect stack or ad-hoc scripts |
| `adt-dotnet-developer` | `adt-dotnet-developer` | Small/medium .NET without full SDD |
| `adt-java-developer` | `adt-java-developer` | Small/medium Java / Spring Boot |
| `adt-react-developer` | `adt-react-developer` | Small/medium React |
| `adt-react-native-developer` | `adt-react-native-developer` | React Native / Expo |
| `adt-angular-developer` | `adt-angular-developer` | Angular |
| `adt-arduino-developer` | `adt-arduino-developer` | Arduino sketches, libraries, and Arduino Core projects |
| `adt-vue-developer` | `adt-vue-developer` | Vue 3 |
| `adt-blazor-developer` | `adt-blazor-developer` | Blazor (WASM/Server/Hybrid) |
| `adt-electron-developer` | `adt-electron-developer` | Electron desktop |
| `adt-esp-idf-developer` | `adt-esp-idf-developer` | Native ESP-IDF C/C++ firmware |
| `adt-javascript-developer` | `adt-javascript-developer` | JavaScript/Node |
| `adt-micropython-developer` | `adt-micropython-developer` | MicroPython device firmware for identified ESP32/ESP8266 targets |
| `adt-python-developer` | `adt-python-developer` | Python |

## Blip plugins and design

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-blip-plugin-developer` | `adt-blip-plugin-developer` | Scaffold Blip React extensions → `adt-react-developer` |

## Operational

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-help-skills` | `adt-help-skills`, `list skills`, `skill catalog` | Present this catalog + `OPERATOR.md` (static) |
| `adt-settings` | `adt-settings` | Show or save the general model and effort for subagents, or return to inheriting |
| `adt-code-review` | `adt-code-review` | Structured review (quality / acceptance / security) |
| `adt-code-explain` | `adt-code-explain` | Explain existing code or describe how it changed, with evidence from opened files |
| `adt-repair-dotnet-build` | `adt-repair-dotnet-build` | Diagnose/fix .NET build and tests |
| `adt-test-coverage` | `adt-test-coverage` | .NET Coverlet coverage report |
| `adt-run-tests` | `adt-run-tests` | Run detected-stack tests; .NET coverage only when the PLAN asks |
| `adt-commit` | `adt-commit`, `adt-commit changes` | Conventional commit on a valid feature branch |
| `adt-push` | `adt-push`, `adt-push changes` | Safe git push after confirmation |
| `adt-open-github-pr` | `adt-open-github-pr` | Create GitHub PR via `gh` |
| `adt-ef-add-migration` | `adt-ef-add-migration` | EF Core migration discovery |
| `adt-scaffold-message-handler` | `adt-scaffold-message-handler` | Message consumer scaffold |
| `adt-refactor` | `adt-refactor` | Safe incremental refactoring |
| `adt-api-integrate` | `adt-api-integrate` | Typed API clients from OpenAPI |
| `adt-api-standards` | `adt-api-standards`, `api standards`, `REST conventions` | Agnostic HTTP/API design standards (no company contracts; packing only) |
| `adt-framework-upgrade` | `adt-framework-upgrade` | Generic framework upgrade orchestrator (audit\|plan\|migrate\|validate; pluggable packs — not a pinned pack) |
| `adt-performance-profile` | `adt-performance-profile` | Profiling and optimization |
| `adt-containerize` | `adt-containerize` | Dockerfiles and compose |
| `adt-i18n-manager` | `adt-i18n-manager` | Extract strings to localization files |

## Documentation (RAG)

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `adt-document-plan` | `adt-document-plan`, `doc plan` | Baby-step documentation plan |
| `adt-document-implement` | `adt-document-implement` | Execute one documentation plan step |

## Activation contract

A skill is eligible only when at least one positive signal declared in its `SKILL.md` Trigger section matches the request and its required context is present. An explicit request naming one installed skill is a positive signal for that skill and takes precedence over topical similarity to other skills. A skill name appearing only in quoted, negated, or descriptive text is not an activation request. A request that does not meet a skill's declared trigger or required context is a negative signal and must not activate it. General topic similarity, isolated keywords, and assumptions about intent are not sufficient.

Apply this decision order:

1. Honor one direct, unambiguous request to invoke a named installed skill; do not activate a second skill based only on topic overlap.
2. Otherwise, consider only skills whose declared trigger and required context both match. If exactly one qualifies, it is eligible.
3. If multiple skills qualify and the request does not state an unambiguous sequence or division of work, ask which capability the user wants before any mutating action. Do not choose by catalog order, wording similarity, or an undocumented ranking.
4. If no skill qualifies, or required context/signals are missing, activate no skill. If the missing information matters to a requested mutating action, ask for clarification before that action.

An explicit request for multiple named skills is eligible only when it specifies a clear sequence or division of work; otherwise ask for clarification. These rules define no numeric thresholds and contain no host-specific APIs or metadata.

The activation corpus records reproducible positive, negative, overlap, and insufficient-signal examples with exact expected outcomes. Positive examples name one installed skill explicitly; negative examples contain no applicable declared trigger and expect no skill. Overlap cases either identify the eligible explicit skill or expect clarification before mutation; insufficient-signal cases expect no activation. The corpus is expected behavior, not a runtime classifier or proof of provider conformance.

## Flow terminal contract

Every skill flow ends its current invocation with one explicit outcome and the next action. The outcome is terminal for that invocation; a handoff or retry starts only after its stated condition is met.

| Outcome | Use when | Required next action |
|---|---|---|
| `done` | The requested scope and its acceptance conditions are complete. | Report the result and give the exact eligible handoff, if one exists. |
| `blocked` | A required dependency, input, approval, or user decision is missing. | Name what is missing and the action that can resolve it; keep dependent work stopped. |
| `failed` | An attempted operation or validation failed. | Report the observed cause and a bounded recovery action; do not repeat the same transition automatically. |
| `open_question` | A material question awaits the user. | Ask one clear question and wait. Silence, timeout, or end of turn leaves the flow blocked. |

Do not treat an unanswered question, unchanged retry, repeated prompt, or handoff suggestion as completion or authorization. Resume only after new input or changed evidence satisfies the recorded next-action condition; then revalidate the affected gates before proceeding. Each flow's existing Outcome, Handoff, report, or stop instructions must name its applicable condition and next action; a flow with no further transition ends with its completed result. These labels describe skill-flow control, not provider APIs or runtime classifier states.

| Reproducible condition | Expected outcome | Next action |
|---|---|---|
| Acceptance and required validation pass. | `done` | Persist the result and expose only the next eligible handoff. |
| Required dependency or approval is absent. | `blocked` | Name the dependency and stop dependent work until it is available; revalidate before resuming. |
| Validation or operation fails. | `failed` | Report the observed failure and a bounded recovery; do not replay the same attempt automatically. |
| A material user decision is unanswered. | `open_question` (the active work remains `blocked`) | Wait for an answer; silence does not advance. Ask again only after new user input or a changed question context. |
| The prior outcome is unchanged and no new input/evidence exists. | Preserve the prior terminal outcome. | Do not repeat the transition; wait or hand off the recorded recovery condition. |
