# OST lite (outcome / story / task)

Lightweight altitude map: **Outcome → Story → Task**. Keeps backlog items at the right height without adopting a full third-party OST methodology dump.

External ideas (paraphrase only): outcome-driven roadmaps map measurable progress to stories and tasks — curated links in `docs/CREDITS.md` (Product backlog quality); do not vendor bodies here.

---

## Three altitudes

| Altitude | Answers | Lives in |
|----------|---------|----------|
| **Outcome** | What progress did the beneficiary achieve? | FEATURE Goals / Product intent; initiative metrics |
| **Story** | What shippable slice delivers part of that progress? | US/TS Objective + AC |
| **Task** | What concrete step implements the story? | Refine steps / PLAN steps / split-checklist |

---

## Mapping rules

1. Every US/TS must point up to an **outcome** (FEATURE Goals or Product intent; TS may use technical outcome + `n/a` product intent).
2. Every task must point up to **one** story — never invent a new US for a task shard (`anti-task-shatter.md`).
3. If a "story" only lists tasks with no outcome, **raise** altitude: rewrite Objective or demote items to steps.

---

## Anti-patterns

| Bad | Fix |
|-----|-----|
| Outcome = "Ship the API" with no beneficiary progress | Restate measurable/observable progress |
| Story = task list in the title | Demote to steps; write outcome title |
| Task promoted to US because "it is big" | Split only when `splitting.md` signals fire |

---

## Relationship

| Ref | Role |
|-----|------|
| `feature-altitude.md` | FEATURE vs story vs step |
| `persona-context.md` | Who/Job/Outcome language for US |
| `invest-and-story-quality.md` | Valuable at story altitude |
