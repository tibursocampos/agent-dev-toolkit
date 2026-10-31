## Mode comparison (RF03)

| | **`series`** | **`parallel`** |
|--|-----------|--------------|
| Who drafts / writes | Parent runs contracts end-to-end (Write after **confirm**) | Agent children **draft only** when `subagents=native` (no disk Write); parent Writes after **confirm**. Else **fallback** to `series` **in-parent** (`SPAWN.md`) |
| Order | Spec -> plan -> (optional approve) -> next | Children concurrent; parent aggregates drafts then writes |
| Deps | Natural - finish dependency stories first | Block spawn until deps have PRD+PLAN (or user waives **story order** only — not missing SEC/ARCH/ANALYSIS) |
| Context (RNF01) | Higher in parent | Parent lean (paths + draft summaries) |
| Confirm-before-write | Inline in parent | Always parent gate after aggregation |
| Best when | Few stories; tight review | Many independent stories; brownfield batch |

Document choice under CONTINUITY **Decisões**.

---

## Process — Choose mode (RF03)

Ask in the user chat language - never assume. Only after the required-siblings STOP has passed — copy in `references/approval-gates.md` § Approval gates (mode selection). Question contract and answer ids: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`.

| Choice (id) | Behavior |
|--------|----------|
| **`series`** | Parent runs contracts sequentially; lower context risk |
| **`parallel`** | Prefer Agent when `subagents=native` (`SPAWN.md`): one Agent per story for **drafts only**. A plan draft waits until contestation accepted the PRD and, when required, `REFINE/tasks.md` exists. Parent aggregates, asks for **confirm**, then **parent** writes via `sdd-spec` / `sdd-plan`. The parent runs `split-story-checklist` between them for medium/complex. Concurrent Agent cap **≤4** per `SPAWN.md`; if N>4, wave ≤4 or prefer `series`. If `subagents=none` or Agent unavailable → **fallback** to `series` **in-parent** (same contracts; never hard-fail) |
| **`cancel`** | Stop; no writes |

Document the choice in `CONTINUITY.md` (decisões). Before any `parallel` Agent wave: load `SPAWN.md` and consult capability `subagents`.

**Model (`SUBAGENT-MODEL.md`):** omit Agent `model` by default — child uses the **same model as the parent session**. Do **not** conflate with a host auto model or Memory Bank policy `auto`. Premium slug only after the rare hard-task gate + user **confirm**; **decline** / silence → omit `model`.

See also § Mode comparison (RF03).
