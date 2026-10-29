# Semantic sufficiency

**Purpose:** Decide whether the specific content consumed answers the material question at the intended boundary. This contract composes existing source-selection, provenance, ownership, decision, and artifact-identity contracts; it does not replace or reassign them.

Use this check when a decision, requirement, acceptance criterion, dependency, or reported result is carried into a downstream artifact or workflow. Apply it to the relevant question and consumer, not as a universal checklist for every file or every step.

## Proportional minimums

For each material question, provide enough information to establish these five things. Keep each explanation proportional to the decision and cite only the evidence needed:

| Minimum | What to establish |
|---------|-------------------|
| **Source** | Cite the portable path and section, or the observed check/result, that bears on the question. Search by topic only to find candidates; confirm the source actually addresses the fact being decided. |
| **Role** | State what the source contributes to this claim: for example, current normative text, an approved decision, implementation evidence, a test/fixture result, or historical context. These descriptions are not a new enum or authority ranking; resolve authority and ownership through `ARTIFACT-OWNERSHIP.md` and the applicable workflow contract. |
| **Consumer** | Name the downstream artifact, workflow, or decision boundary that relies on the claim, including its relevant section or REQ/CA when present. If no material consumer is identified, say why the question does not affect a downstream decision. |
| **Evidence** | Point to the specific statement, result, or observed behavior that supports or refutes the claim. Distinguish document inspection, fixture/static checks, and observed runtime; a link or identifier alone is not evidence of matching content. |
| **Limit** | State what the cited material does not establish, including an unverified host/runtime, an unsearched source, an inference, or a remaining gap. Absence of evidence is not evidence of absence. |

Do not demand all five as a fixed form when a question is immaterial or a field does not apply. For a material decision, explain non-applicability rather than silently omitting the source role, consumer, evidence, or limit. Do not fill a gap with an unconfirmed assumption; follow `CONTRACT-PROVENANCE.md` for `agreed` versus `invented` and `SELECTIVE-RETRIEVAL.md` for relevant, absent, and conflicting evidence.

When an explicit material operator request or correction is carried into implementation or review, preserve its source and context, disposition (`covered`, `preserved`, `excluded` only with approval, or `open`), mapped REQ/CA or unresolved question, responsible owner, consuming artifact, and result evidence with limits. Reuse the existing PRD/PLAN decision, step notes, and evidence artifacts; do not create a parallel ledger. An `open` item blocks only the acceptance and dependents it affects. If resolving it would change approved scope or acceptance, return it to the owning artifact instead of silently promoting it.

## Resource and journey proof

Apply this block only when a change alters a resource, screen, transition, or external response. Scope without such a change does not receive this gate. The consumer project supplies the proof; the toolkit requires it and reconciles it. For each material acceptance, provide each item below with its source, or record the missing item as a GAP:

| Item | What to establish |
|------|-------------------|
| **Reference** | The approved reference (portable path and section) for expected content, layout, and material fields. |
| **Resource/version** | The resource or configuration and version actually consumed, not only declared. |
| **Entry** | The condition that reaches the path. |
| **Route** | The route or transition exercised, including the negative paths. |
| **Transferred data** | The fields or state passed between producer and consumer, compared by key, value, or state. |
| **Observed output** | The observed output (content, layout, material fields) compared with the reference. |
| **Level** | The level executed (static, fixture/local, integration, or host), with command, environment, result, and limit. |

Rules:

- A declared resource without an observed route is not journey proof.
- Valid JSON or matching keys alone do not replace the observed output comparison.
- A disconnected fixture or a prior version proves only what it executed; it is not current consumer evidence.
- A level not executed is never PASS. Host unavailability keeps the dependent acceptance as a GAP and does not invalidate local proof.
- A missing link between reference, resource/version, route, and output is a GAP, never an inferred PASS.
- A material change to a resource, route, transition, or output reopens the journey proof of each affected acceptance: current proof items are required for them. Evidence for an unaffected element is kept only when its applicability to the changed element is demonstrated.
- A missing, incompatible, stale, unavailable, or failed item is recorded as FAIL, GAP, or BLOCKED with its cause and next action. It blocks only the dependent acceptance and its closure; independent work stays eligible.
- Privacy checks in journey evidence use synthetic or redacted values. Secrets, tokens, authorization headers, and personal data do not appear in payloads, logs, receipts, or fixtures.
- Compatibility of old and new formats, malformed input, defaults, cache, and authorization are checked only when material to the journey and backed by a current decision. A missing or conflicting decision is a GAP; a check outside the journey scope is not required.
- A category disabled within the journey scope produces no lookup. Evidence that shows such a lookup is FAIL for the dependent acceptance.

## Normative content and current decisions

A decision ID, portable link, or section identity establishes a traceable relationship. It does not establish that the consumer's normative text matches the decision.

1. Resolve the current decision and its owner using the existing decision record and ownership contract. In FEATURE, preserve decision IDs, affected normative destinations, status, and supersession links as defined by `core/skills/_shared/templates/features/FEATURE.md` §Decisions.
2. Inspect the actual normative section or acceptance text consumed. Confirm that its behavior agrees with the current decision and that the consumer is within the decision's stated scope.
3. If the section contradicts the current decision, treat the consumed content as insufficient even when every ID and link is valid. Identify the affected consumer and return the discrepancy to the existing owner for reconciliation; do not silently rewrite another owner's artifact.
4. A superseded decision remains historical context. Do not carry it forward as an active rule when the current decision record identifies its replacement.

The existing owner and approval gate remain authoritative. This check does not create an approval, promote `invented` content, or make a downstream summary a new source of truth.

## Change impact and selective reconciliation

Classify a change with the existing categories in `CONTRACT-PROVENANCE.md`: compatible, operational drift, material change, or incompatible. Compare the meaning at the affected consumer boundary. A hash or formatting diff proves that bytes were written; it does not prove that behavior changed.

Record the affected decision, normative section, consumers, and existing owner. Reconcile the affected content through that owner's current process. Formatting-only changes do not invalidate all downstream work after semantic equivalence is confirmed. A material or incompatible change requires reconciliation of the affected consumers before they rely on the changed content. Do not automatically invalidate the whole feature, preserve a materially changed approval by inference, or introduce a parallel state/ledger to track the result. If impact cannot be established, report the specific gap or conflict and keep only the dependent decision pending.

## Artifact identity and consumed-section sufficiency

The `source_context` envelope described by `core/skills/read-sdd-artifact/references/envelope-schema.md` identifies an artifact by kind, portable path, and applicable feature/story/file identity. It supports the existing no-opaque-reread behavior in `core/skills/read-sdd-artifact/references/build-consume-report.md`.

Identity and semantic sufficiency are separate checks. A valid envelope does not, by itself, show that the consumed section was supplied, answers the consumer's question, reflects the current decision, or supports the reported conclusion. When the body or relevant section is available, assess that content against the material question. Read only the current section needed to resolve an identified gap or contradiction; do not reread an artifact solely to rediscover identity already supplied by a valid envelope.

## Disposition

For a material question, state whether the result is a supported conclusion, a labeled inference or recommendation, insufficient evidence, or an unresolved conflict, then name the next authorized boundary. These are narrative dispositions, not new IDs, statuses, or workflow states:

| Outcome | Required handling |
|---------|-------------------|
| Supported conclusion | State the bounded conclusion, cite the relevant source/evidence, name its consumer, and preserve material limits. |
| Inference or recommendation | Label it as inference or recommendation; do not present it as an agreed decision or requirement. |
| Insufficient evidence | Name the requested fact not established, relevant sources checked, affected consumer, and existing owner or next source needed. |
| Conflict | Cite the incompatible claims and the affected consumer. Resolve only from an established authority, supersession, or scope distinction; otherwise keep that decision pending with its owner. |

Use the retrieval stop and contradiction rules in `SELECTIVE-RETRIEVAL.md`. Do not turn a finding into a new requirement, approval, owner, schema, or workflow state.

## Examples

These examples are synthetic and illustrate the judgment boundary; they do not assert live behavior.

| Case | Evidence and consumer | Disposition |
|------|----------------------|-------------|
| Relevant source supports the exact conclusion | Synthetic example: a current rule says an omitted optional field retains its prior value; the named consumer's normative section states the same behavior. The cited text supports that contract statement, but no runtime result was observed. | Supported for the stated normative behavior only; do not claim runtime verification. |
| Decoy shares keywords | Synthetic example: a historical note mentions the same optional field but describes a different workflow and consumer. | Exclude it from support and citations; continue with relevant sources or report a gap. |
| Linked decision contradicts normative text | Synthetic example: current decision `D-005` says to retain the prior value, while the linked PRD section says to clear it. All decision IDs and portable links are valid. | **Negative control: fail sufficiency.** Valid IDs, links, and envelope identity cannot override the contradictory text. Route reconciliation to the existing owner. |
| Decision is superseded | The current decision record links older `D-004` to replacement `D-005`, and the consumed section reflects `D-005`. | Treat `D-004` as history, not as an active requirement. |
| Formatting-only change | Whitespace, line wrapping, or presentation changes; semantic comparison confirms decision, rule, and acceptance content are unchanged. | Classify with `CONTRACT-PROVENANCE`; a changed hash alone does not invalidate consumers. |

## Compatibility boundary

Existing contracts continue to own source relevance and retrieval stops (`core/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md`), provenance and change classes (`core/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md`), artifact authority and writers (`core/skills/_shared/sdd-artifacts/ARTIFACT-OWNERSHIP.md`), invocation context (`core/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md`), decision identity and supersession (`core/skills/_shared/templates/features/FEATURE.md` §Decisions), and artifact identity (`core/skills/read-sdd-artifact/`). This reference adds a shared sufficiency judgment across those boundaries. It adds no ownership rule, provenance value, invocation context, storage/session behavior, receipt field, ledger, automatic invalidation, or runtime claim.
