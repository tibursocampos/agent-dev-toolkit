# INVEST and story quality

Normative checklist for **Independent, Negotiable, Valuable, Estimable, Small, Testable** stories. Used by O1 synthesis, `refine-story` scorecard, and promotion gates. Lazy-load — do not preload for every skill.

**Complementary:** `story-sizing.md` (how many / how large); `persona-context.md` (Who/Job/Outcome); `anti-task-shatter.md` (what must not become a US/TS).

External ideas (paraphrase only; do not vendor third-party bodies): classic INVEST criteria for backlog quality — curated link in `docs/CREDITS.md`.

---

## Valuable (RN04)

| Item type | Rule |
|-----------|------|
| User Story | Declare **beneficiary** + **observable progress** (Product intent / Who+Job+Outcome) |
| Technical Story / Bug | Product intent may be `n/a`; still state a **verifiable technical outcome** |

Vague delivery ("improve X") without a measurable or observable Then fails Valuable.

---

## Other INVEST dimensions (compact)

| Letter | Pass when | Fail when |
|--------|-----------|-----------|
| **I** Independent | Story can ship without mandatory sibling merge in the same wave (deps explicit) | Hard-coupled to unfinished sibling with no rationale |
| **N** Negotiable | Scope and AC can be challenged; implementation how is not locked in the title | Title encodes file/class/script or a fixed design |
| **E** Estimable | Team can size relative effort from Objective + AC | Unknown domain with no spike/OOS |
| **S** Small | Fits one PR / refine baby-step budget (`story-sizing.md`) | Needs >~8 refine steps without split |
| **T** Testable | AC have observable Then (see `gherkin-budget.md`) | Only implementation tasks, no business/tech Then |

---

## Quality bar before human backlog gate

1. Title and Objective name an **outcome**, not a file list.
2. US has Valuable fields filled (or explicit deferral with reason — rare).
3. AC budget meets `gherkin-budget.md` when the item is a US (or TS with behavioral AC).
4. Failures of I/N/E/S/T are recorded as refine challenges, not silently shipped.

---

## Relationship

| Artifact | Role |
|----------|------|
| `anti-task-shatter.md` | Hard stop on task-shaped promotion |
| `splitting.md` | When Valuable/S force a split |
| `clarify-depth.md` | Open questions that unblock Negotiable/Estimable |
| Templates FEATURE/STORY | Persist fields; this file is the norm |
