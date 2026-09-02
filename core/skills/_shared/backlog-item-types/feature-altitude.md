# Feature altitude

What belongs on **FEATURE** vs **US/TS** vs **refine/PLAN step**. Prevents stuffing implementation into FEATURE and promoting steps into stories.

---

## Altitude table

| Artifact | Must contain | Must not contain |
|----------|--------------|------------------|
| **FEATURE** | Problem, Goals, Non-goals, Evidence (or honest omit), story table with Rationale + Product intent | File checklists, per-class tasks, full PRD dump |
| **US/TS** | One verifiable outcome; AC budget when behavioral | Verb+file titles; layer-only scope |
| **Refine / PLAN step** | SMART implementation action | New US/TS identity |

---

## Promotion / demotion

| From → To | When |
|-----------|------|
| Step → US/TS | Only if outcome-shaped **and** passes `anti-task-shatter.md` |
| US/TS → Step | Title/objective is task- or layer-shaped |
| Many US → fewer | Merge per `splitting.md` / `story-sizing.md` |
| FEATURE thin → deep | Fill Problem/Goals/Non-goals before human backlog gate |

---

## Cap and rationale

FEATURE table justifies story count. Cap ≤4 US/TS for Product Initiative maturity unless rationale is explicit (`anti-task-shatter.md` RN03).

---

## Relationship

| Ref | Role |
|-----|------|
| `ost-lite.md` | Outcome ↔ story ↔ task chain |
| `clarify-depth.md` | Depth of open questions at FEATURE/PRD altitude |
| Templates FEATURE/STORY | Field shapes |
| `orchestrate-analyze` story-synthesis | Cap + altitude enforced at O1 gates |
