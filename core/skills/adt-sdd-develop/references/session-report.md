# adt-sdd-develop result

Report the step, observed result, applicable validation and any limitation or next action. In direct Classic do this after saving and re-reading the PLAN. Under O3, return the result without writing PLAN progress. Follow the chat language in `LANGUAGE.md`.

For a delegated direct step, the parent re-reads the persisted PLAN, checks the relevant result, and renders the complete current progress table before deciding whether to continue. For an O3 child, return the role-specific receipt; the O3 parent validates and reconciles it before dispatching another serial step.

Keep the PLAN row as the only persisted implementation progress. Do not create session reports, duplicate checkpoints, claims, or CONTINUITY progress mirrors as a completion condition. A missing or conflicting PLAN update blocks advancement until its owner resolves it.
