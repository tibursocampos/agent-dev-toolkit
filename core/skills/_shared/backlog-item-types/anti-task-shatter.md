# Anti-task-shatter

Hard rules that stop **task-shaped** or **layer-only** candidates from becoming US/TS. Bake into O1 promotion gates and `split-story-checklist` output policy.

Normative source for this toolkit: feature ANALYSIS anti-task-shatter list (US03). External PM checklists may inspire wording — **paraphrase + link only**; do not vendor third-party bodies. Do **not** add a Core `/write-spec` skill for this (ARCH non-goal / RNF-004).

---

## Rules (must enforce)

1. **Title = verb + file/class/script/path** → do **not** create US/TS. Keep as PLAN/refine step.
2. **Layer-only** title (e.g. "Domain types", "Infrastructure") → **merge** into a vertical / outcome story.
3. **Maturity cap** → Product Initiative backlog ≤ **4** US/TS unless FEATURE rationale explicitly justifies extra split (RN03).
4. **`split-story-checklist` output** → SMART **tasks**, never one US per file.
5. **Valuable** → US must name beneficiary + observable progress; pure TS may use `n/a` for Product intent (RN04).

---

## Detection heuristics (promotion gate)

| Pattern | Example (reject as US/TS) | Keep as |
|---------|---------------------------|---------|
| Imperative + artifact | "Create `ExportController.cs`" | Refine / PLAN step |
| Imperative + script | "Add `validate-foo.ps1`" | Refine / PLAN step |
| Class/type only | "`OrderValidator`" | Step under an outcome story |
| Folder/layer only | "Update Application layer" | Merge into vertical slice |
| Outcome-shaped | "Operators export archives by date range" | Eligible US/TS |

TE02 intent (PRD): message like “Not promoted to US/TS (anti-task-shatter): …”.

---

## Relationship to sizing

`story-sizing.md` already bans one-file / one-layer / file-named steps. This file is the **promotion** contract: even if sizing heuristics are skipped, the gate must still reject task-shaped titles.

---

## Relationship

| Ref / skill | Role |
|-------------|------|
| `invest-and-story-quality.md` | Valuable bar after promotion |
| `splitting.md` | Cap and merge/split policy |
| `feature-altitude.md` | Correct height for rejected items |
| `orchestrate-analyze` | **Wired:** promotion + FEATURE depth + cap gates in `references/story-synthesis.md` (lazy-load this file at synthesis) |
| `split-story-checklist` | **Wired:** output = SMART tasks; must not emit US-per-file (lazy-load this file before Write) |
| `refine-story` | Scorecard Product depth; outcome-shaped titles (lazy-load at scorecard) |
