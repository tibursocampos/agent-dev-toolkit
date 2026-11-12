# REFINEMENT.md content outline

Use this outline for a required feature refinement. Keep each normative item in one place and use stable references elsewhere. Omit a section only when it is genuinely not applicable; state `None` or the reason when omission could be mistaken for an oversight.

1. **Identity and declared inputs** — feature/repository identity, portable source paths, stable revision or content hash when available, role, affected IDs, language.
2. **Triage** — objective, complexity, nature/scope, specialist signals and reasons.
3. **Objective and boundaries** — desired outcome, in-scope behavior, exclusions, current/target flow when relevant.
4. **Decision register** — one item per decision, `D-###`, with the body fields in "Refinement items" (question and answer, normative value, status, superseded decision, affected unit/criterion IDs, severity blocking/important/minor).
5. **Acceptance criteria** — one item per criterion, `CA-###`, with the body fields in "Refinement items" (Given/When/Then, source and decision IDs, evidence/validation, affected unit, status).
6. **Evidence and analysis** — concise conclusion, source, confidence (`CONFIRMED`, `INFERRED`, `GAP`), limitation, affected decision/criterion IDs. Include specialist results only when triggered.
7. **Risks and assumptions** — one item per risk, `R-###`, with the body fields in "Refinement items" (impact, evidence, owner or resolution point); retain unresolved material questions explicitly.
8. **Unit and repository map** — one outcome per `USnn` or `TSnn`, dependency order, shared-file owner/order, each affected repository as `AFFECTED` or evidence-backed `NO_CHANGE`.
9. **Definition of done** — criterion IDs and required evidence; do not restate criterion text.
10. **Approval state (operational block)** — a refinement carries exactly one operational block `<!-- DELIVERY:APPROVAL:BEGIN -->` ... `<!-- DELIVERY:APPROVAL:END -->` holding one JSON object with `schema` `delivery-approval/v1`. Place it in its own final section headed by a level-2 heading `## Approval ...`, never a level-3 heading or text directly under an item, so that recording an approval cannot change an item hash. It carries no other DELIVERY block (no PROGRESS, CHECKPOINT, or STEP). Field names, required fields per `state`, and enums follow the APPROVAL table in `../../_shared/integrated-delivery/SCHEMAS.md` (section 6.3); do not copy them here. This block is excluded from the normative identity. All decisions, criteria, and text outside it are normative. Any status or approval prose lives only inside that block's JSON, never as free text in the normative sections, so recording an approval never changes the normative identity. Do not record raw private transcripts or credentials.

Minimal example, state `pending`:

```markdown
<!-- DELIVERY:APPROVAL:BEGIN -->
{"schema": "delivery-approval/v1", "state": "pending"}
<!-- DELIVERY:APPROVAL:END -->
```

**Amendments.** After approval, any change outside the APPROVAL block changes the normative identity and needs a new approval. Follow the `approved` -> `pending` transition in `../../_shared/integrated-delivery/SCHEMAS.md` section 6.3: reset the block to `pending`, then record a new approval for the new identity. Changes confined to the APPROVAL block's operational fields (for example `approved_utc` or `review_identity`) do not change the identity and need no new approval.

## Refinement items

A decision, criterion or risk is one item: a level-3 heading `### <ID> <title>`, where `<ID>` is `D-`, `CA-` or `R-` followed by at least three digits and is the first space-delimited token of the heading. The item body runs to the next heading of level 1-3 and holds one labelled line per field, using `none` when a field is empty:

- Decision (`D-`): `Question:`, `Answer:`, `Normative value:`, `Status:`, `Superseded decision:` (the ID this item replaces, or `none`), `Affected units/criteria:`, `Severity:` (`blocking`, `important` or `minor`).
- Criterion (`CA-`): `Given:`, `When:`, `Then:`, `Sources:`, `Evidence:`, `Affected unit:`, `Status:`.
- Risk (`R-`): `Impact:`, `Evidence:`, `Owner:`.

A superseded decision keeps its item and its body line `Status: superseded by <ID>`; its ID is never reused.

Item hash: the uppercase SHA-256 hex of the UTF-8 item body, from the heading line through the line before the next level 1-3 heading, LF-normalized, trailing blank lines trimmed, ending with exactly one LF. Editing one item changes only that item's hash; the IDs must be unique within the file.

### Focused amendment

Change only the affected item(s), as a minimal patch. Rewrite the whole document only with a stated reason.

1. Reset the APPROVAL block to `pending` (`../../_shared/integrated-delivery/SCHEMAS.md` section 6.3), re-review the affected content, and record a new approval.
2. Each dependent plan then reports `refinement_reference_stale` (changed hash) or `refinement_reference_superseded` (cited item superseded) in the preflight.
3. In each dependent plan, update only the affected `Uses:` lines. Read the new hashes with `Get-DeliveryRefinementItems.ps1`; for a superseded ID, cite the replacement ID. Re-audit the affected plan sections and re-approve the plan content.
4. Operational edits (progress, checkpoint, step status, evidence) never require a new normative approval.

## Cross-reference rules

- The decision's normative value is authored only in its decision item; other sections cite the ID.
- Criterion body is authored only in the acceptance section; plans and evidence cite its ID and item hash.
- Supersession updates the former decision status and points to the new ID; never silently erase history or recycle IDs.
- Every unit boundary must have a rationale tied to outcome, repository, dependency, or shared-file sequencing. Avoid splitting solely by layer or specialist.
- `NO_CHANGE` requires inspected paths/symbols, applicable rule/criterion, considered change, and evidence for why no change applies. Insufficient evidence remains `GAP`.
