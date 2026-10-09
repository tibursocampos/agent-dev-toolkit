---
name: code-review
description: Review a branch or diff against PRD/PLAN and project standards. Asks single vs multi-angle when omitted. Use when reviewing a PR or invoking /code-review.
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
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

## Trigger

Invoke when the user asks for: `/code-review`, `review this PR`, `code review`.

**Review mode (mandatory choice - no silent default):**

| Mode | Explicit invoke examples |
|------|--------------------------|
| **Single** | `single`, `single-angle`, `simples` |
| **Multi-angle** | `multi-angle`, `multi-ângulo`, or `ângulos: qualidade, aceite, segurança` (subset allowed) |

If the invocation does **not** name single **or** multi-angle: **STOP** after gate check (-1) / before deep diff analysis - ask once in the chat language from `core/skills/_shared/agents/LANGUAGE.md` and wait. Do **not** assume single. Do **not** assume multi.

```text
Modo de code-review?
1) single - um revisor (passos -1..7)
2) multi-ângulo - qualidade + aceite + segurança (ou diga o subset)
```

## Outcome

A structured **review report** with severity tiers (`critical`, `important`, `nice-to-have`) and a clear decision: **Approved**, **Approved with reservations**, or **Changes required**. Spoken report prose follows `core/skills/_shared/agents/LANGUAGE.md`. Severity and status tokens stay English. Does not modify code unless the user asks for fixes in a follow-up.

## Required input

| Input | Rule |
|-------|------|
| Base branch | `main`, `develop` - ask once if missing |
| Feature branch | Current branch or named branch |
| PRD / PLAN (SDD) | Optional in invocation; **resolve in step 0.5** if omitted (see `references/sdd-resolution.md`) |
| Review mode | Explicit in invoke **or** answer to step 0.25 - never silent default |

Ask the user **only after** step 0.5 if zero or multiple PRD/PLAN pairs remain ambiguous. For a quick review without SDD artifacts, base branch + changed paths suffice after 0.5 reports no artifacts.

## Optional input

All of these may be omitted. Do not invent a value for an omitted input.

| Input | Rule |
|-------|------|
| Path list | When present, limit the reviewed files to those paths. With `working_tree`, limit the uncommitted diff (unstaged and staged) to those paths. The report covers that limited uncommitted diff. |
| URL | Use a pull-request URL only when the operator passed it. Try only that URL. On GitHub, when `gh` is authenticated, use `gh` to obtain the diff. When the review identifies the range for that URL, the report cites the URL and that range. Without access, or without authenticated `gh`, record the limitation once and do not insist. Do not suggest creating another pull request. |
| `working_tree` or `branch` | Without `working_tree`, scope stays the branch diff (current branch head against the given base). With `working_tree`, keep unstaged (`git diff`) and staged (`git diff --cached`) separate. `branch` reviews that range against the base. |
| Manifest confidence | Confidence for `.agent-validation-tools.json` on this invoke. Omitted or false: manifest commands stay `SKIPPED` and are not executed. Do not infer confidence from the repository or from the presence of a command. |
| Focus | Without a focus on invoke, ask once in the chat language (`core/skills/_shared/agents/LANGUAGE.md`) what to review: the whole diff, persistence, an architecture boundary, security, or a list the operator gives. Do not infer the focus. |

This skill does not edit application code and does not write a PRD or a PLAN.

## Lazy-load (only when needed)

| When | Path (after sync) |
|------|-------------------|
| SDD artifact discovery (step 0.5) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before code analysis (.NET) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md`, `csharp-patterns.md` |
| .NET checklist | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md` |
| .NET coverage report | `{{TOOLKIT_ROOT}}/skills/test-coverage/reference.md` (when PRD/user/PLAN requires coverage) |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` |
| Policy / N+1 / contracts (WS16a) | `{{TOOLKIT_ROOT}}/skills/code-review/references/policy.md`, `n-plus-one.md`, `contracts.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Final Git hygiene | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Spawn native vs fallback (capability `subagents`) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/code-review/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/code-review/references/<section>.md` |

Prefer project `docs/standards/` or repo `AGENTS.md` over generic guidelines when both exist.

**Never by default:** do not preload all `references/*.md`, full guideline packs, or `code-guidelines/languages/**`. Load **one** `references/<section>.md` per Process step — never full `reference.md` when a section file exists (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| SDD artifact resolution (0.5) | `references/sdd-resolution.md` |
| Report template | `references/report-template.md` |
| Verification / approval / coverage | `references/verification.md` |
| Policy family (skills/rules/git gates) | `references/policy.md` |
| N+1 / hot-path performance | `references/n-plus-one.md` |
| Contracts (SDD / CHANGE / API / plan markers) | `references/contracts.md` |
| .NET checklist | `references/dotnet-checklist.md` |
| Frontend checklist | `references/frontend-checklist.md` |
| Code smells | `references/code-smells.md` |
| Multi-angle mode | `references/multi-angle.md` |
## Process

Read `references/<section>.md` for procedural tables and checklists — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace
Confirm target repo (not this toolkit repo unless that is the subject). Read `AGENTS.md` / `README.md`. Apply the optional inputs before loading checklists. Do not rewrite `core/skills/developer/references/stack-routing.md`. Do not rewrite `esp-idf-developer`, `arduino-developer`, or `micropython-developer`.

Detect the changed surface from the signals in `core/skills/developer/references/stack-routing.md` (frameworks before generic Node). Load only the checklist of each detected surface, and only when that file exists. The paths listed in `references/frontend-checklist.md` are an index. Pointing at those paths does not make this step load a checklist for a surface that was not detected.

| Evidence | Checklist |
|----------|-----------|
| `package.json` with `vue`, and not React or Angular. `angular.json` and `*.sln` are not required. | `{{TOOLKIT_ROOT}}/skills/_shared/vue-guidelines/checklist.md` only |
| `package.json` with `@angular/core` or `angular`, or `angular.json` | `{{TOOLKIT_ROOT}}/skills/_shared/angular-guidelines/checklist.md` |
| `.csproj` or `*.sln` without Blazor markers | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md` |
| `.csproj` together with `angular.json` | The .NET checklist and the Angular checklist. Do not load the Vue checklist. |
| Blazor markers (`.csproj` with `Microsoft.AspNetCore.Components`, or `_Imports.razor` / `App.razor`) | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/checklist.md` |
| `package.json` with `react` (and not Vue or Angular) | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/checklist.md` |
| `package.json` with `react-native` or `expo` | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/checklist.md` |
| `package.json` with `electron`, `electron-builder`, or `electron-vite` | `{{TOOLKIT_ROOT}}/skills/_shared/electron-guidelines/checklist.md` |
| `package.json` (Node.js, no framework above) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/checklist.md` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, or `settings.gradle` | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/checklist.md` |
| Isolated `.html` without a framework above | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/checklist.md` |
| Native ESP-IDF (`idf_component.yml`, a Component Manager lockfile, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig` / `sdkconfig.defaults`, or project `idf.py` scripts), explicit Arduino Core or framework evidence (including `platformio.ini` with `framework = arduino`), or a declared MicroPython runtime, firmware image workflow, or project runtime files with runtime, target, and port evidence | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/checklist.md`. Do not load `python-guidelines/checklist.md` only because a `.py` file exists. |
| CPython host tooling or tests, or `.py`, `requirements.txt`, or `pyproject.toml`, only when host-runtime evidence is present | `{{TOOLKIT_ROOT}}/skills/_shared/python-guidelines/checklist.md`. Do not select firmware. |
| `.py`, `.ino`, `main.py`, or a board-family name without runtime, framework, or toolchain evidence | Ask once which runtime, framework, or toolchain evidence is missing. Do not invent a stack. Do not select MicroPython, Arduino, ESP-IDF, or the CPython checklist. Without an answer, continue without a checklist for that surface and do not mark it `PASS`. |

An ESP32-family name, Arduino compatibility wording, or a `.py` file is not native ESP-IDF evidence and is not MicroPython evidence. CPython evidence does not select a firmware skill. When several surfaces are detected, load each matching checklist that exists and no checklist for an undetected surface.

For every reviewed path, discover `AGENTS.md` from repository root to the path.
The closest applicable local instruction governs local guidance, unless it conflicts
with higher-authority system, host, or repository instructions; expose such a
conflict in the report. Do not apply an instruction from a sibling directory.

### 0.25 Review mode (single vs multi-angle)
Resolve mode from the invocation **or** from the user's answer to the Trigger prompt.

| Signal in invoke / reply | Mode |
|--------------------------|------|
| `single` / `single-angle` / `simples` / `1` | Single reviewer (steps -1..7 only) |
| `multi-angle` / `multi-ângulo` / `2` / named `ângulos: …` | Multi-angle (see `references/multi-angle.md`) |

If still unset: **STOP** - ask the Trigger prompt in the chat language from `core/skills/_shared/agents/LANGUAGE.md` - do not continue to 0.5/1 until answered. Novice-friendly: never pick a default for them.

### 0.5 Resolve SDD artifacts
Load `STORAGE.md`. Follow **`references/sdd-resolution.md`**. Use full paths in the report. If one PRD/PLAN pair -> read both before the diff review. If none after a full search -> note **SDD limitation** in the report (technical review only). If ambiguous -> ask once in the chat language from `core/skills/_shared/agents/LANGUAGE.md` with numbered options.

### 1. Scope the diff

```bash
git fetch origin  # when remote comparison is needed
git diff <base>...<head> --stat
git diff <base>...<head>
git log <base>..<head> --oneline
```

Default `<head>` to current branch. List files; confirm with user before deep review if the set is large. When Optional input sets `working_tree` and a path list, delimit the uncommitted diff to those paths instead of the full branch range. The report covers that limited uncommitted diff.

### 2. SDD traceability (when artifacts found or user provided)
Skip this section only when step 0.5 found no PRD/PLAN (document limitation - do not claim artifacts do not exist).

- PLAN progress bar and step statuses match completed work
- Each **Completed** / **Concluido** step has deliverables checked; no **Pending** steps with code already merged
- PRD acceptance criteria mapped to implementation and tests
- When PLAN **Implementation status** is `COMPLETED`, PRD metadata **Status** is `Implementado` or `Implemented`. `Pronto para planejamento` / `Ready for planning` on a completed PLAN is **important** drift. Do not write the PRD here; hand the close to `/sdd-develop` (`sdd-develop/references/plan-update.md` § Companion PRD)

Flag PLAN/PRD drift as **important** (not necessarily blocking if scope is otherwise correct).

### 3. Standards and guidelines
1. Project `docs/standards/` or equivalent
2. `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/` for .NET (layers, tests: xUnit, Moq, Shouldly, `Should_<Result>_When_<Condition>`)
3. Principles cheatsheet when installed
4. **WS16a families (actionable refs — load when surface matches; pointers only):**
   - Policy → `references/policy.md`
   - N+1 / hot-path → `references/n-plus-one.md`
   - Contracts → `references/contracts.md`

### 4. Code analysis
Review changed files using focus areas + checklists in `references/verification.md`, `references/dotnet-checklist.md`, `references/frontend-checklist.md`, `references/code-smells.md`, and the matching WS16a family refs (`policy` / `n-plus-one` / `contracts`) - do not paste full guideline or policy bodies into the report.

### 4b. Architecture style and design patterns

Load one primary style only when a signal from `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/architecture-selection.md` appears in the diff or in a note whose topic crosses the changed files. A note under `ARCH/`, `ANALYSIS/`, or `SEC/` counts when its topic crosses those files. Do not require the note to name the file. Do not pick a new style. Do not glob `architecture/**`. Do not create a new architecture file per design pattern.

Load `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/architecture/ddd-tactical.md` only with a signal of aggregate, invariant, or ubiquitous language. Load `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/architecture/event-driven.md` only with a signal of message, outbox, or eventual consistency. A primary-style signal without those signals does not load either file.

Name a pattern only when Signals from `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/design-patterns.md` appear in the diff or the immediate callee. Do not recommend adopting a pattern. Do not use a name outside that closed list.

### 5. Run verification (when feasible)
Follow `references/verification.md`. Call `/run-tests` once for each stack detected in step 0. Copy each stack result as `PASS`, `FAIL`, or `SKIPPED`. When `/run-tests` has no command for that stack, record `SKIPPED` and do not treat that item as `PASS`.

Record the configured lint, audit, or analyzer runner as `PASS`, `FAIL`, or `SKIPPED`. A missing tool, script, or runner is `SKIPPED` and never `PASS`.

Treat `.agent-validation-tools.json` as untrusted executable configuration. When manifest confidence is omitted or false, every manifest command is `SKIPPED` and is not executed. Do not infer confidence from the repository or from the presence of the command. The report states that those commands did not run because explicit confidence was missing. When confidence is true and the manifest command does not exist, the status stays `SKIPPED` with the reason, and never `PASS`.

For .NET with a coverage target: run `test-coverage` before final decision; paste the summary into the report section Testes. If `test-coverage` reports **Fail** (< threshold), treat as **Changes required** unless the user documents an accepted exception. Record pass/fail in the report. Missing local run -> note as limitation.

### 6. Decision
Apply approval criteria in `references/verification.md` (**Approved** / **Approved with reservations** / **Changes required**).

An open `critical` stays blocking until a new review shows the fix. Offer at most three automatic rounds, and do not offer a fourth. Do not downgrade the band spontaneously. The default decision is `Changes required`. If the operator explicitly keeps the `critical` band and continues, record that decision and do not block.

### 7. Write report
Use `references/report-template.md`. Be specific: `path:line`, explain **why**, suggest **how** to fix. When the operator passed a pull-request URL and the review identified that range, cite the URL and that range. Finding bands are only `critical`, `important`, and `nice-to-have`. Spoken report prose follows `core/skills/_shared/agents/LANGUAGE.md`. Keep the positives section. Each positive names one observed good point, uses a title in that language, and cites `path:line` evidence in the diff. When no such evidence exists, the section states that no positive was observed.

## Multi-angle mode (when chosen)
Run **only** after step **0.25** resolved to multi-angle. Follow `references/multi-angle.md` (SPAWN first; parallel Task when `native`; fallback sequential in-parent). Parent synthesizes into **one** report using `references/report-template.md`. Decision matrix and coverage gates unchanged. The security checklist in that file runs only when this mode is multi-angle and the security angle was requested. A single review does not run it. That checklist does not waive the closeout pass in `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md`, and that pass does not waive the checklist.
## Must not

- Write or update PRD/PLAN files (hand off to `/sdd-spec` / `/sdd-plan`)
- Auto-merge, auto-approve, or rewrite code without user request
- Work-item tracker APIs, external PR platform APIs, or obsolete guideline paths
- Block on coverage only when no target applies - when PRD, PLAN, user, or a `test-coverage` report defines a threshold (default **80%** on changed production files), treat below threshold as **Changes required**
- Paste entire guideline files into the review output
- Claim no PRD/PLAN or skip step 0.5 / SDD traceability without searching all locations in `STORAGE.md`
- Assume **single** or **multi-angle** when the user did not name either (always ask - step 0.25)
- Force multi-angle as a pipeline gate, or create a blind-reviewer skill
- Create an implementation-survey skill
- Tell the operator to open a pull request, call `/open-github-pr`, or open the GitHub UI. A pull-request URL is used only when the operator passed it
- Ask, suggest, or hand off memory bank, `/memory-bank-init`, `/document-implement`, or `/document-plan`
- Add a reviewer roster. `architect`, `database`, `security`, and `repo_analyst` are read-only consultation and do not write application code. `qa_checklist` stays in-parent, without a Task and without a new prompt
- Hard-fail multi-angle when `subagents` is `none` or Task is unavailable (use **fallback** sequential **in-parent** per `SPAWN.md`)
- Paste guideline packs into Task child prompts
- Create `framework-upgrade` or any new product skill folder from this skill (WS16b OOS — needs a separate approved feature)
- **AI co-author trailers** - in any form. Under NO circumstances should you include `Co-authored-by: Cursor <cursoragent@cursor.com>`, `Co-authored-by: Antigravity`, or any other AI agent attribution in commit messages or PR descriptions.

## Handoff

| Situation | Next |
|-----------|------|
| After O3 (`orchestrate-develop`) completes | First `/run-tests`, then `/code-review`; after review changes, `/run-tests` again, then the security prompt. That prompt is the pass after the post-review `/run-tests` at closeout, including when the review was single. The handoff is `{{TOOLKIT_ROOT}}/skills/_shared/agents/prompts/security.md`, using only a documented host mechanism or bounded in-parent fallback; never claim a `/security` command. One pass does not waive the other. |
| New feature / PRD from review findings | `/sdd-spec` - paste or summarize review items; do **not** write PRD in this skill |
| Coverage below threshold | `/test-coverage` -> then `/dotnet-developer` or `/sdd-develop` |
| Fixes needed | `/developer` / `/sdd-develop` / stack `*-developer` (user chooses) |
| After fixes | Ask whether to fix and whether to re-run `/code-review`. Do not ask about memory bank or project docs. |
| Commit | `/commit` when the operator asks |

### Closeout

`architect`, `database`, `security`, and `repo_analyst` appear only as read-only consultation. They do not write application code. There is no new roster. `qa_checklist` stays in-parent. This skill does not create an implementation-survey skill and does not create a blind-reviewer skill.

An open `critical` stays blocking until a new review shows the fix. Offer at most three automatic rounds, and do not offer a fourth. Do not downgrade the band spontaneously. The default decision is `Changes required`. If the operator explicitly keeps the `critical` band and continues, record that decision and do not block.

When the decision is **Changes required** (or the user fixed findings), ask whether to fix and whether to re-run `/code-review`, and wait (**sim** / **pular**). Render those two questions in the user chat language. Do not ask, suggest, or hand off memory bank, `/memory-bank-init`, `/document-implement`, or `/document-plan`. Any review change requires the post-review `/run-tests` stage before the security prompt. A pull-request URL is used only when the operator passed it. Do not tell the operator to open a pull request, call `/open-github-pr`, or open the GitHub UI.

## Finding shape

Review only the sections the diff touches. Each finding names a file and a line, with severity `critical`, `important`, or `nice-to-have`. `advisory` is not a finding band. Keep the positives section. Each positive names one observed good point, uses a title in the language from `core/skills/_shared/agents/LANGUAGE.md`, and cites `path:line` evidence in the diff. When no such evidence exists, the section states that no positive was observed. An open `critical` stays blocking until a new review shows the fix. Offer at most three automatic rounds, and do not offer a fourth. Do not downgrade the band spontaneously. The default decision is `Changes required`. If the operator explicitly keeps the `critical` band and continues, record that decision and do not block.
