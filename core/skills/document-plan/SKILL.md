---
name: document-plan
description: Create a baby-step documentation plan (overview + domain deep dives for RAG). Asks doc language before writing. Use when planning repo docs or invoking /document-plan.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: document-plan

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user asks for: `/document-plan`, `plan repo documentation`, `/document-plan`, or `doc plan`.

Optional argument: path to an existing **reviewed** `docs/overview.md` (or equivalent) to seed the plan.

## Outcome

In the **target workspace** (including this toolkit repo when it is the repository to document):

- `docs/documentation-plan/plan.md` - baby-step documentation plan with progress tracking
- `docs/overview.md` - high-level repo summary (created or refreshed unless user provided overview)

Product documentation prose follows the **language the user chooses** (pt-BR or English). File paths stay in English.

## Lazy-load

| When | Path |
|------|------|
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/document-plan/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/document-plan/references/<section>.md` |
| SDD vs RAG plan boundary | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md` (read section Read-only discovery - do not conflate paths) |
| Language surfaces (chat vs spawn) | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |

**Never by default:** do not preload full `reference.md` when `references/` exists; load one section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Stack detection | `references/stack-detection.md` |
| Output paths | `references/output-paths.md` |
| Plan template | `references/plan-template.md` |
| Execution update / SDD boundary | `references/execution-update.md` |
| Planning checklist | `references/planning-checklist.md` |
## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Workspace and stack

1. Confirm **target repository** (consumer app/service - not the toolkit unless explicit).
2. Detect stack with Glob (see `references/stack-detection.md`). Summarize: languages, frameworks, layout - **do not** assume a fixed corporate stack.
3. Read `AGENTS.md` / `README.md` if present.

**Not SDD:** this skill writes `docs/documentation-plan/plan.md` only - not `PLAN/PLAN_*.md` or `{{SDD_ROOT}}/<repo-id>/PLAN/`. Feature PRD/PLAN use `sdd-spec` / `sdd-plan` / `sdd-develop` per `STORAGE.md`.

### 1. Documentation language (blocker)

Before creating or updating any file under `docs/` in the target repo, ask once:

> Documentation language for product `docs/` - **pt-BR** or **English**?

Record the choice in the session and in `docs/documentation-plan/plan.md` header (see template).

### 1b. Documentation-plan ignore and tracking gate

Before writing or updating `docs/documentation-plan/plan.md`:

1. Resolve the target Git repository root and check whether `docs/documentation-plan/plan.md` is already tracked (`git -C <repo-root> ls-files --error-unmatch -- docs/documentation-plan/plan.md`).
2. If it is tracked, stop before writing and ask for explicit **sim** to remove only this path from the index with `git rm --cached -- docs/documentation-plan/plan.md`. Do not run that command without the confirmation; explain that it stages the removal while preserving the working copy. After confirmation, verify the path is no longer tracked.
3. Ensure the target repository's root `.gitignore` contains a rule that ignores `/docs/documentation-plan/plan.md`. If absent, append that narrow rule automatically before writing the plan; do not add a rule that ignores `docs/overview.md` or other product documentation.
4. Verify the path is ignored by the repository rule (`git -C <repo-root> check-ignore --no-index --quiet -- docs/documentation-plan/plan.md`). A global excludes file alone does not satisfy this requirement.
5. After writing/updating the plan, verify it remains untracked with `git ls-files`. Never stage plan contents or commit the plan. The only permitted index mutation is an explicitly confirmed `git rm --cached` to untrack a previously tracked path. If verification fails, stop and report the exact path.

This applies in every target repository, including the toolkit repository when explicitly selected. The plan is local workflow state; `docs/overview.md` and other product documentation remain versionable.

### 2. Existing artifacts

| Path | Action |
|------|--------|
| `docs/documentation-plan/plan.md` | After the ignore/tracking gate: if it exists, read completed steps and resume or ask to overwrite |
| `docs/overview.md` | Use user-provided path, existing file, or generate from exploration |
| Neither | Create both per `references/output-paths.md` + `references/plan-template.md` |

### 3. Explore and draft overview

Glob/Grep/Read: solution layout, main entry points, bounded contexts, external integrations, test layout. Write or update `docs/overview.md` in the chosen language - concise, RAG-friendly, no invented business domain names.

### 4. Write documentation plan

Create or update `docs/documentation-plan/plan.md` using `references/plan-template.md` (checklist: `references/planning-checklist.md`):

**Sizing (required):**

| Kind | How to plan |
|------|-------------|
| **New** domain/overview/integration doc (file does not exist yet) | **One plan step per new deliverable file** (e.g. one step → `docs/domains/billing.md`) |
| **Update** existing docs after a feature/change | Prefer **one single update step** covering all touched existing paths (not one baby-step per file) |
| Large greenfield pack or large doc refactor | Keep coherent steps; `document-implement` may **spawn** specialists for heavy steps (`SPAWN.md`) |

Do **not** default to 5–12 tiny baby steps. Prefer fewer, larger steps aligned with new files + one update bucket when refreshing.

- Progress `0/N`, status per step (**Pending** / **Completed**)
- Mark **Kind:** `new` \| `update` \| `refactor` on each step when useful for implement routing
- Each **new**-doc step sized for one `document-implement` session; **update** steps may list multiple existing paths in one session

### 5. Context checkpoint

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 6. Summarize handoff

Finish with a usable handoff, not only a summary that the plan was created.

- Always report the canonical plan path, document language, and progress (`completed/total` steps).
- If any step is pending, identify the first pending STEP id and title, give its concise scope and acceptance summary, and provide the exact next command `/document-implement`.
- If all steps are complete, explicitly state that there is no next step.
- Do not end with a generic plan-created summary without the applicable handoff above.

```
/document-implement
```

## Must not

- Embed MES or organization-specific product context
- Require external wiki APIs, or fixed .NET/Angular versions without detection
- Stage plan contents or commit `docs/documentation-plan/plan.md`; it must be ignored by the target repository's root `.gitignore` and remain untracked
- Write `docs/` before the language question is answered
- Default product doc language without asking

## Handoff

| Situation | Next |
|-----------|------|
| Execute next doc step | `/document-implement` |
| Code change needed | `/developer` or SDD `sdd-develop` |
| Commit docs | `/commit` |
