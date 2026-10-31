# Readiness severity (B / I / MINOR) + READY gate

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/readiness-severity.md`

**Language:** This guideline is **English**. Operator chat mirrors the **user chat language** (`LANGUAGE.md`). Artifact body language follows content-language resolution (`LANGUAGE.md`; `null` ≠ pt-BR).

Companion: `clarify-depth.md`, `PIPELINE.md` § Feature / story siblings, `INVOCATION-CONTEXTS.md`, `SESSION.md`, `STORAGE.md` § Portable path, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`).

**Rule IDs:** `RDY-SEVERITY` · `RDY-DUAL-PLANE` · `RDY-STOP-O2` · `RDY-MACHINE-GATE` (REQ-004 / REQ-005 / REQ-006 / RN02 / TE01)

---

## Purpose (REQ-004 / CA2)

Clarify and O2 handoff need a **typed** readiness status. Folder **presence** of `ANALYSIS/` / `ARCH/` / `SEC/` is necessary when flags require it — it is **not** clarification READY (**RN02**).

Canonical severity identifiers (English tokens only):

| Id | Meaning | Blocks READY? |
|----|---------|---------------|
| **B** (Blocker) | Ambiguity that would make wrong PRD/PLAN/impl likely | **Yes** |
| **I** (Important) | Material gap; next stage unsafe without an answer | **Yes** |
| **MINOR** | Clarification still needed, but lower impact | **Yes** |

Canonical status tokens:

| Token | Meaning |
|-------|---------|
| **READY** | No unanswered **B**, **I**, or **MINOR** questions. |
| **NEEDS_CLARIFICATION** | One or more unanswered **B**, **I**, or **MINOR** questions at a gate boundary. |

Do **not** invent alternate status ids that collapse READY vs NEEDS (e.g. “mostly ready”).

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
| **Implementation** | O3 / `sdd-develop` / ledger / SESSION `step_confirmed` / `tests_run` | “Questions closed” / clarification READY |

Readiness **READY** ≠ PLAN step Completed. Do **not** overload PLAN step status or SESSION develop gates with clarify severity. `step_confirmed` never implies READY.

`READY` is only the clarification status: no unanswered B/I/MINOR questions remain.
It does not mean the implementation Definition of Ready (DoR) is satisfied, does
not approve a PLAN, and does not authorize starting a step. The implementation DoR
is checked separately against the PRD/PLAN contract in
`templates/sdd/PRD.md` §2.1 and `templates/sdd/PLAN.md` §Readiness and completion
contract. Likewise, a satisfied DoR does not mean implementation DoD is met; DoD
requires the declared acceptance, validations, and evidence at the applicable
step/US boundary.

## STOP / NEEDS_CLARIFICATION (REQ-005 / TE01 / `RDY-STOP-O2`)

At an O2 Write boundary (PRD/PLAN) or refine equivalent (fake-forward “approved for PRD” while B/I/MINOR remain):

The global READY rule applies at every readiness boundary: any unanswered **B**, **I**, or **MINOR** question blocks the next artifact. Stop code: `open_question`.

1. **STOP** Write of PRD/PLAN (and do not claim backlog/PRD readiness).
2. Emit typed handoff: status **`NEEDS_CLARIFICATION`** + **portable** artifact paths (`STORAGE.md` § Portable path) + short severity list (few sharp questions — align `clarify-depth.md`).
3. Route to `refine-story` (which runs `requirement-review` before handoff) and/or O1 light.

Presence STOP (missing `ANALYSIS/` / `ARCH/` / `SEC/` when `needs_*` / brownfield) remains orthogonal and still applies. WS3 **adds** quality/severity on top of presence — presence alone never yields READY (**RN02**).

### Context boundary for required siblings

The presence rule is strict only for `invocation_context=orchestrated` (O1/O2). In `direct` Classic SDD, a missing O1-only `ANALYSIS/`, `ARCH/`, or `SEC/` sibling is an operator decision point: ask for inline creation, explicit operator-risk continuation, or optional `/orchestrate-analyze`. Do not hard-block direct mode solely on that missing folder. This exception does not waive unanswered open questions at the four Open-question gates, does not make folder presence equal READY, and does not relax any B/I severity result.

The risk path must durably register `owner`, the portable missing `path`, and the current `baseline` that is not reconciled. If the operator does not choose inline or risk, stop. Orchestrated mode must return to O1 and must not use the direct waiver.

### Operator handoff shape (user chat language; English tokens)

```text
Status: NEEDS_CLARIFICATION

Paths:
- features/NNN-slug/USnn/STORY.md
- features/NNN-slug/USnn/REFINE/… (if any)

Open (B/I/MINOR):
- [B] <sharp question>
- [I] <sharp question>

Next: answer B/I/MINOR → re-check READY → then O2 Write / sdd-spec
```

When **READY**: proceed with Write.

## Open-question gate

These four write gates use stop code **`open_question`**. At each of them, any unanswered question blocks the next artifact. That includes severity **MINOR**. On this chain, **MINOR** does not proceed on an assumption.

| Gate | Moment | What stays blocked |
|------|--------|--------------------|
| O1 feature gate | `orchestrate-analyze`, before any story folder | Next artifact while FEATURE has an open question |
| O2 story-files gate | Before the PRD of that story | PRD while required STORY, `ANALYSIS/`, `ARCH/`, or `SEC/` has an open question |
| PRD gate | Before the PLAN of that story | PLAN while that story's PRD has an open question |
| PLAN gate | Before persisting the PLAN | PLAN write while a question on that plan is still unanswered |

Close a question only with cited evidence (a portable path, `STORAGE.md`) or an explicit user answer recorded against the question id. Silence does not close a question. "I do not know" leaves the question open. A specialist recommendation is not a close.

Finding shape: `refine-story/references/finding-format.md`. A blocked story does not erase sibling stories and does not re-slice the feature.

## Consumers (skill-text this US)

| Skill / ref | Obligation |
|-------------|------------|
| `clarify-depth.md` | Depth rules + pointer to this severity / READY rule |
| `orchestrate-deliver` (`preconditions`, per-story, Must not) | Before PRD/PLAN Write: if any unanswered B/I/MINOR → STOP + typed handoff |
| `refine-story` (boundary / guardrails) | Do not hand off as ready-for-PRD while any unanswered B/I/MINOR is open; emit `NEEDS_CLARIFICATION` |
| `requirement-review` (feature and tech challenge) | Writes `Status:` plus open B/I/MINOR questions; READY only with none unanswered; no ready-for-PRD claim while questions wait |

**Machine gate (PS1 / REQ-006):** `{{TOOLKIT_ROOT}}/scripts/validation/Invoke-SiblingReadinessGate.ps1` evaluates the stable markers (`Status: READY|NEEDS_CLARIFICATION`, severity table cells, `-[B]`/`-[I]`/`-[MINOR]` lists) — no free-form prose parse; no tracker or runtime dependency. This file remains the skill/contract SoT for taxonomy and STOP wording.

## What this contract does **not** include

| Out of scope | Reason |
|--------------|--------|
| Tracker or Python runtime | Selective PS1 only (separate step) |
| `agents.max_depth` host knobs | SPAWN caps unchanged |
| Duration / story-point estimates in checkpoints | Forbidden |
| Monolithic `feature-refinement.md` | Navigation is WS7; readiness pointers stay short |
| Equating folder presence with READY | **RN02** |

## Checklist (manual CT for REQ-004 / REQ-005)

- [ ] Severity rows use **B** \| **I** \| **MINOR** (or mapped legacy)
- [ ] READY definition: zero unanswered B/I/MINOR
- [ ] Dual plane: readiness ≠ `step_confirmed` / impl Complete
- [ ] Open B/I/MINOR at O2/refine boundary → STOP Write + `NEEDS_CLARIFICATION` + portable paths
- [ ] At the four Open-question gates, any unanswered question (including `MINOR`) stops with `open_question`
- [ ] Sibling folder present ≠ READY
