## Approval gates

### Mode selection

Question contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`. Render the question and option labels in the user's conversation language (`LANGUAGE.md`); the ids below are fixed.

```text
Question: execution mode for O2 in `{feature-path}` ({N} stories).
Options (ids):
- series: one story at a time (spec -> plan -> approval)
- parallel: one Agent per story; the child drafts PRD/PLAN only; the parent writes after confirm; aggregation and approval happen in the parent
- cancel: stop
```

### PRD/PLAN approval

Question contract: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`. Render in the user's conversation language (`LANGUAGE.md`); ids are fixed.

```text
Report: PRD/PLAN for O2 are ready for approval.
Scope: (per-story | batch, the whole set)
Question: may the parent mark these as approved?
Options (ids): confirm | adjust | cancel
```

Domain ids for this file: mode `series`, `parallel`; scope `per-story`, `batch`.

| Scope | When |
|-------|------|
| **Per story** (`per-story`) | User wants tight control; default in `series` mode after each story |
| **Batch** (`batch`) | N > 1 and user chose `batch` after `parallel` (or after all `series` drafts). One **confirm** authorizes **only** paths listed in the approval table; clear/reset `write_confirmed` after the batch (do not reuse stale gate for unlisted paths) |

Parallel Agent cap: **≤4** concurrent story drafts per `SPAWN.md`; wave or prefer `series` when N>4. If `subagents=none` or Agent unavailable → **fallback** to `series` **in-parent** (never hard-fail).

Silence, an ambiguous or unrelated reply, or a lone emoji is not approval; a clear affirmative reply in any language is. Map the reply per `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md` (Answer to id mapping).

**confirm** does not close an open question and does not replace stop code `open_question`. Render these prompts in the user chat language (`LANGUAGE.md`).

In `series` mode, once this story's named approval scope is satisfied and its checkpoint is reconciled, continue to the next eligible story without a separate “continue?” prompt. This does not pre-approve that story: present and honor its own required write and content-approval gates when due. If the current answer is pending, `adjust`, or `cancel`, do not advance dependent work; follow the table above. Batch approval authorizes only the paths explicitly listed in its approval table.

### Observable question and answer lifecycle

The states for every blocking operator question (`presented`, `pending`, `answered`, `resumed`), the order rule, and the answer-to-id mapping are defined once in `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`. Per-surface evidence and retry/redelivery limits are recorded in `adapters/README.md`.

---

## Process — Approval answers

After drafts exist (or after each story in `series`), present summary table (id, PRD path, PLAN path, 3 bullets). Ask in the user chat language — copy in § Approval gates; answer mapping per `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`.

The per-story approval table is governed by `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md` (O2 caller section): columns `gate`, `status`, `owner`, `evidence`, one row per story with the story ID in the gate cell, state keys and ASCII glyphs from that file, labels in the user chat language. You must redraw the full table at each gate and again after each answer (answer ids `confirm` / `adjust` / `cancel`); always show every story row, never a summary or only the changed row.

Offer `per-story` vs `batch` when N > 1.

| Answer | Action |
|--------|--------|
| **confirm** (`per-story`) | Set `write_confirmed` as needed per artifact write; write that story's PRD/PLAN; clear `write_confirmed` after; mark story deliver status; continue |
| **confirm** (`batch`) | **One** `batch` confirm authorizes Write for **only** the PRD/PLAN paths listed in the approval table. Parent writes that set (`series` within parent); set/clear `write_confirmed` around the batch (or per artifact if contracts require). Do **not** reuse a stale `write_confirmed=true` from an earlier story for unlisted paths |
| **adjust** | Revise named story via sdd-spec/sdd-plan contract; re-ask |
| **cancel** | Leave drafts; do not emit O3 / develop handoff as approved |
| *(silence)* | **not** approval - wait |
