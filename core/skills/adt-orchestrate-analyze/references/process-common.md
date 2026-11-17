# O1 common practices

## Resolve storage and paths

Use `STORAGE.md` and, when needed, `STORAGE-RESOLUTION.md` to resolve the
canonical feature root. Common roots are repository `features/` or the
manifest-selected global `<classic.path>/features/`.

Normalize portable paths and reject traversal or paths outside the resolved
feature root. Preserve the current workspace and its existing files. Do not
edit application `.gitignore` outside the repository storage rules. Ask about
storage only when the canonical destination is genuinely unresolved; do not
repeat a choice already established by the manifest or conversation.

O1 may prepare and revise its authorized FEATURE/STORY/analysis artifacts
without separate write confirmation. This does not authorize product-code
changes, commits, pushes, PRs, publication, installation, deletion, or unrelated
external actions.

## Questions and evidence

Ask only when a decision blocks determining behavior, acceptance, scope,
required access, or an implementation choice. Identify affected work and keep
unrelated investigation moving. Minor questions and optional improvements may
be recorded without stopping the flow.

Use relevant repository and cited evidence directly. Distinguish observed
facts, inferences, suggestions, and operator decisions. Cite portable paths
where useful. Do not fabricate evidence or promote suggestions into approved
scope. Read only relevant Memory Bank files if an existing bank can answer a
concrete question; see `memory-bank-gate.md`.

## Handoff

There is no separate O1 backlog approval or durable CONTINUITY checkpoint.
Summarize the demand, prepared stories, material decisions/questions, evidence
limits, and next action in the session. O2 or Classic planning obtains one
explicit approval for the complete implementation PLAN set before code.
