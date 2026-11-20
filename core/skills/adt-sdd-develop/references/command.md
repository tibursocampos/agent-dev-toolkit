# adt-sdd-develop command playbook

Load after the shared pipeline and canonical PLAN path are resolved. Use one PLAN step at a time and load only the relevant step references.

| Step | Action | Reference |
|---|---|---|
| 1 | Resolve invocation context and confirm approved scope. Resolve cadence only for direct Classic | `PIPELINE.md`, `INVOCATION-CONTEXTS.md`, `references/develop-modes.md` |
| 2 | Acquire the canonical PLAN, resolve the requested step, and verify dependencies, scope, acceptance, and access | `references/plan-acquisition.md` |
| 3 | Show the complete PLAN-step table and step summary in direct Classic; O3 owns its table | `references/execution-display.md` |
| 4 | Inspect relevant code and repository conventions, then implement the approved step | `references/code-analysis.md`, `references/stack-pointers.md` |
| 5 | Run applicable validation. Record evidence and limitations in the direct PLAN row or return them to the O3 coordinator | Repository guidance; `references/plan-update.md` |
| 6 | In direct Classic, re-read the PLAN, reconcile its row and report through the table owner. Under O3, return the scoped result only | `references/plan-update.md`, `references/execution-display.md`, `references/session-report.md` |

Before marking a step complete, use `references/quality-self-check.md`. Optional evidence or closeout flows apply only when their own concrete trigger is present. Classic execution does not run session or claim scripts.
