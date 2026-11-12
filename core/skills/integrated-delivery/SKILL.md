---
name: integrated-delivery
description: >-
  Experimental, opt-in coordinator for the integrated feature-to-code delivery flow. Triages a demand, identifies the next eligible stage, asks material questions, and routes to refinement or a unit plan. Use when the operator invokes integrated-delivery; existing SDD and O1/O2/O3 flows remain separate.
---

# Integrated delivery coordinator

This is the single user-facing entry for the experimental flow. It runs in the main context and coordinates one transition at a time. Start with a concise status; update it only when the current stage or a material decision changes. Do not produce parallel status tables or repeat unchanged progress.

## Load only what this transition needs

1. Read `../_shared/integrated-delivery/FLOW.md` and `DOCUMENTS.md` before routing or writing. Before any delegation, read `../_shared/integrated-delivery/STARTUP.md`.
2. Read `EXECUTION.md` only when checking approval, resume, or execution state. Read `REVIEW.md` only before a required review or when reconciling findings.
3. Read the active repository's relevant instructions and only named Memory Bank files that could affect the demand. Do not dump the Memory Bank or unrelated SDD references into context.
4. For triage and question grouping, read [references/triage.md](references/triage.md).
5. Invoke `integrated-delivery-review` at stabilized refinement and per-unit plan gates, or when re-evaluating changed material and affected context.

The flow is experimental and opt-in. Do not claim an adapter, validator, reviewer, or runtime capability is available unless this session exposes it and it was observed working. A skill not yet installed is a future transition, not an executable tool.

## Each invocation

1. Resolve the workspace root and inspect the target feature's existing canonical artifacts. Preserve the current branch and all unrelated work. Do not allocate a feature folder until the repository's existing storage convention is understood and the operator's demand warrants persisted artifacts.
2. Precheck the environment before planning: confirm the intended repository is open, its local instructions and relevant source paths are readable, current feature storage can be resolved, and there is no apparent path/permission blocker. This is a lightweight readiness check, not a build or proof of host capabilities. Report its result in one line: `environment OK`, or `blocked: <exact blocker>`.
3. Determine the next state from on-disk evidence, not conversation memory alone. Follow `FLOW.md`. Never infer an approval from a review result, a prior session, or a file's presence.
4. Triage objective, scope, exclusions, affected repositories, complexity, risks, unit boundaries, material specialist signals, and platform or integration constraints (see `references/triage.md`). Reuse information already supplied or evidenced; ask only for unresolved material decisions. Batch blocking and important questions, at most five per batch. Use the host's native question component when available; do not ask these as unstructured prose. List the recommended option first on every question, with a one-line reason; if the operator accepts the defaults, the recommended options close the whole batch. Record MINOR observations without interrupting unless they expose a material gap.
5. Before routing, announce the classification (simple unit or multi-unit) with a one-line reason and the canonical path that will be written. This is an announcement, not a gate; the operator may object. Route only the current eligible stage. A simple single-unit demand goes directly to the unit-plan stage when available; do not create a `REFINEMENT.md`, story, PRD, task checklist, or feature scaffold solely for formality. If the plan stage is unavailable, report that exact next step and stop without simulating its output.
6. For multi-unit work, shared files, changed shared contracts, or superseded material decisions, invoke `integrated-delivery-refine` when available. It writes the canonical feature refinement and stops at the required review/approval gate. Do not start unit planning in the same invocation after that gate.
7. Invoke domain specialists only for a material signal identified by the triage rules. Use available depth-one read-only specialist capability; specialists do not spawn other agents. If unavailable, do targeted analysis in the main context or record the evidence gap. Do not create empty folders or separate notes by default. Keep concise findings, evidence, confidence, limitations, and affected IDs in the canonical refinement.
8. Consult Memory Bank content only if this repository has one and a named file is relevant to a material decision or accepted convention. Cite the exact file/section and distinguish it from current repository evidence.
9. Before each write, state the intended canonical path and ensure the content remains inside the selected feature/repository storage. Ask the operator only when a material decision or required action authorization is missing; otherwise continue the authorized documentation work.

## Invocation without a demand

When invoked with no demand text, do not open a questionnaire. After the precheck, read the on-disk state and show it in one line (for example: feature `NNN-slug` has an approved refinement and 2 of 3 unit plans pending). Offer only the next actions that state allows, the recommended one first with a one-line reason. If nothing exists on disk, ask a single question: the observable objective of the demand.

## Routing and stop conditions

- `REFINEMENT.md` required and absent/draft → `integrated-delivery-refine`.
- One simple unit, no cross-unit decision → `integrated-delivery-plan` directly, if installed.
- Approved refinement and pending unit → `integrated-delivery-plan`, if installed.
- Approved plan and implementation requested → `integrated-delivery-implement`, if installed; implementation authorization and cadence are checked there.
- Missing/stale artifact, invalid approval, unresolved material decision, unavailable required review, unreadable input, or failed precheck → stop the affected transition and identify the exact blocker and next action.
- Never perform Git or publication actions, implement code, silently widen scope, or convert a specialist inference into an approved requirement.

For the concrete unit-boundary, materiality, question, and conditional-specialist rules, use [references/triage.md](references/triage.md). The canonical document and approval rules in shared contracts take precedence over this router.

## Coordinator conduct

- Report progress only on a stage change, a material decision, or a block. No waiting turns and no repeated partial reports of the same child.
- Amend documents by focused patches. Rewrite a whole document only with a reason stated in the stage summary.
- Present decisions as numbered items per `../_shared/agents/QUESTIONS.md` and the question rules in `../_shared/integrated-delivery/FLOW.md`.
- Choose a subagent model and effort pair by role under `../_shared/agents/SUBAGENT-MODEL.md`. Record the requested pair in the review record with `-RequestedModel` and `-RequestedEffort`. Never claim an effective model or isolation the host did not report.

## Lazy-load

| When | Path |
|---|---|
| Every routing transition | `../_shared/integrated-delivery/FLOW.md`, `DOCUMENTS.md` |
| Checking approval, resume, or execution state | `../_shared/integrated-delivery/EXECUTION.md` |
| Before a required review or reconciling findings | `../_shared/integrated-delivery/REVIEW.md` and `../integrated-delivery-review/SKILL.md` |
| Triage or question grouping | `references/triage.md` |
| Writing or resuming a feature refinement | `../integrated-delivery-refine/SKILL.md` |
| Writing or resuming a unit plan | `../integrated-delivery-plan/SKILL.md` |
| Implementing an approved plan | `../integrated-delivery-implement/SKILL.md` |

**Never by default:** do not load every stage skill, all shared contracts, all feature artifacts, or the full Memory Bank. Load only the active transition's skill and contract; retrieve other context only when that transition declares it.
