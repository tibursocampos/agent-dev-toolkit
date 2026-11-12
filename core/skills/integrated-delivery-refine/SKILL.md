---
name: integrated-delivery-refine
description: >-
  Produces or updates the single canonical REFINEMENT.md for a multi-unit or cross-cutting integrated-delivery feature, consolidating decisions, criteria, evidence, specialist findings, risks, and unit boundaries. Do not use for a simple single-unit demand that can proceed directly to its plan.
---

# Integrated delivery feature refinement

Create or update one canonical `REFINEMENT.md` only when the shared document contract requires it. This skill does not implement application code, create story/PRD/task/analysis scaffolding, or start unit plans.

## Before writing

1. Read `../_shared/integrated-delivery/FLOW.md` and `DOCUMENTS.md`; at the first transition in a host session, follow `STARTUP.md` to resolve and record the startup marker before any canonical write. Check `-Gate spawn` before the first delegation and `-Gate review-record` before each durable review-record write. Read `REVIEW.md` when entering or resuming the cold-review gate.
2. Confirm this is a multi-unit/cross-cutting feature or a previously simple case that acquired a material cross-unit decision. If it is a simple single unit, return to the coordinator and route directly to planning.
3. Inspect current canonical files and declared source inputs. Resolve the feature path using the repository's existing storage convention; do not invent a root or write to the experiment's design folder.
4. Reuse settled decisions and evidence; ask the coordinator to collect unresolved material decisions before drafting. Do not repeat questions answered by the operator or current repository evidence.
5. For each material specialist signal, obtain a concise bounded finding or record the evidence gap. Keep findings in the canonical document by default. Separate an attachment only when a real consumer, sensitive detail, or unwieldy source format requires it; retain the summary and stable reference in `REFINEMENT.md`.

## Draft and close

Use [references/refinement-format.md](references/refinement-format.md) as the content outline. Define normative decisions and acceptance criteria once, with stable IDs; write each decision, criterion and risk as its own level-3 item `### <ID> <title>` with the labelled body fields listed under "Refinement items". Trace each criterion to evidence and affected unit(s); define dependencies and shared-file ownership/order. Include only concise evidence needed for an operator to decide and for future unit plans to consume.

Prepare the stabilized draft in memory or a temporary feature-local scratch snapshot. Do not require legacy SDD validators, scorecards, or quality checklists. Invoke `integrated-delivery-review` for the required feature-level cold reader and critic review before canonical write. The review roles receive only their contracted inputs and do not edit or spawn. If a required reviewer is unavailable, offer the explicit bypass choice through the host's question component; do not treat absence as a bypass. An explicit bypass is recorded with its reason when supported; unresolved B/I still block.

Map every finding to a disposition. B/I findings require correction and targeted re-review, or an evidence-backed contest; MINOR requires a reasoned disposition. Re-review changed normative content and affected context. Do not use a fixed round count or claim that review is isolated unless the host proves it.

Present the exact canonical path, concise scope/unit summary, unresolved material gaps, review outcome, and approval identity. List the material decisions and any sensitive exceptions as numbered items, each with its ID and source, so the single approval can be traced item by item. Ask once for explicit approval of the displayed content; that approval authorizes writing it to the canonical path and does not authorize implementation, cadence choice, Git, or publication (see the decisions table in `../_shared/integrated-delivery/EXECUTION.md`). Do not add a separate content or write-authorization gate. If content or a declared material input changes, re-review the affected content and obtain fresh approval (focused-amendment rule: "Focused amendment" in `references/refinement-format.md`; approval reset: item 10). After writing the approved refinement, stop: the coordinator starts planning in a separate eligible transition.

Approval state lives only in the single APPROVAL block (`references/refinement-format.md` item 10; fields in `../_shared/integrated-delivery/SCHEMAS.md` section 6.3). Create the block as `pending` in the draft. Set `state` to `approved` only after the operator approves the exact normative content, with `identity` equal to that content's normative identity and `input_identity` from the declared inputs. Never record approval as normative prose. The coordinator records the state change with `scripts/ledger/Set-DeliveryExecutionBlock.ps1 -Block APPROVAL` and the current payload hash as `-ExpectedBlockHash`; the script accepts a REFINEMENT.md under `features/` (its parameter is named `-PlanPath`), replaces an existing block only, and fails on any change to the normative identity. Insert the initial pending block with the draft. On a normative change to an approved block, apply the `approved` -> `pending` transition in `../_shared/integrated-delivery/SCHEMAS.md` section 6.3 and record a new approval; use `superseded` only when the approval is withdrawn or the document is replaced.

## Required output behavior

- Single source of truth at `features/NNN-slug/REFINEMENT.md`.
- Language follows operator/repository conventions; stable IDs and paths stay portable.
- No full Q&A history, raw specialist/reviewer transcripts, duplicated PRD, separate criteria file, or default `ANALYSIS/`, `ARCH/`, `SEC/`, `STORY.md`, or `CONTINUITY.md` tree.
- Facts, inferences, assumptions, gaps, and operator decisions remain visibly distinct.
- Record each platform, API, SDK or integration constraint that shapes a decision with its primary source, version or date, a verifiable statement of the constraint, and open uncertainties; an unsourced constraint that affects a decision is a material gap, not an assumption.
- Verify material external facts against current primary sources when possible. Label facts, repository observations, inferences, assumptions, and gaps distinctly; include enough source detail for a reviewer to recheck a claim, and date volatile facts.
- Never claim approval, successful review, host isolation, or validation that was not observed.

## Lazy-load

| When | Path |
|---|---|
| Every refinement | `../_shared/integrated-delivery/FLOW.md`, `DOCUMENTS.md` |
| Entering or resuming the cold-review gate | `../_shared/integrated-delivery/REVIEW.md`, `EXECUTION.md`, `../integrated-delivery-review/SKILL.md` |
| Drafting the canonical document | `references/refinement-format.md` |
| Resolving an identified material specialist signal | Only the matching specialist capability and its declared evidence paths |

**Never by default:** do not preload all shared contracts, every feature artifact, raw conversations, all specialist references, or the entire Memory Bank. Load only the contract and evidence needed for the current refinement decision.
