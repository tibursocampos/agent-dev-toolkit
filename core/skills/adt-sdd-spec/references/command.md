# adt-sdd-spec — command playbook

| Step | Action | Reference |
|---|---|---|
| 1 | Resolve request, canonical story path, and relevant context | `PIPELINE.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md` |
| 2 | Inspect only evidence needed to understand behavior and material impact | `SELECTIVE-RETRIEVAL.md`, `references/challenge-vagueness.md` |
| 3 | Draft and substantively review PRD | `references/template-usage.md`, `references/req-tracking.md` |
| 4 | Resolve material questions that affect the PRD | `QUESTIONS.md` when presenting a question |
| 5 | Save the PRD and hand off to planning | `references/filename-numbering.md`, `references/storage-gitignore.md` |

## Progress table

A direct invocation owns one contextual table per `LIVE-STAGE-TABLE.md`. If O2 invokes this skill internally, O2 owns the table and this skill suppresses its own. Render complete current state at start, meaningful transitions, a blocking decision and its resolution, resume, and handoff. Do not add a separate approval table.

## Substantive review

Check that the PRD makes the requested behavior, acceptance, scope, relevant contracts, and material risks understandable. IDs and document form may help cross-reference but are not authorization requirements. Structural validators are optional diagnostics, not gates.
