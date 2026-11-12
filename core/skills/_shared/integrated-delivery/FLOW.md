# Integrated delivery flow contract

Status: Stage 1 design contract for the opt-in `integrated-delivery` flow.

## Ownership and canonical sources

| Concern | Authority | Consumer | Persisted when |
|---|---|---|---|
| Feature intent, scope, decisions, criteria, unit boundaries, shared files | One feature `REFINEMENT.md` | Coordinator and all unit plans | Refinement is required: multiple units, shared files, changed contracts, or superseded material decisions |
| Unit requirements, evidence references, implementation steps, tests and execution state | One `(USnn|TSnn)/PLAN.md` per unit and affected repository | Plan reviewer and implementer | A unit has repository work |
| No-change decision | Owning feature refinement; evidence reference and decision ID | Coordinator and feature reviewer | A repository was assessed and needs no change |
| Review result and exact identity | Delivery review record | Coordinator and approver | Every required cold review |
| Runtime progress / resume | Operational block in unit plan | Implementer | Plan execution starts |

Story and PRD may be inputs. They are not parallel authorities after their accepted content is represented in the canonical refinement or unit plan. Full conversations and raw specialist transcripts are not canonical artifacts.

Platform constraints (source, version, statement, uncertainty) are evidence entries of the feature refinement, not a legacy gate; an external-effect step also needs the activation and rollback statement defined in the plan format.

## Flow states

`intake → feature_refinement → feature_review → feature_approval → unit_plan → plan_review → plan_approval → implementation → validation → complete`

The coordinator is the sole user-facing entry and routes one state at a time. It may invoke internal stages and conditional specialists. It presents one current status, material questions and next eligible transition. It must not infer approval from a review result, a file status, or an earlier approval.

- A single simple unit may omit the feature refinement only under the rule in `DOCUMENTS.md`.
- Each feature refinement receives a cold reader and critic review before feature approval.
- Each executable unit/repository plan receives a cold reader and critic review before plan approval.
- After a correction, reviewers recheck the changed content and affected context. The review identity includes declared dependencies; a changed, missing, or unverifiable dependency blocks the affected approval and execution.
- An unavailable cold review stops the flow and offers an explicit bypass with reason. B/I findings remain blocking under bypass.
- Drafts may be prepared in memory or scratch, then cold-reviewed before the canonical write. Do not require legacy SDD structural validators, scorecards, or quality checklists as gates in this flow. Keep only checks necessary for the chosen operational state format and safe execution.
- Plans and refinements are written for a cold reader. Material external facts are checked against primary sources when available; record the source, version/date, and uncertainty when a fact shapes scope, acceptance, or execution. Label repository observations, facts, inferences, assumptions, and gaps distinctly.

## Conditional specialist routing

The coordinator invokes domain, architecture, API, database, security, frontend, or DevOps specialists only when the intake or repository evidence shows a material need. Security signals are evaluated even when other specialist routes are off. Specialist conclusions return as concise findings with evidence, confidence (`CONFIRMED`, `INFERRED`, `GAP`), affected decision/criterion IDs, and limitations. A separate note is allowed only if a downstream consumer needs the detail, sensitivity requires separation, or the canonical document would become unwieldy; the canonical document retains a summary and stable reference.

No specialist folder is created empty. No specialist result creates authorization or a new requirement by itself.

## Questions, approvals, and transitions

Questions are grouped by material decision. A material decision can change objective, scope, acceptance, unit boundaries, shared-file ordering, security posture, approval identity, or permitted implementation action. Unresolved material decisions block only the affected approval and dependent work. MINOR observations remain recorded without blocking unless they reveal a material gap.

Examples: changing an accepted API contract or deciding that another repository must change is material; correcting a typo in a progress note or adding a non-normative evidence link is not. Reclassify if the added evidence changes a criterion, dependency, risk, or approval identity.

Explicit approval of a cold-reviewed refinement or plan authorizes writing that displayed content to its declared canonical path; there is no separate content-approval and write-authorization prompt. An approved refinement authorizes planning only for the accepted feature scope. An approved unit plan plus the operator's selected cadence authorizes implementation within that plan. Continuous mode covers all eligible steps; eligibility requires completed valid dependencies, resolved material decisions, current approvals/reviews, and action within the approved scope. Stop on actual blockers, material scope changes, stale dependencies, or unauthorized Git/publication actions. Step-by-step mode stops after one eligible step. Neither mode authorizes commit, push, merge, publication, external writes, or out-of-scope changes implicitly.

## Failure and recovery

If a required artifact, review record, dependency identity, approval, or validation is missing, changed, or unverifiable, stop the affected transition and report the exact reason. Resume from the plan's operational checkpoint only after revalidating material input identities, branch and HEAD. Do not replay an `IN_PROGRESS` step automatically; reconcile its diff or request operator direction. Never mark completion from a receipt, progress count, or status token without required acceptance and validation evidence.

## Current-flow disposition requirement

Before removing or merging any existing O1/O2/O3 gate, Stage 1 coverage matrix must identify its purpose, input, output, failure detected, consumer, available cost evidence, replacement control, and evidence that the replacement covers the same risk. Unknown cost or unproven coverage is recorded as a gap; it does not justify removal. Current skills remain unchanged by this contract.
