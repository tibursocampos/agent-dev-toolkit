# adt-delivery-refine - command playbook

**Load after the gates.** Ordered step discovery without dumping `SKILL.md` Process. Load one reference per step.

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman suspended in this stage (never compress) | `CAVEMAN.md` |
| 1 | Resolve storage and feature; write Operational record lines | `STORAGE-FEATURE.md`, `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md` |
| 2 | Entry check (prose: Step 0 passed, Operational record written, plan inside the feature directory) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`, `STORAGE-FEATURE.md` |
| 3 | Show progress, display point 1 (mandatory read) | `DISPLAY.md`, `LIVE-STAGE-TABLE.md` |
| 4 | Memory-bank check (selective read or absent) | `STORAGE-FEATURE.md` ("Memory bank root"), `MEMORY-BANK.md` |
| 5 | Specialist triage | `TRIAGE.md` |
| 6 | Guidelines (mandatory; `Guidelines:` line) | `references/clarify.md` ("Guidelines to read") |
| 7 | Clarify and gather evidence | `references/clarify.md` |
| 8 | Record in PLAN.md | `PLAN-TEMPLATE.md` |
| 9 | Outcome and handoff | `HANDOFF.md` |

## Stage table
Rows, weights and table kind: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` (section for this skill). Standard, glyphs and label map: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`.
