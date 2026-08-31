## Mode comparison (RF03)

| | **Série** | **Paralelo** |
|--|-----------|--------------|
| Who drafts / writes | Parent runs contracts end-to-end (Write after **sim**) | Task children **draft only** when `subagents=native` (no disk Write); parent Writes after **sim**. Else **fallback** série **in-parent** (`SPAWN.md`) |
| Order | Spec -> plan -> (optional approve) -> next | Children concurrent; parent aggregates drafts then writes |
| Deps | Natural - finish dependency stories first | Block spawn until deps have PRD+PLAN (or user waives **story order** only — not missing SEC/ARCH/ANALYSIS) |
| Context (RNF01) | Higher in parent | Parent lean (paths + draft summaries) |
| Confirm-before-write | Inline in parent | Always parent gate after aggregation |
| Best when | Few stories; tight review | Many independent stories; brownfield batch |

Document choice under CONTINUITY **Decisões**.

---

## Process — Choose mode (RF03)

Ask (pt-BR) - never assume. Only after the required-siblings STOP has passed — copy in `references/approval-gates.md` § Approval gates (mode selection).

| Choice | Behavior |
|--------|----------|
| **1 série** | Parent runs contracts sequentially; lower context risk |
| **2 paralelo** | Prefer Task when `subagents=native` (`SPAWN.md`): one Task per story for **drafts only**; parent aggregates, gates `sim`, then **parent** writes via `sdd-spec` / `sdd-plan`. Concurrent Task cap **≤4** per `SPAWN.md`; if N>4, wave ≤4 or prefer série. If `subagents=none` or Task unavailable → **fallback** to série **in-parent** (same contracts; never hard-fail) |
| **3** | Stop; no writes |

Document the choice in `CONTINUITY.md` (decisões). Before any paralelo Task wave: load `SPAWN.md` and consult capability `subagents`.

**Model (`SUBAGENT-MODEL.md`):** omit Task `model` by default. Premium slug only after the rare hard-task gate + user **sim**; **não** / silence → omit `model`.

See also § Mode comparison (RF03).
