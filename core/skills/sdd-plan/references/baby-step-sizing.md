# Outcome-based planning

Derive steps from the requested behavior, acceptance, dependencies, and available evidence. Do not create one step per file or layer, and do not invent technical work that the evidence or request does not support.

- Name each step for a result that can be reviewed. Mention files or components in the planned-change detail when useful.
- Group closely related outcomes that share dependencies and validation; separate work when it has a real independent outcome, risk, or dependency boundary.
- Represent only real blocking dependencies. Independent steps need not be serialized for ceremony.
- Do not estimate duration or impose a fixed number of steps.
- Use IDs that are easy to reference. Preserve IDs from an existing linked checklist when doing so is useful and consistent with the approved scope; otherwise derive IDs in the PLAN.
- Keep migration, mapping, API, UI, and infrastructure work together or separate according to their behavior and proof boundaries, not a universal file-count rule.
- Write acceptance so a reviewer can recognize the outcome, using an existing requirement ID when helpful. Do not require a fixed REQ/CA format, named automated test, or checklist row for every step.
- Cite relevant ARCH/ANALYSIS/SEC evidence when it exists and informs the step. Its absence alone does not block planning.

For detailed code or test decomposition, retain the project's existing structure and avoid speculative implementation choices.
