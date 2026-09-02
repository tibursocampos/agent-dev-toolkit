# Story splitting

When to **split** vs **merge** backlog items so each remains one verifiable outcome. Complements `story-sizing.md` heuristics; does not replace them.

External ideas (paraphrase only): vertical-slice splits, dependency-ordered waves — curated link in `docs/CREDITS.md`; not file-per-story checklists.

---

## Prefer split when

| Signal | Example |
|--------|---------|
| Independent consumers / deployables | App A vs App B package consumption |
| Different blast radius / rollback | Feed publish vs app migration |
| Hard dependency order | Package on feed **before** consumer reference |
| Refine overload | Single story needs **>~5–8** refine steps |
| Unrelated outcomes mixed | Auth + unrelated reporting in one US |

Cap for Product Initiative maturity: **≤4 US/TS** unless FEATURE rationale explicitly justifies more (`anti-task-shatter.md` / RN03).

---

## Prefer merge when

| Signal | Example |
|--------|---------|
| Same bounded context + same consumer | Multiple files of one vertical slice |
| Layer-only candidates | Domain-only + API-only that only make sense together |
| Task shards of one outcome | "Add DTO" + "Add validator" for the same command |

---

## Split output altitude

| After split | Must be |
|-------------|---------|
| New US/TS | Outcome title + Valuable / technical outcome (`invest-and-story-quality.md`) |
| Remaining work inside one story | Refine / PLAN **steps** (SMART tasks) — see `split-story-checklist` skill |

`split-story-checklist` emits **tasks**, not a new US per file (`anti-task-shatter.md`).

---

## Recording rationale

FEATURE story table must state **why N** (not N−1 or N+1). Silent splits without rationale fail the sizing merge policy in `story-sizing.md`.

---

## Relationship

| Ref | Role |
|-----|------|
| `story-sizing.md` | Minimum unit + anti file/layer patterns |
| `feature-altitude.md` | Feature vs story vs step height |
| `anti-task-shatter.md` | Blocks promoting shards to US/TS |
