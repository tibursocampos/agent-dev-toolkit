## Template usage

1. Start new PRDs from `skills/_shared/templates/sdd/PRD.md`. Follow the relevant surface guidance in `skills/_shared/sdd-artifacts/AUTHORING-CONTENT.md`; omit inapplicable prompts and keep equivalent sections in existing PRDs.
2. Describe the outcome, scope, material functional and non-functional requirements, and acceptance in verifiable terms. Write new criteria in Given / When / Then, covering relevant success, failure, and boundary cases. Link to existing contract sources at their specific section or symbol.
3. Include current behavior, intended change, and concrete risks when the request changes an existing system and that impact matters. Cite only evidence actually inspected; mark limits clearly.
4. Record unresolved material questions with options when useful and affected work. When answered, record the observable decision and source. Follow `skills/_shared/agents/QUESTIONS.md` for a disappeared or expired prompt. Minor questions do not block unrelated work.
5. Keep `## Related` with portable paths to siblings that exist or are known. Omit absent siblings; do not create CONTINUITY, CHANGE, TASKS, or another file to satisfy a link.
6. Drafting and saving the PRD are preparation. The complete PLAN receives one explicit approval before implementation; do not add a separate PRD content or write approval gate. End this direct skill with a handoff to planning; do not start implementation.
