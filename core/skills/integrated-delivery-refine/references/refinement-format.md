# REFINEMENT.md content outline

Use this outline for a required feature refinement. Keep each normative item in one place and use stable references elsewhere. Omit a section only when it is genuinely not applicable; state `None` or the reason when omission could be mistaken for an oversight.

1. **Identity and declared inputs** — feature/repository identity, portable source paths, stable revision or content hash when available, role, affected IDs, language.
2. **Triage** — objective, complexity, nature/scope, specialist signals and reasons.
3. **Objective and boundaries** — desired outcome, in-scope behavior, exclusions, current/target flow when relevant.
4. **Decision register** — stable `D-###`, blocking/important/minor, status, question and answer, normative value, superseded decision, affected unit/criterion IDs.
5. **Acceptance criteria** — stable `CA-###`, Given/When/Then, source and decision IDs, evidence/validation, affected unit, status.
6. **Evidence and analysis** — concise conclusion, source, confidence (`CONFIRMED`, `INFERRED`, `GAP`), limitation, affected decision/criterion IDs. Include specialist results only when triggered.
7. **Risks and assumptions** — impact, evidence, owner or resolution point; retain unresolved material questions explicitly.
8. **Unit and repository map** — one outcome per `USnn` or `TSnn`, dependency order, shared-file owner/order, each affected repository as `AFFECTED` or evidence-backed `NO_CHANGE`.
9. **Definition of done** — criterion IDs and required evidence; do not restate criterion text.
10. **Operational review and approval block** — maintain outside normative identity per the shared contracts. Do not record raw private transcripts or credentials.

## Cross-reference rules

- The decision's normative value is authored only in its decision-register row; other sections cite the ID.
- Criterion body is authored only in the acceptance section; plans and evidence cite its ID and body identity.
- Supersession updates the former decision status and points to the new ID; never silently erase history or recycle IDs.
- Every unit boundary must have a rationale tied to outcome, repository, dependency, or shared-file sequencing. Avoid splitting solely by layer or specialist.
- `NO_CHANGE` requires inspected paths/symbols, applicable rule/criterion, considered change, and evidence for why no change applies. Insufficient evidence remains `GAP`.
