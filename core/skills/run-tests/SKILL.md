---
name: run-tests
description: Run the workspace test command for each detected stack and return pass or fail. Use when invoking /run-tests or when orchestrate-develop closes a story scope.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

1. This skill does not implement code and does not take a plan step
When the parent is `orchestrate-develop` at scope close, the scope **sim** already authorizes the test command. Do not ask for a second **sim** only for that command.

Read-only modes (plan mode or ask): do not run a shell. Say that an edit mode is required.

### Step -1b - Caveman Mode (Full cap)

When caveman is on, load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` and apply the **Full** cap.

---

# Skill: run-tests

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

`/run-tests`, or `orchestrate-develop` closing a story scope.

This skill does not replace `test-coverage`. It does not choose a stack in place of `developer` when the request is to implement.

## Outcome

One report per detected stack, then an overall result. Tokens `PASS`, `FAIL`, and `SKIPPED` stay English. Sentences follow the user chat language.

## Lazy-load

| When | Path |
|------|------|
| Stack order | `references/stack-detect.md` |
| Command per stack | `references/commands.md` |
| Report shape | `references/report.md` |
| Must not | `references/must-not.md` |
| Caveman | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` |
| Reference index | `reference.md` |

Do not load every developer guideline pack.

**Never by default:** do not preload every stack guideline or every `references/*.md`. Load one section for the detected stack.

## Process

1. Detect stacks with `references/stack-detect.md`. None: stop `stack_not_detected` and ask. Do not run a generic test.
2. For each stack, run the command in `references/commands.md`. A missing command stops that stack with `stack_test_command_missing`.
3. Emit `references/report.md`. Overall `PASS` only when every stack passed. A missing check is `SKIPPED` with a reason. It is not `PASS`.
