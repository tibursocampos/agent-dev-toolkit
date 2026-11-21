# Authoring content for SDD and Delivery

Read for the current artifact and its applicable risks. Start new documents from the workflow's canonical template. In an existing document, use equivalent sections and link to the artifact that owns a shared contract. Leave inapplicable guidance out. Heading order, titles, IDs and wording are editorial conventions.

## Observable requirements and decisions

- Describe the intended outcome, current behavior where relevant, included work, and explicit exclusions. Use a metric only when there is a defensible way to measure it. Name material functional and non-functional requirements.
- Author story and PRD acceptance as Given / When / Then and use the same pattern for the Delivery PLAN. Include each relevant success, failure or boundary scenario. Keep the Then observable. Existing equivalent criteria can be used in place.
- A story's Definition of Done points to the evidence for its outcomes. Feature completion proves that the stories work together, including boundaries between producers and consumers. Keep execution status in the PLAN.
- Record the source of each material decision and label unconfirmed alternatives as proposals. Cite an inspected path and symbol or section, or an authorized portable external reference. Distinguish source observations, inferences, proposals, simulations and results observed in an actual environment. State what each source establishes and what remains unknown.
- Follow `../agents/QUESTIONS.md` for material questions. Record the question, alternatives where useful, affected work and the observable answer with its source in the existing decision section. Only work that depends on the answer pauses. A change to approved behavior, scope, acceptance, access or a material implementation decision returns to the decision owner. Use the existing approval boundary.

## Depth by affected surface

| Surface | Close the material choices before implementation |
|---|---|
| API or external integration | Operation and consumer, input/output types and required fields, mapping, status and error behavior, examples, and exact contract source. Where relevant, define timeout, retry, idempotency and handling of uncertain outcomes. Distinguish fixture proof from live evidence. |
| Persistence or data | Entity model, cardinality, keys/constraints, transaction boundary and invariants, existing data, and migration or recreation. State how representative integrity cases are verified and which provider is actually executed. |
| Worker or concurrency | Triggers, states and transitions, ordering and ownership (including claim and fencing when used), deduplication, recovery after interruption, partial failures and limits of guarantees. Use a transition table or diagram when it resolves ambiguity. |
| Security or privacy | Assets and sensitive data, current authentication and authorization, trust boundaries, destination, access, retention when relevant, failure behavior, proposed controls and their verification. A new credential, permission, destination or disclosure needs a material decision. |

Start from a concrete question, such as what a consumer can read after an asynchronous acknowledgment. Choose a specialist only if that expertise helps answer it. Record observed behavior, evidence, alternatives and impact in the canonical artifact. When separate technical notes are useful, use the ANALYSIS, ARCH or SEC scaffold under `../templates/features/story/`.

## Executable steps and one substantive review

A step identifies the observable outcome, preconditions and dependencies, paths and symbols to change or add, intended changes and limits, relevant error behavior, acceptance covered, and the check with expected evidence. Keep dependency and progress information in its canonical place. When a step creates or changes a contract (signature, JSON shape, request or response, error payload, command), copy the exact contract excerpt into that step. Refer by id only to contracts the step does not change. Leave only naming and formatting to established repository conventions; never leave behavior, contracts, data or security choices to them. Close choices that affect behavior, contracts, data, security, architecture or operational guarantees.

In the existing review, follow one outcome from the original demand through the contract, step and expected evidence. Reconcile interfaces between stories or steps, particularly when a producer makes a different guarantee than its consumer assumes. Identify the missing decision and affected work. Check only the affected content after a material correction. Prefer an editorial suggestion for equivalent grammar or naming. This guidance adds no automated document check, extra approval or second review round.
