# Clarify depth

How deep **open questions** and challenge prompts must go before FEATURE/STORY/PRD are “ready enough” for the next gate. Complements refine challenge-vagueness without requiring a separate `/write-spec` Core skill (RNF-004).

**Severity / READY SoT:** `_shared/sdd-artifacts/readiness-severity.md` (REQ-004 / REQ-005 / RN02) — canonical **B** \| **I** \| **MINOR**, tokens **READY** / **NEEDS_CLARIFICATION**, dual plane readiness ≠ implementation / `step_confirmed`.

External ideas (paraphrase only): structured clarification (metrics, prioritization, severity) — curated links in `docs/CREDITS.md` (Product backlog quality); do not paste corpora here.

---

## Depth targets by artifact

| Artifact | Minimum clarify depth |
|----------|------------------------|
| **FEATURE** | Problem, Goals, Non-goals clear; open questions named if blockers remain |
| **US/STORY** | Objective unambiguous; AC budget slots identifiable (`gherkin-budget.md`); OOS explicit when known |
| **PRD** | Metrics and MoSCoW discussable; open questions carry **severity** (**B** \| **I** \| **MINOR**) when listed |

---

## Severity + READY (REQ-004)

| Severity | Blocks READY? |
|----------|---------------|
| **B** | Yes |
| **I** | Yes |
| **MINOR** | No — may remain with a recorded assumption |

**READY** = no open **B** or **I**. Sibling folder **presence** (`ANALYSIS/` / `ARCH/` / `SEC/`) ≠ READY (**RN02**).

Legacy template cells `blocker \| high \| medium \| low` map per `readiness-severity.md` (blocker→B, high→I, medium|low→MINOR). Prefer writing **B** / **I** / **MINOR** on new rows.

When open **B**/**I** remain at an O2 or refine→PRD boundary: status **`NEEDS_CLARIFICATION`** — **STOP** Write; typed handoff with portable paths (`readiness-severity.md` / TE01). Do not treat SESSION `step_confirmed` as clarification READY (dual plane).

---

## Good vs shallow questions

| Good | Shallow |
|------|---------|
| "Which beneficiary measures success in week 1?" | "Any other requirements?" |
| "What fails if date range is empty?" | "Confirm AC" |
| "Is feed publish blocking App B, or parallel?" | "Dependencies?" (no options) |

---

## Rules

1. Prefer **few sharp questions** over long questionnaires.
2. Do not ask operators to invent Evidence (`product-evidence-lite.md`).
3. Challenge file/task-shaped titles toward outcomes (`anti-task-shatter.md`).
4. Caveman Mode: **never compress** product drafts or clarification gates (ARCH).
5. Every listed open question **must** carry severity (**B** \| **I** \| **MINOR**, or mapped legacy).

---

## Relationship

| Ref / skill | Role |
|-------------|------|
| `readiness-severity.md` | Canonical B/I/MINOR, READY / NEEDS_CLARIFICATION, dual plane, STOP shape |
| `feature-altitude.md` | Which questions belong on FEATURE vs story |
| `sdd-spec` / `refine-story` | Wire challenge prompts; refine STOP fake-forward when B/I open |
| `orchestrate-deliver` | O2 STOP Write on open B/I (`preconditions.md`) |
| `invest-and-story-quality.md` | Negotiable / Estimable unlocked by clarify |
