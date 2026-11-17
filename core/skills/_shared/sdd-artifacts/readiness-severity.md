# Readiness severity (B / I / MINOR)

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/readiness-severity.md`

**Language:** This guideline is **English**. Operator chat mirrors the **user chat language** (`LANGUAGE.md`). Artifact body language follows content-language resolution (`LANGUAGE.md`; `null` ≠ pt-BR).

Companion: `clarify-depth.md`, `PIPELINE.md` § Feature / story siblings, `INVOCATION-CONTEXTS.md`, `SESSION.md`, `STORAGE.md` § Portable path, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`).

**Rule IDs:** `RDY-SEVERITY` · `RDY-DUAL-PLANE` · `RDY-STOP-O2`

---

## Purpose (REQ-004 / CA2)

Use severity to distinguish material blockers from useful but non-blocking questions. This contract does not make optional specialist folders or formatting a gate. A missing artifact blocks only when its evidence or decision is materially required for the work at hand.

Canonical severity identifiers (English tokens only):

| Id | Meaning | Blocks READY? |
|----|---------|---------------|
| **B** (Blocker) | Ambiguity that would make the next authorized work materially wrong or unsafe | **Yes, affected work only** |
| **I** (Important) | Decision needed for behavior, acceptance, scope, required access, or implementation choice | **Yes, affected work only** |
| **MINOR** | Lower-impact clarification or optional improvement | **No; keep visible** |

Canonical status tokens:

| Token | Meaning |
|-------|---------|
| **READY** | No unresolved **B** or **I** that blocks the next authorized action. MINOR items may remain visible. |
| **NEEDS_CLARIFICATION** | One or more unresolved **B** or **I** questions that block the affected next action. |

These labels are explanatory vocabulary, not machine authorization tokens.

## Legacy severity map (FEATURE / PRD tables)

Older templates may still show `blocker \| high \| medium \| low`. When evaluating READY, map:

| Legacy | Canonical |
|--------|-----------|
| `blocker` | **B** |
| `high` | **I** |
| `medium` | **MINOR** |
| `low` | **MINOR** |

New open-question rows **prefer** `B` \| `I` \| `MINOR` directly.

## Dual plane (REQ-004 / `RDY-DUAL-PLANE`)

| Plane | Owns | Must **not** mean |
|-------|------|-------------------|
| **Readiness** | Clarify / O1–O2: questions answered enough to Write the next artifact | Code done / tests green / PLAN step Complete |
| **Implementation** | Approved PLAN execution table, acceptance, and required validation | “Questions closed” / clarification READY |

Readiness **READY** ≠ PLAN step Completed. Do **not** overload PLAN step status with clarify severity. SESSION develop gates are not part of Classic/O1/O2/O3 readiness.

`READY` is only the clarification status: no unresolved B/I question blocks the next authorized action. MINOR items may remain.
It does not mean the implementation Definition of Ready (DoR) is satisfied, does
not approve a PLAN, and does not authorize starting a step. The implementation DoR
is checked separately against the PRD/PLAN contract in
`templates/sdd/PRD.md` §2.1 and `templates/sdd/PLAN.md` §Readiness and completion
contract. Likewise, a satisfied DoR does not mean implementation DoD is met; DoD
requires the declared acceptance, validations, and evidence at the applicable
step/US boundary.

## STOP / NEEDS_CLARIFICATION (REQ-005 / TE01 / `RDY-STOP-O2`)

At an O2 or refinement boundary:

Only an unanswered **B** or **I** that blocks the next artifact or implementation action pauses the affected work. Stop code: `open_question`. MINOR questions do not block and must not prevent independent stories from advancing.

1. Pause only approval or implementation of the affected scope; preparation and draft writing may continue with a clearly labeled assumption.
2. State the material question, affected paths, and next decision in concise prose; do not require a status token or typed handoff.
3. Route the missing decision to the appropriate owner; continue unrelated eligible work.

Do not stop solely because `ANALYSIS/`, `ARCH/`, or `SEC/` is absent by classification. Stop only when concrete evidence, a decision, or an access prerequisite is materially required and missing.

### Context boundary for required siblings

The presence rule is strict only for `invocation_context=orchestrated` (O1/O2). In `direct` Classic SDD, a missing O1-only `ANALYSIS/`, `ARCH/`, or `SEC/` sibling is an operator decision point: ask for inline creation, explicit operator-risk continuation, or optional `/orchestrate-analyze`. Do not hard-block direct mode solely on that missing folder. This exception does not waive unanswered open questions at the four Open-question gates, does not make folder presence equal READY, and does not relax any B/I severity result.

The risk path must durably register `owner`, the portable missing `path`, and the current `baseline` that is not reconciled. If the operator does not choose inline or risk, stop. Orchestrated mode must return to O1 and must not use the direct waiver.

### Operator handoff shape (user chat language; English tokens)

```text
Status: NEEDS_CLARIFICATION

Paths:
- features/NNN-slug/USnn/STORY.md
- features/NNN-slug/USnn/REFINE/… (if any)

Open items (unresolved B/I block affected work; MINOR stays visible):
- [B] <sharp question>
- [I] <sharp question>

Next: resolve blocking B/I → re-check affected readiness; carry MINOR context forward without blocking
```

When **READY**: proceed with authorized preparation or planning. Plan approval remains the only approval gate before implementation.

## Material question boundary

Use stop code **`open_question`** only when an unresolved B/I question prevents safe or correct progress on the affected next artifact or implementation action. MINOR remains visible but is non-blocking.

| Gate | Moment | What stays blocked |
|------|--------|--------------------|
| O1 analysis | Before story synthesis when a material decision is necessary | Only work dependent on the unresolved decision |
| O2 story plan | Before approval of implementation scope | Only the affected story or step when behavior, acceptance, scope, access, or implementation decision is unresolved |
| PRD / PLAN preparation | During drafting | Draft may proceed with clearly labeled assumptions; only a material unresolved item blocks approval or implementation |

Resolve a material question with cited evidence (portable path, `STORAGE.md`) or an explicit user decision. Do not present a specialist suggestion as a user decision. A minor question may remain open without blocking.

Finding shape: `refine-story/references/finding-format.md`. A blocked story does not erase sibling stories and does not re-slice the feature.

## Consumers (skill-text this US)

| Skill / ref | Obligation |
|-------------|------------|
| `clarify-depth.md` | Depth rules + pointer to this severity distinction |
| `orchestrate-deliver` | Pause only the affected story when a material B/I question blocks its next action; proceed on independent stories |
| `refine-story` | Label material open questions and distinguish non-blocking MINOR items |
| `requirement-review` | Report evidence, inference, suggestions, and decisions separately; do not promote suggestions to scope |

Readiness is a semantic review of material behavior, acceptance, scope, access, and implementation choices. Markdown labels, a fixed status token, or a structural validator do not authorize or block advancement by themselves.

## What this contract does **not** include

| Out of scope | Reason |
|--------------|--------|
| Additional runtime protocol | Not needed for a semantic blocker decision |
| `agents.max_depth` host knobs | SPAWN caps unchanged |
| Duration / story-point estimates in checkpoints | Forbidden |
| Monolithic `feature-refinement.md` | Navigation is WS7; readiness pointers stay short |
| Equating folder presence with READY | **RN02** |

## Checklist (manual CT for REQ-004 / REQ-005)

- [ ] Severity rows use **B** \| **I** \| **MINOR** (or mapped legacy)
- [ ] READY means no unresolved material B/I decision blocks the next action
- [ ] MINOR remains visible but does not block
- [ ] PLAN approval is the only approval before implementation
- [ ] Optional sibling folders are not required solely by classification
