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
   behavior, risk, or boundary. For material behavior, apply
   `skills/_shared/sdd-artifacts/SEMANTIC-SUFFICIENCY.md` rather than duplicating
   its criteria: cite source paths and sections or symbols actually read,
   identify what role the evidence plays, distinguish demonstrated behavior
   from proposal or gap, and state the proof
   limit. Trace source/producer, selection/route, receiver, and effect only as
   relevant. A present receiver does not prove a publisher or integration; do
   not imply messaging where the flow has none. Include a material negative
   route when it bounds the behavior.

   The PLAN records each behavior (or a justified group sharing evidence and a
   proof boundary) against REQ/CA, existing coverage/evidence, primary proof
   boundary, disposition (reuse, add/change, defer with reason, limit/dependency,
   or no new check with a reason), owner, and create/execute checkpoint. Add
   validation only for distinct missing evidence or composition value. Any
   additional proof cites distinct behavior or composition value; do not repeat the same validation at
   every layer; cover lower layers for their own behavior and composition where it adds evidence.
   Do not repeat a check per
   file or step without a distinct proof boundary. Follow the
   consumer's established runner, libraries, doubles/mocks, and test structure.
   Deferred checks stay pending, have a reason, limit, dependency, owner, and
   checkpoint, and never pass or close intermediate acceptance; put them in
   final consolidation only when they do not gate that step. Final
   consolidation maps applicable acceptance criteria to tests/evidence,
   preserves unique unit and unrelated smoke coverage, and removes only proven
   redundancy. Keep the PLAN/US DoD open until required consolidation and
   configured STATE/EVD validation pass.
