---
description: Non-negotiable agent rules for every conversation - git, write confirmation, one step per session, tests, language
alwaysApply: true
---

# Guardrails - non-negotiable agent rules

**Applies to:** every skill in agent-dev-toolkit - SDD, developer, operational, and documentation skills.

Full enforcement context: `docs/ENFORCEMENT.md` in the toolkit repo.

---

## STOP - read first (every conversation, turn 1)

Before **any** tool call (`Read`, `Write`, `Shell`, etc.):

1. Read this rule (`{{GUARDRAILS_PATH}}`).
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`.
3. Read `{{TOOLKIT_ROOT}}/AGENTS.md` § Git and language when mutating git or writing code.

If the user has **not** said **sim** to the current action, do **NOT** execute mutating git or file writes.

---

## 1. Git (blocked by default)

**Never** run automatically:

- `git commit`, `git push`, `git merge`, `git rebase`
- `git checkout -b` or other branch-creating commands

**Allowed without confirmation:** read-only - `git status`, `git diff`, `git log`.

Mutating git commands require explicit **sim** in the user's **immediately previous** message, or the user runs them manually.

Use `/commit` / `/push` after confirmation.

**Commit messages:** never include `Co-authored-by: Cursor`, Antigravity, or any AI agent - not in the message file, not via `--trailer`. If the IDE injects a co-author trailer after commit, amend it away per `/commit` §5.1 and `conventional-commits.mdc`.

---

## 2. Write / delete (confirm before write)

Before creating or replacing **new** SDD artifacts (PRD, PLAN):

1. Show title, path, summary bullets.
2. Ask **(pt-BR):** `Posso gravar em '{path}'? (sim / ajustar / cancelar)`
3. Write only after **sim**.

**Exception:** updating an existing PLAN after an **already approved** develop step - no re-confirmation.

Before editing production code or tests: confirm scope unless the user explicitly approved the current step/task.

---

## 3. One step per session (SDD develop)

- `sdd-develop`: exactly **one** PLAN step per session.
- `document-implement`: exactly **one** documentation plan step per session.

After completing the step: **STOP**. Do not start step N+1 in the same conversation.

---

## 4. Tests before marking done

Before marking a develop step or task complete:

- Run project tests (`dotnet test`, `npm test`, `pytest`, or per project constitution).
- Do not mark complete if tests fail and cannot be fixed in scope.

---

## 5. Language

| Context | Language |
|---------|----------|
| Chat replies to user | **pt-BR** |
| `SKILL.md`, guidelines, rules | **English** |
| PRD, PLAN (default) | **pt-BR** |
| Production code, tests, identifiers | **English** |

If the user corrects language, fix the **artifact/code** - do not flip chat to English unless asked.

---

## 6. Context management

See `{{TOOLKIT_ROOT}}/rules/context-management.mdc`. At ≥40% context: pause and recommend new session.

---

## 7. Session gates

See `SESSION.md`. Before Write/Shell, verify:

- `storage_confirmed` - for manifest/storage path changes
- `write_confirmed` - for new artifacts
- `step_confirmed` - before implement
- `tests_run` - before marking step done

Set gates to `true` only after user **sim**.

---

## Never compress (Caveman Mode)

Confirmation gates, artifact drafts, and git-block notices are **never** subject to Caveman compression.
Skills `commit` / `push` ignore `caveman_mode` (clear prose). Auto-Clarity drops compression for security and irreversible confirms.
Contract: `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`. Optional narrative compact: `COMPACT.md` (requires user **sim**). Always-on rule: `caveman-mode.mdc`.
