## Challenge vagueness + product depth (before Write)

Reject or rewrite acceptance / REQ text that cannot be verified. Examples of **forbidden** phrasing: "works correctly", "as expected", "properly", "funciona corretamente", "como esperado", "de forma adequada".

Every CA must state an **observable** outcome (test, script exit code, checklist item, or measurable UI/API result). Every functional REQ maps to ≥1 CA.

### Product depth challenge (FEATURE / STORY / PRD)

Before drafting the PRD, challenge Prior context and operator answers for **depth**, not only wording. Lazy-load norms only at this step (do not preload):

| Artifact | Must challenge / require | Norm / template |
|----------|--------------------------|-----------------|
| FEATURE (sibling) | Problem, Goals, Non-goals, Evidence (omit > fabricate); story table Rationale + Product intent | `feature-altitude.md`, `product-evidence-lite.md`, `templates/features/FEATURE.md` |
| STORY (sibling) | Objective; Who/Job/Outcome when US; OOS; AC budget **happy + rule/edge + failure** with observable Then | `gherkin-budget.md`, `invest-and-story-quality.md`, `templates/features/story/STORY.md` |
| PRD (this Write) | Success **metrics** (§1.3); **MoSCoW** (§4.3); open questions with **Severity** (§5.1) when unknowns remain | `clarify-depth.md`, `templates/sdd/PRD.md` |

**What / not how:** depth challenges ask for observable outcomes, beneficiaries, and success signals — **never** implementation code, class design, or step-by-step how. Identifiers (types, APIs, paths) stay English when cited.

If FEATURE/STORY siblings are thin: ask ≤3 gap questions targeting the missing depth fields; do **not** invent Evidence (`product-evidence-lite.md`). If required siblings are missing under FEATURE `needs_*` / brownfield, **STOP** per SKILL (do not Write PRD).

Anti-task-shatter titles (verb+file/class/script) in Prior context → keep as PLAN/refine altitude; do not promote into Valuable US framing without outcome rewrite (`anti-task-shatter.md` — load only when titles look task-shaped).
