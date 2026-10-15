## Template usage

1. `Read` `skills/_shared/templates/sdd/PLAN.md`.
2. Copy into the canonical PLAN path; remove instructional brackets.
3. Fill **Mapa REQ → passo** so every PRD `REQ-NNN` appears in ≥1 step.
4. Each step **Aceite** cites **REQ-NNN** and/or CA with verifiable outcomes (no vague language). Mark completed REQ coverage in develop via checked Aceite lines.
5. **`## Related` (REQ-009):** Keep the template Navigation block. Title exactly `## Related`. **MUST** include the source PRD portable path. After Write, refresh the PRD `## Related` so it cites this PLAN (classic mutual cite when both exist). Cite STORY / FEATURE / CONTINUITY only when on-disk. **Omit-if-absent** — never stub siblings solely for links (`STORAGE.md` § Navigation block).
6. Immediately before the Mermaid graph, add a two-column index in the same order as the ledger: step id, objective.
7. Every test row has a precondition, an action, an assertion, and whether it is required or conditional.
8. Default to a mixed test strategy: keep distinct step-level checks with the
   step they validate, and explicitly assign deferred checks to a final
   consolidation step in the same US. That step maps acceptance criteria to
   tests/evidence, reviews integration or end-to-end coverage of primary flows,
   retains unit tests with distinct value, and removes only redundancy without
   unique coverage. The PLAN/US DoD stays open until required consolidation and
   configured STATE/EVD validation pass. A deferred test is never a passing
   result for an intermediate step.
