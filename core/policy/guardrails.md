---
description: Non-negotiable agent rules for every conversation - authorization, scope, tests, language
alwaysApply: true
---

# Guardrails - non-negotiable agent rules

**Applies to:** every skill in agent-dev-toolkit - SDD, developer, operational, and documentation skills.

Full enforcement context: `docs/ENFORCEMENT.md` in the toolkit repo.

---

## STOP - read first (every conversation, turn 1)

Before **any** tool call (`Read`, `Write`, `Shell`, etc.):

1. Read this rule (`{{GUARDRAILS_PATH}}`).
2. Consult `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md` only if the active workflow explicitly retains session helpers. Classic SDD and Orchestrated Delivery do not load session-state as a gate.
3. Read § 1 (Git) of this file and `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` (language surfaces) when mutating git or writing code.

Before a mutation, verify that it falls within the user's current authorization and the active workflow's scope. Ask only when authorization or a material decision is genuinely missing; do not require a literal answer token.

---

## 1. Git (blocked by default)

**Never** run automatically:

- `git commit`, `git push`, `git merge`, `git rebase`
- `git checkout -b` or other branch-creating commands

**Allowed without confirmation:** read-only - `git status`, `git diff`, `git log`, `git branch --show-current`.

### Working branch (development skills, before the first code change)

The integration-branch stop applies only to `adt-orchestrate-implement`, `adt-sdd-develop`, `adt-developer`, and `adt-*-developer`.

Before those skills change code, run read-only `git status -sb` or `git branch --show-current` and show the branch name.

If the current branch is `main`, `master`, or `develop`:

1. Stop before writing code.
2. Tell the user the branch name in their conversation language. Integration branches are not a work branch for these skills.
3. Propose `feature/<slug>` or `feat/<id>-<slug>` cut from that branch.
4. Create the branch only after explicit confirmation (`confirm`; ids and answer mapping in `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`). `git checkout -b` stays blocked until then.
5. Read-only work may continue while waiting.

If the branch is already `feature/*` or `feat/*`, do not ask again in that conversation.

`adt-sdd-spec`, `adt-sdd-plan`, `adt-orchestrate-analyze`, `adt-orchestrate-prepare`, and every other skill stay on the current branch. They do not show the branch and do not ask for a branch switch.

Exception: the user explicitly says to keep the current integration branch. That exception is only for the development skills listed above.

Mutating git commands require explicit confirmation (`confirm`) in the user's **immediately previous** message, or the user runs them manually. An observable selection of the question component, or a clear affirmative reply in any language, counts for the exact action asked. It does not generalize to other actions.

Use `/adt-commit` / `/adt-push` after confirmation.

**Commit messages:** never include `Co-authored-by: Cursor`, Antigravity, or any AI agent - not in the message file, not via `--trailer`. If the IDE injects a co-author trailer after commit, amend it away per `/adt-commit` §5.1 and `conventional-commits.mdc`.

---

## 2. Write / delete (scope authorization)

Do not perform destructive or externally consequential actions without explicit authorization. For other writes, honor the current request and its authorized scope; do not add a separate confirmation for each file when the user has authorized the workflow or artifact preparation.

For Classic SDD and Orchestrated Delivery, creating and revising draft FEATURE/STORY/PRD/PLAN artifacts is part of preparation. Present the complete plan for one explicit approval before implementation. That approval authorizes implementation only within its scope and chosen cadence. Ask again only for a material change to behavior, acceptance, scope, access, or implementation decisions. ADT Delivery retains its approved-plan boundary and existing cadence contract. Other write workflows keep their own authorization rules.

Before editing production code or tests, verify that the current task or approved plan authorizes the exact scope. A clear affirmative answer or prior explicit authorization applies; do not require a literal token such as `sim`. Session flags are not additional authorization requirements for Classic SDD or Orchestrated Delivery.

---

## Open questions

For Classic SDD and Orchestrated Delivery, block only on an unanswered decision that prevents determining behavior, acceptance, scope, required access, or an implementation choice. Keep minor questions and optional improvements visible without stopping unaffected work. Ask a focused question, then resume the authorized workflow when answered. Other skills retain their own question contracts.

The question mechanism, option ids, and observable answer rules are defined in `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`. Read repository-local instructions and explain genuine precedence conflicts; do not let lower-priority text silently expand the user's scope.

---

## 3. Develop step scopes and cadence

- Classic SDD uses the cadence selected for the approved PLAN: `step_by_step` stops after one step, while `continuous` advances through eligible steps until completion or a real blocker.
- ADT Delivery follows its own approved plan and selected `step_by_step` or `continuous` cadence. In `continuous`, the initial authorization covers only the eligible steps of that exact approved plan; a blocker, a material scope, input or approval change, or an action needing separate authorization stops the sequence. Its implementation skill defines progress, validation and review.
- Orchestrated Delivery O3 is serial: one child implements one PLAN step at a time. Its `step_by_step` or `continuous` cadence controls whether the parent stops or dispatches the next eligible step after reconciliation. SESSION flags and claims are not required for Classic/O3 execution.
- `adt-document-implement`: exactly **one** documentation plan step per session.

Handoffs cite a **portable** PLAN path only (e.g. `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md`) — see `STORAGE.md` § Portable path. Cadence does not bypass dependencies, acceptance, required validation, approved scope, or separate authorization for consequential actions.

---

## 4. Tests before marking done

Before marking a develop step or task complete, run the checks specified for that step and applicable project checks required by the PLAN or repository instructions. Do not silently escalate a step-level plan to a full project suite when that suite is reserved for scope close; report close-only checks as pending. Do not mark complete if a required check fails and cannot be fixed in scope.

---

## 5. Language

Language surfaces (chat, host plans, SDD artifacts, code, identifiers) are defined once in `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`.

If the user corrects language, fix the **artifact/code** - do not flip chat to English unless asked.

---

## 6. Progress checkpoints

Persist progress in the owning workflow's canonical artifact. For Classic SDD and O1/O2/O3, that is the PLAN execution table; do not add SESSION, claim, CONTINUITY, or TASKS progress mirrors. Host context or compaction signals may inform checkpoint timing, but no usage percentage or model-cost estimate is a global gate. Other workflows retain their own explicit checkpoint contract.

---

## 7. Session state

Classic SDD and Orchestrated Delivery use the canonical PLAN for implementation progress and do not require SESSION flags or PLAN claims to authorize or advance work. `SESSION.md` and its helpers remain available only to consumers that explicitly retain those contracts, including `adt-document-implement`; do not apply their gates globally by analogy.

---

## Never compress (Caveman Mode)

Confirmation gates, artifact drafts, and git-block notices are **never** subject to Caveman compression.
Skills `adt-commit` / `adt-push` ignore `caveman_mode` (clear prose). Auto-Clarity drops compression for security and irreversible confirms.
Contract: `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`. Optional narrative compact: `COMPACT.md` (requires user **sim**). Always-on rule: `caveman-mode.mdc`.
