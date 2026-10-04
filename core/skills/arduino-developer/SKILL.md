---
name: arduino-developer
description: >-
  Implement or fix Arduino sketches and libraries using the project-declared board, Arduino Core, version, and tooling. Use for Arduino IDE/CLI or configured PlatformIO work when invoking arduino-developer.
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

# Skill: arduino-developer

## Trigger

Invoke `arduino-developer` for Arduino sketches, libraries, board-specific firmware, or Arduino Core projects. Host examples: `/arduino-developer`, `$arduino-developer`, `use skill arduino-developer`.

## Outcome

A configuration-aware implementation or diagnosis for the declared Arduino target. The skill identifies the board/module and revision, Arduino Core and version, dependency provenance, and the configured toolchain before recommending APIs or commands. It reports compile-only, upload, device runtime, and HIL evidence separately.

## Lazy-load

| When | Path |
|------|------|
| Scope and framework boundary | `references/scope.md` |
| Orientation and execution flow | `references/execute-flow.md` |
| Forbidden assumptions and reporting limits | `references/must-not.md` |
| Embedded context and provenance | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/README.md`, `target-and-provenance.md`, `validation-and-reporting.md` |
| Resources and communication | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/resources-and-communication.md` |
| Security and dependencies | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/security-and-dependencies.md` |
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Structure / quality | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |

Do not preload unrelated stack packs or the whole memory bank. Load only the embedded topic needed for the current claim.

## Process

### Step -1b - Caveman Mode (Full cap)

1. Read `{{SDD_ROOT}}/preferences.json`.
2. If `caveman_mode` is false, continue normally.
3. If true, load `_shared/caveman/CAVEMAN.md`, apply the Full cap, and honor the session commands.

### Subagent-first (before implement)

Classify complexity, consult capability `subagents`, and load `SPAWN.md` plus `subagent-first.md`. Medium or complex work may use up to two children with scoped **paths** and a **receipt**; trivial work stays **in-parent**. If unavailable, use the documented **fallback** **in-parent** path.

### 0. Establish the target context

Inspect the project before choosing an Arduino flow. Record each field as `confirmed`, `assumed`, `planned`, `implemented`, or `verified`:

| Field | Required evidence |
|------|-------------------|
| Target | board/module, architecture, variant, and revision |
| Runtime and core | Arduino runtime, Arduino Core family, exact version, and dependency source |
| Tooling | Arduino IDE/CLI or project-configured PlatformIO and its version |
| Source and hardware provenance | project metadata, board specification, datasheet, measurement, or operator input |
| Validation boundary | host-only, compile-only, device runtime, or HIL, with target and scenario |

If a material field is absent, ask for it or report the work as blocked. Do not select a board, core, API, pin, command, or capability from a family name alone.

### Framework and toolchain decision

Treat the framework and the toolchain as separate decisions. Before routing or recommending a command, require project evidence for all of the following:

| Decision | Acceptable evidence | Result when absent |
|---|---|---|
| Arduino framework/core | explicit Arduino Core or Arduino framework declaration, dependency metadata, Arduino CLI/IDE project metadata, or operator-provided project evidence | do not route to this skill; ask for the framework and exact version |
| Arduino Core version | pinned dependency/platform version, lockfile, package metadata, or an explicit project record | block version-sensitive guidance; do not infer it from the board or library name |
| Build/upload tool | Arduino IDE/CLI configuration or command evidence; `platformio.ini`/equivalent with `framework = arduino` for PlatformIO | ask which configured tool is authoritative; do not introduce a tool |
| Debug capability | configured debugger/probe and target support, plus an observed debug session or project declaration | report debug as unavailable or unverified; do not equate compilation or serial logs with debug |

For ESP32 or ESP8266, a board name is never framework evidence. A native ESP-IDF project identified by `idf_component.yml`, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`, or `idf.py` scripts remains ESP-IDF-owned even when the board is ESP32/ESP8266. Route by the declared project framework, not by the board family. Keep MicroPython firmware and CPython host code outside this skill.

### 1. Classify the Arduino artifact

Handle `.ino` sketches, Arduino libraries, and board-specific firmware according to the project’s existing layout and dependency metadata. Preserve the declared library/core versions and source provenance. Do not add a build system or dependency merely to fill a missing context.

For ESP32 or ESP8266, require evidence that the project uses the Arduino Core. Arduino Core may use platform internals, but it remains distinct from native ESP-IDF. Route native ESP-IDF projects to their own workflow; route MicroPython firmware to its own workflow; keep CPython host tools and tests with `python-developer`.

### 2. Choose tooling from configuration

Use Arduino IDE or Arduino CLI only when the project configuration, scripts, metadata, or operator evidence identifies it. Use PlatformIO only when its project configuration is present and relevant. Do not make PlatformIO the default and do not substitute `idf.py`, CMake, MicroPython tooling, or CPython commands for an Arduino flow without evidence.

If PlatformIO is selected, confirm that the relevant environment declares the Arduino framework; a `platformio.ini` containing only a board/platform name is insufficient. If native ESP-IDF signals are present without an Arduino framework declaration, stop the Arduino flow and hand off to the ESP-IDF workflow. If neither framework nor toolchain is identifiable, request the smallest missing project evidence or report a bounded blocker.

### 3. Implement and report narrowly

Apply the project’s selected core and board APIs, then label each result separately:

- compile-only: source/toolchain compatibility for the declared target;
- upload: firmware transfer observed with the named board, port, and tool;
- debug: an observed breakpoint/trace/debug-session result using the named debugger/probe and target configuration;
- device runtime: behavior observed on the named board/revision and configuration;
- HIL: behavior observed with the named fixture, instruments, and scenario.

A successful compile does not prove upload, debug, startup, peripherals, timing, electrical safety, runtime, or HIL. Serial output, logging, and a successful upload are not debug evidence. If the tool, board, core, version, or provenance is insufficient, request the missing data or stop with a bounded blocker.

### 4. Review safety boundaries

Keep Arduino Cloud guidance limited to firmware integration. Do not include dashboard or service administration. Never place credentials in source, examples, logs, or evidence. Qualify TLS, OTA, storage, memory, timing, pinout, voltage, and current claims by target, revision, library/core version, and authoritative source.

## Must not

- Infer Arduino Core, ESP-IDF, MicroPython, or CPython from a board or family name alone.
- Treat native ESP-IDF as an Arduino implementation or reuse `idf.py` without project evidence.
- Treat a compile result as upload, device runtime, or HIL evidence.
- Treat compile, upload, serial logging, or runtime observations as debug evidence without an observed debugger/probe session.
- Presume a universal Arduino IDE, CLI, PlatformIO, board revision, core version, pin map, TLS behavior, or OTA capability.
- Put secrets, real credentials, or private keys in examples, logs, fixtures, or evidence.
- Expand Arduino Cloud into dashboards or administration.
- Paste guideline packs into child prompts, spawn for trivial work, or hard-fail when `subagents` is `none` or Task is unavailable; use scoped paths, receipt, and fallback in-parent behavior.
- Auto-commit, auto-push, or claim hardware validation that was not exercised.

## Handoff

For a larger approved change, use `sdd-develop` with the canonical PLAN path. For a commit, use `commit`; for review, use `code-review`.
