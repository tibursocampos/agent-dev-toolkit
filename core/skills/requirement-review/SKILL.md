---
name: requirement-review
description: Challenge a feature or story before SDD in one of two modes. Mode --feature checks functional gaps and acceptance criteria; mode --tech grounds contracts and flows in the repository. Use when reviewing requirements or invoking requirement-review.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

Writes (review report, Q&A history) are new artifacts: show the target path and summary, then wait for `sim` before any Write (`guardrails.md` section 2). Never write code.

---

# Skill: requirement-review

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user asks for: `/requirement-review`, `requirement-review --feature`, `requirement-review --tech`, "challenge this requirement", "review the acceptance criteria", or "check this story against the repository".

Not a trigger: a request to write a PRD (`sdd-spec`), to break steps into a checklist (`split-story-checklist`), or to change code (`developer`, `*-developer`).

**Mode (mandatory, exactly one per run - no silent default):**

| Mode | Explicit invoke examples | Playbook |
|------|--------------------------|----------|
| **--feature** | `--feature`, `feature`, `1` | `references/feature.md` |
| **--tech** | `--tech`, `tech`, `2` | `references/tech.md` |

If the invocation names neither mode, or both: **STOP** after gate check (-1) and ask once, in the **user chat language**, then wait. Load **no** playbook until the mode is set. Do not assume a mode.

When `invocation_context=orchestrated` (a parent such as `refine-story` passes the mode), do not ask. A missing mode is `blocked`: return to the parent.

```text
requirement-review mode?
1) --feature - functional review of the story or feature
2) --tech - repository-grounded technical review
```

Render the two options in the user chat language. Keep the mode ids `--feature` and `--tech` in English.

## Outcome

One review report per run, with:

- Status token `READY` or `NEEDS_CLARIFICATION` (`_shared/sdd-artifacts/readiness-severity.md`).
- Open questions with severity, decision owner, and one answerable question each.
- Findings with stable ids (`refine-story/references/finding-format.md`).
- Atomized acceptance criteria (feature mode) or grounding and follow-ups (tech mode).
- Q&A entries appended to the Q&A history.

Flow outcome per `_shared/skills-catalog/CATALOG.md` (Flow terminal contract): `done` when READY and the handoff is named; `open_question` while any question waits for an answer; `blocked` when the source or the repository is missing.

## Flow contract: reads, writes, where, when

- **Reads:** `STORY.md` or `FEATURE.md`, `REFINE/qa-history.md` when present, or pasted text.
- **Writes:** after `sim` only: `REFINE/requirement-review-feature.md` (or `-tech.md`) and `REFINE/qa-history.md`. Pasted source: chat only.
- **Where:** `features/NNN-slug/USnn/REFINE/`; without a story folder, `docs/backlog/<slug>-requirement-review-<mode>.md`.
- **When to use:** challenge a feature or story before SDD, with `--feature` (acceptance criteria) or `--tech` (repository contracts).

Full flow: [backlog refinement guide](../../../docs/guides/backlog-refine.md).

## Lazy-load

| When | Path |
|------|------|
| Index (routing only) | `{{TOOLKIT_ROOT}}/skills/requirement-review/reference.md` |
| Mode playbook **feature** (only when mode = --feature) | `{{TOOLKIT_ROOT}}/skills/requirement-review/references/feature.md` |
| Mode playbook **tech** (only when mode = --tech) | `{{TOOLKIT_ROOT}}/skills/requirement-review/references/tech.md` |
| API contract standards (tech mode, only when an API contract is affected) | `{{TOOLKIT_ROOT}}/skills/api-standards/SKILL.md`, then one matching file under its `references/` |
| Severity B / I / MINOR + READY gate | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/readiness-severity.md` |
| Clarify depth | `{{TOOLKIT_ROOT}}/skills/_shared/backlog-item-types/clarify-depth.md` |
| Finding types and block shape | `{{TOOLKIT_ROOT}}/skills/refine-story/references/finding-format.md` |
| Q&A history shape and flow rules | `{{TOOLKIT_ROOT}}/skills/refine-story/references/qa-history.md` |
| Storage paths and portable paths | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` |
| Invocation contexts (`direct` vs `orchestrated`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` |
| Selective retrieval (`SR-NO-FULL-DUMP`) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |

**Never by default:** do not preload `references/feature.md` and `references/tech.md` together; load only the selected mode. Do not load `api-standards` unless the tech playbook finds an affected API contract. Do not dump `memory-bank/`, a full PRD, or whole source files (`SR-NO-FULL-DUMP`).

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply the **Lite** cap and prefs `caveman_level`; show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity and never-compress gates, drafts, and paths per `CAVEMAN.md`.

### 0. Workspace and invocation context
Confirm the target repository only for `--tech`. Resolve `invocation_context` per `INVOCATION-CONTEXTS.md`: `direct` unless the parent handoff marks `orchestrated`.

### 0.5 Mode
Resolve `--feature` or `--tech` from the invocation or from the answer to the mode prompt. Then read **only** that playbook.

### 1. Locate source and prior history
- **Source** (one of): `features/NNN-slug/USnn/STORY.md` (or `TSnn`), `features/NNN-slug/FEATURE.md`, `REFINE/refine.md` beside the story, or pasted text. Pasted text has no file: keep the report in chat until the operator confirms a write path.
- **Prior history first:** read `features/NNN-slug/USnn/REFINE/qa-history.md` (or the shortcut `docs/backlog/<slug>-qa-history.md`) before asking anything. Do not re-ask a question whose entry is `resolved` or `superseded`.
- **Never erase a decision.** A changed decision is a new entry linked through `Supersedes` / `Superseded by`, with the reason recorded in its Resolution field.

### 2. Run the mode playbook
Follow `references/feature.md` or `references/tech.md`. It produces findings, candidate questions, and mode-specific sections. Shared rules below apply to both modes.

### 3. Classify open questions
- Severity **B**, **I**, or **MINOR** per `readiness-severity.md`. Depth per `clarify-depth.md`.
- Decision owner: **Product** (value, scope, business rules, priority), **Engineering** (feasibility, contracts, data model, performance targets), or **UX** (flows, visible states, copy).
- Each question has **one** answerable question. Prefer a closed choice ("yes / no / other") when the decision space is known.
- A product decision is never solved by assumption. Do not write a default into a criterion. Ask.
- Ask every open question in one batch at the end, including MINOR. Silence does not close a question. "I do not know" leaves it open.

Question entry (chat and report):

```text
Q-003 [I] owner: Product
Question: <one answerable question>
Impact: <portable path>#<section>; CA-002.a
```

### 4. Atomize acceptance criteria
Applies to every criterion the source carries.

- Keep the parent id (`CA-002`). When one criterion carries several independently observable outcomes, derive atoms `CA-002.a`, `CA-002.b`, and so on.
- Never renumber an existing id. A new atom takes the next free suffix under its parent.
- Each atom has Given / When / Then with an observable Then. Include the boundary atom (empty, minimum, maximum, duplicate, where the domain has them) and the failure atom (what the user sees and what is persisted).
- An atom must be checkable by someone who did not write it. Reject "works correctly", "as expected", "properly", and "funciona corretamente" as Then.

### 5. Report and Q&A
Output shape (report body; prose follows the user chat language, tokens stay English):

```markdown
# Requirement review - <title>

| Field | Value |
|-------|-------|
| **Mode** | --feature \| --tech |
| **Invocation context** | direct \| orchestrated |
| **Source** | <portable path or "(pasted text)"> |
| **Updated** | YYYY-MM-DD |

Status: READY | NEEDS_CLARIFICATION

## Open questions

| ID | Severity | Owner | Question |
|----|----------|-------|----------|
| Q-003 | I | Product | <one answerable question> |

(Open items only. Resolved and superseded items live in the Q&A history.)

At every `open_question` stop and at close, you must show this full table in chat with every open question row (ID, Severity, Owner, Question), localized per `_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`. Never show only the changed row or summarize rows. A question the operator has resolved leaves the table and stays only in the Q&A history.

## Findings

[FND-001 | I | GAP] <section heading>
Evidence: <portable path> | no-evidence
<what is ambiguous, missing, contradictory, risky, or dependent>
Recommendation: <recommendation, not a decision>

## <mode section>
<feature: atomized criteria table; tech: grounding and follow-ups, see the playbook>

## Next
<handoff line from step 6>
```

- Finding ids, types, and block shape: `refine-story/references/finding-format.md`. Do not invent a second severity vocabulary.
- Q&A entries: append new questions with `Status: open` **before** waiting for answers, using the `qa-history.md` shape. Set `Origin` to `requirement-review --feature` or `--tech`. Keep question ids stable; allocate the next free `Q-` and `D-` ids.
- Persistence (after `sim`): `features/NNN-slug/USnn/REFINE/requirement-review-feature.md` or `requirement-review-tech.md`, with the Q&A history at `REFINE/qa-history.md`. Shortcut when no story folder exists: `docs/backlog/<slug>-requirement-review-<mode>.md` with `docs/backlog/<slug>-qa-history.md`. Source is a FEATURE.md with no story folder: report in chat and persist only to a story folder the operator names, or the shortcut. Do not invent a feature-root `REFINE/` folder.
- Portable paths only in the file, the handoff, and the history. No OS absolute paths.

### 6. Status and handoff
Status follows `readiness-severity.md`: `READY` only with no unanswered B, I, or MINOR question. Recompute it on every refresh.

| Status | Handoff |
|--------|---------|
| `READY`, mode `--feature`, no repository involved | `sdd-spec - <portable-story-path>` |
| `READY`, mode `--feature`, story touches a repository | `requirement-review --tech - <portable-story-path>` next, then `sdd-spec` |
| `READY`, mode `--tech` | `sdd-spec - <portable-story-path>`, with the listed technical follow-ups |
| `NEEDS_CLARIFICATION` | Answer every open question, cite the Q&A history path, re-run the same mode. Do not claim the item is ready for `sdd-spec` |

Technical follow-ups are not questions. They never block READY; they travel to `sdd-spec` as a list.

## Must not

- Decide a product question by assumption, or write a default into an acceptance criterion
- Claim READY while any unanswered B, I, or MINOR question remains
- Write code, edit application files, or write a PRD or PLAN
- Assert a repository fact without a search hit (`--tech`); record `not-found` instead of guessing
- Copy the `api-standards` rules into the report; cite the reference file
- Load both mode playbooks, or load the api-standards pack without an affected API contract
- Erase or rewrite a prior answer, resolution, or impact; supersede it with a linked entry
- Put more than one question in one entry
- Call an external tracker, work-item API, or MCP work-item tool
- Write OS absolute paths or InstallRoot embeds into the report, history, or handoff
- Describe the design by reference to any external product, repository, or skill; state behavior in toolkit terms

## Handoff examples

```
requirement-review --feature - features/004-export/US01/STORY.md
requirement-review --tech - features/004-export/TS02/STORY.md
```

```
/sdd-spec - features/004-export/US01/STORY.md
```

Cite `REFINE/qa-history.md` in the typed handoff when present. Do not paste the history into the slash line.
