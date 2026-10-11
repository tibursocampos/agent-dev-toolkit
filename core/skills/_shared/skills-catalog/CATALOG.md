# Skills catalog (agent SoT)

Lean skill map for agents after install. **Do not invent skills** — only names listed here exist as skill ids. Invoke by **skill id**; host prefixes: `/id` (Cursor/Claude/Copilot/Grok), `$id` (Codex/ZCode), `use skill id` or `/id` (Antigravity), OpenCode `skill` tool. Compat: `use skill <id>` / natural language. Full host matrix: sibling `OPERATOR.md`.

**Load via skill `help-skills`** (or Read this path). Operator nuances: sibling `OPERATOR.md` in this folder. Shared packs under `_shared/` are not invocable skills. There is **no** `architect` skill — architect is spawned from `orchestrate-analyze` / the agent roster.

Installed path (after sync): `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md`

Total: **45** kebab skills.

## Tracks

| Track | Skills | When |
|-------|--------|------|
| **Classic SDD** | `sdd-spec`, `sdd-plan`, `sdd-develop`, `read-sdd-artifact` | One clear feature |
| **Backlog Refine** | `refine-story`, `split-story-checklist` | Rough bug/story first |
| **Orchestrated Delivery** | `memory-bank-init`, `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop` | Multi-story / brownfield |

**Track choice:** tracks are recommendations only. Classic SDD does **not** require Orchestrated Delivery first. Start with `/sdd-spec` or `/sdd-plan` whenever one feature has a clear path.

## Classic SDD

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `sdd-spec` | `sdd-spec` | Create a PRD for a new feature or change |
| `sdd-plan` | `sdd-plan` | Baby-step PLAN from an existing PRD |
| `sdd-develop` | `sdd-develop` | Execute **one** PLAN step per session |
| `read-sdd-artifact` | `read-sdd-artifact` | Normalize FEATURE/STORY/PRD/PLAN → `source_context` envelope |

## Backlog Refine — backlog prep

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `refine-story` | `refine-story` | Refine bug/story into structured markdown + BDD |
| `split-story-checklist` | `split-story-checklist` | Dependency-aware task checklist (BE/FE/tests) |

## Orchestrated Delivery — orchestration

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `memory-bank-init` | `memory-bank-init` | Create/refresh `memory-bank/` at repo or global root (Step 0; never under `features/NNN-slug/`) |
| `orchestrate-analyze` | `orchestrate-analyze` | Triage, specialists, backlog structure |
| `orchestrate-deliver` | `orchestrate-deliver` | PRD + PLAN per story via SDD contracts |
| `orchestrate-develop` | `orchestrate-develop` | One PLAN step per subagent via `sdd-develop` |

## Developer routing and stack

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `developer` | `developer` | Hybrid router: detect stack or ad-hoc scripts |
| `dotnet-developer` | `dotnet-developer` | Small/medium .NET without full SDD |
| `java-developer` | `java-developer` | Small/medium Java / Spring Boot |
| `react-developer` | `react-developer` | Small/medium React |
| `react-native-developer` | `react-native-developer` | React Native / Expo |
| `angular-developer` | `angular-developer` | Angular |
| `arduino-developer` | `arduino-developer` | Arduino sketches, libraries, and Arduino Core projects |
| `vue-developer` | `vue-developer` | Vue 3 |
| `blazor-developer` | `blazor-developer` | Blazor (WASM/Server/Hybrid) |
| `electron-developer` | `electron-developer` | Electron desktop |
| `esp-idf-developer` | `esp-idf-developer` | Native ESP-IDF C/C++ firmware |
| `javascript-developer` | `javascript-developer` | JavaScript/Node |
| `micropython-developer` | `micropython-developer` | MicroPython device firmware for identified ESP32/ESP8266 targets |
| `python-developer` | `python-developer` | Python |

## Blip plugins and design

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `blip-plugin-developer` | `blip-plugin-developer` | Scaffold Blip React extensions → `react-developer` |

## Operational

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `help-skills` | `help-skills`, `list skills`, `skill catalog` | Present this catalog + `OPERATOR.md` (static) |
| `code-review` | `code-review` | Structured review (quality / acceptance / security) |
| `implementation-survey` | `implementation-survey` | Describe what changed and how the implementation appears to work |
| `repair-dotnet-build` | `repair-dotnet-build` | Diagnose/fix .NET build and tests |
| `test-coverage` | `test-coverage` | .NET Coverlet coverage report |
| `run-tests` | `run-tests` | Run detected-stack tests; .NET coverage only when the PLAN asks |
| `commit` | `commit`, `commit changes` | Conventional commit on a valid feature branch |
| `push` | `push`, `push changes` | Safe git push after confirmation |
| `open-github-pr` | `open-github-pr` | Create GitHub PR via `gh` |
| `ef-add-migration` | `ef-add-migration` | EF Core migration discovery |
| `scaffold-message-handler` | `scaffold-message-handler` | Message consumer scaffold |
| `refactor` | `refactor` | Safe incremental refactoring |
| `api-integrate` | `api-integrate` | Typed API clients from OpenAPI |
| `api-standards` | `api-standards`, `api standards`, `REST conventions` | Agnostic HTTP/API design standards (no company contracts; packing only) |
| `framework-upgrade` | `framework-upgrade` | Generic framework upgrade orchestrator (audit\|plan\|migrate\|validate; pluggable packs — not a pinned pack) |
| `performance-profile` | `performance-profile` | Profiling and optimization |
| `containerize` | `containerize` | Dockerfiles and compose |
| `i18n-manager` | `i18n-manager` | Extract strings to localization files |

## Documentation (RAG)

| Skill | Id / phrases | Purpose |
|-------|--------------|---------|
| `document-plan` | `document-plan`, `doc plan` | Baby-step documentation plan |
| `document-implement` | `document-implement` | Execute one documentation plan step |

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
