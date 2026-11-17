## Template usage

1. Read `skills/_shared/templates/sdd/PLAN.md`; include enough detail to implement the requested outcome and remove prompts that do not apply.
2. Derive executable steps directly from the PRD or authorized demand. `adt-split-story-checklist` remains optional; a missing `TASKS` or `REFINE/tasks.md` file does not block planning.
3. Use useful step IDs and explicit dependencies. Map material behavior to steps where it helps trace acceptance; exact REQ/CA naming, numbering, or a prescribed count is not an authorization gate.
4. Maintain one progress table with step, dependencies, state, evidence/validation, and blocker/next action. Detailed step descriptions may explain goal, planned changes, limits, acceptance, and validation, but do not duplicate progress state.
5. Include brownfield current behavior, intended change, and concrete risks when relevant. Record only remaining material questions and identify the work they block.
6. Add validation appropriate to the risks and acceptance. Reuse existing evidence when sufficient; do not require one test per criterion or repeat a check without distinct evidence value.
7. Keep `## Related` links portable and point to the source PRD when it exists. Omit absent siblings; do not create CONTINUITY, CHANGE, TASKS, or another file for navigation.
8. Present the complete PLAN for one explicit approval before implementation. A direct planning invocation ends with handoff and does not start implementation automatically.
