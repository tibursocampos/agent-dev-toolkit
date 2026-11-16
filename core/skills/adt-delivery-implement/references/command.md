# adt-delivery-implement - command playbook

**Load after the gates.** Ordered step discovery without dumping `SKILL.md` Process. Load one reference per step.

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Full when active | `CAVEMAN.md` |
| 1 | Select plan, approval check, entry check (prose: `plan=approved`, `Mode: full`, approval line) | `references/start-choices.md`, `PLAN-LIFECYCLE.md` |
| 2 | Guidelines (mandatory, `Guidelines:` line), choices, baseline, display point 1 | `references/start-choices.md`, `adt-delivery-refine/references/clarify.md`, `DISPLAY.md` |
| 3 | Show progress and execute steps | `references/execution.md`, `DISPLAY.md` |
| 4 | Criterion tests and closeout | `references/execution.md` ("Criterion tests"), `references/closeout.md` |
| 5 | Report, outcome, memory-bank offer | `HANDOFF.md`, `{{TOOLKIT_ROOT}}/skills/memory-bank-init/SKILL.md` |

## Stage table
Rows, weights and table kind: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` (section for this skill). Standard, glyphs and label map: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`.
