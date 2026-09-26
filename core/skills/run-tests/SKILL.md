---
name: run-tests
description: Run the workspace test command for each detected stack and return pass or fail. Use when invoking /run-tests or when orchestrate-develop closes a story scope.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask the user in the **user chat language** (`LANGUAGE.md`) - do **NOT** Write/Shell
4. This skill does not implement code and does not take a plan step
5. This skill body is **English**. The report follows the user chat language (`LANGUAGE.md`)

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] User confirmed current action (sim) when invocation is direct
-> If any unchecked: STOP
```

When the parent is `orchestrate-develop` at scope close, the scope **sim** already authorizes the test command. Do not ask for a second **sim** only for that command.

Plan mode or Ask: do not run a shell. Say that Agent mode is required.

### Step -1b - Caveman Mode (Full cap)

When caveman is on, load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` and apply the **Full** cap.

---

# Skill: run-tests

## Trigger

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
