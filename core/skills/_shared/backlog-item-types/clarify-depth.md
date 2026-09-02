# Clarify depth

How deep **open questions** and challenge prompts must go before FEATURE/STORY/PRD are “ready enough” for the next gate. Complements refine challenge-vagueness without requiring a separate `/write-spec` Core skill (RNF-004).

External ideas (paraphrase only): structured clarification (metrics, prioritization, severity) — curated links in `docs/CREDITS.md` (Product backlog quality); do not paste corpora here.

---

## Depth targets by artifact

| Artifact | Minimum clarify depth |
|----------|------------------------|
| **FEATURE** | Problem, Goals, Non-goals clear; open questions named if blockers remain |
| **US/STORY** | Objective unambiguous; AC budget slots identifiable (`gherkin-budget.md`); OOS explicit when known |
| **PRD** | Metrics and MoSCoW discussable; open questions carry **severity** when listed |

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

---

## Relationship

| Ref / skill | Role |
|-------------|------|
| `feature-altitude.md` | Which questions belong on FEATURE vs story |
| `sdd-spec` / `refine-story` | Wire challenge prompts (later PLAN steps) |
| `invest-and-story-quality.md` | Negotiable / Estimable unlocked by clarify |
