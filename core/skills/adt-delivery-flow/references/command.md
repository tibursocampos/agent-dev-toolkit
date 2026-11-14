# adt-delivery-flow - command playbook

**Load after the gates.** Ordered step discovery without dumping `SKILL.md` Process. Load one reference per step.

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| 1 | Resolve storage and feature | `STORAGE-FEATURE.md` |
| 2 | Triage the demand | `references/routing.md`, `TRIAGE.md` |
| 3 | Route to refinement | `references/routing.md`, `adt-delivery-refine/SKILL.md` |
| 4 | Route to planning, one approval | `references/routing.md`, `adt-delivery-plan/SKILL.md`, `PLAN-LIFECYCLE.md` |
| 5 | Route to implementation | `adt-delivery-implement/SKILL.md` |
| 6 | Show progress | `DISPLAY.md`, `LIVE-STAGE-TABLE.md` |
| 7 | Resume and outcome | `references/routing.md`, `HANDOFF.md` |

## Stage table
Rows, weights and table kind: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` (section for this skill). Standard, glyphs and label map: `LIVE-STAGE-TABLE.md`.
