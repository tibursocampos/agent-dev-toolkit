# adt-delivery-flow - command playbook

**Load after Step 0 (`references/step0.md`) and the gates.** Ordered step discovery without dumping `SKILL.md` Process. Load one reference per step.

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| 0 | Blocking start: capability, model choice, preflight, notices | `references/step0.md` |
| -1b | Caveman: exempt in refine and plan, Lite otherwise | `CAVEMAN.md` |
| 1 | Resolve storage and feature | `STORAGE-FEATURE.md` |
| 2 | Triage the demand | `references/routing.md`, `TRIAGE.md` |
| 3 | Route to refinement | `references/routing.md`, `adt-delivery-refine/SKILL.md` |
| 4 | Route to planning, one approval | `references/routing.md`, `references/step0.md`, `adt-delivery-plan/SKILL.md`, `PLAN-LIFECYCLE.md` |
| 5 | Route to implementation | `references/routing.md`, `references/step0.md`, `adt-delivery-implement/SKILL.md` |
| 6 | Show progress | `DISPLAY.md`, `LIVE-STAGE-TABLE.md` |
| 7 | Resume and outcome | `references/routing.md`, `HANDOFF.md` |

## Stage order

Stage order, entry conditions and exit evidence: section "Stage map" in `SKILL.md`. Not repeated here.

## Stage table
Rows, weights and table kind: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` (section for this skill). Standard, glyphs and label map: `LIVE-STAGE-TABLE.md`.
