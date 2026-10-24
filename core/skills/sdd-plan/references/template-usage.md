## Template usage

1. `Read` `skills/_shared/templates/sdd/PLAN.md`.
2. Copy into the canonical PLAN path; remove instructional brackets.
3. Fill **Mapa REQ → passo** so every PRD `REQ-NNN` appears in ≥1 step.
4. Each step **Aceite** cites **REQ-NNN** and/or CA with verifiable outcomes (no vague language). Mark completed REQ coverage in develop via checked Aceite lines.
5. **`## Related` (REQ-009):** Keep the template Navigation block. Title exactly `## Related`. **MUST** include the source PRD portable path. After Write, refresh the PRD `## Related` so it cites this PLAN (classic mutual cite when both exist). Cite STORY / FEATURE / CONTINUITY only when on-disk. **Omit-if-absent** — never stub siblings solely for links (`STORAGE.md` § Navigation block).
6. Immediately before the Mermaid graph, add a two-column index in the same order as the ledger: step id, objective.
7. Every test row has a precondition, an action, an assertion, and whether it is required or conditional.
8. Use BDD as the language for observable behavior and acceptance; it does not
   require an automated test for each scenario or a new test in every step. Use
   TDD selectively when test-first feedback provides distinct evidence for the
   behavior, risk, or boundary. The PLAN records per behavior (or a justified
   group sharing the same evidence and boundary): REQ/CA, existing coverage or
   evidence, primary proof boundary, disposition (reuse, add/change, defer with
   reason, limit/dependency, or no new check with a reason), owner, and
   create/execute checkpoint. Any
   additional proof cites distinct behavior or composition value. In a
   service-to-handler-to-consumer chain, do not repeat the same validation at
   every layer; cover lower layers for their own behavior and composition where
   it adds evidence. Follow the consumer's established runner, libraries,
   doubles/mocks, and test structure. Deferred checks stay pending, have a
   reason, limit, dependency, owner, and checkpoint, and never pass or close intermediate acceptance; put
   them in final consolidation only when they do not gate that step. Final
   consolidation maps applicable acceptance criteria to tests/evidence,
   preserves unique unit and unrelated smoke coverage, and removes only proven
   redundancy. Keep the PLAN/US DoD open until required consolidation and
   configured STATE/EVD validation pass.
