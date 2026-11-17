# O1 triage

Classify the work to choose a proportionate path. These labels guide
investigation; they do not create approval, document, or specialist gates.

| Dimension | Guidance |
|---|---|
| Nature | `greenfield`, `brownfield`, or `operational`; use brownfield when existing behavior or integration may change. |
| Complexity | `trivial` for a clear isolated change; `medium` for one bounded story; `complex` for multiple outcomes, consumers, or unresolved impacts. |
| Scope | `backend`, `frontend`, `fullstack`, or an operational surface. |
| Investigation signals | `needs_*` describe questions to consider under shared `ROSTER.md`; they do not require specialists or folders by themselves. |

Prefer Classic SDD for one clear story and Backlog Refine for an informal item.
Use O1 for justified multi-story decomposition, multi-area impact, or concrete
unknowns that need coordinated investigation. A trivial shortcut may be
offered, but do not require the user to select a numbered menu when the
appropriate route is already clear.

## Collect the demand

Reuse supplied context. Identify the desired outcome, relevant current
behavior, constraints, likely affected areas, and material uncertainties. Read
only relevant cited files. A citation is usable evidence; do not require a
promotion copy merely because it is outside `features/`.

For an explicitly identified EPIC and feature ID, read only the selected
feature brief, relevant shared context, dependencies, and references needed to
understand it. A filename alone does not establish relevance. This narrow read
does not create a separate handoff or approval.

Ask focused questions only when the missing answer affects behavior,
acceptance, scope, required access, or an implementation choice. Identify the
affected work. Minor uncertainties and optional improvements remain visible;
they do not block independent work.

## Security and sensitive signals

Use the shared ROSTER and security contract when auth, secrets, PII,
supply-chain, or another concrete threat question is in scope. Ask for missing
facts only when required to assess a material risk or access boundary. Do not
place credentials, secrets, or raw PII in artifacts or agent prompts.
