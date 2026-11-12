# Triage and routing rules

Use this reference only while establishing or revisiting scope. It operationalizes the Stage 1 contracts without changing their authority.

## Decision sequence

1. State the requested outcome in one sentence and identify observable success evidence.
2. Separate known facts, operator decisions, assumptions, and evidence gaps. Re-read only cited source paths and named relevant Memory Bank files.
3. Identify affected repositories and inspect enough representative code/configuration to ground the scope. Do not conduct a broad inventory without a material question it answers.
4. Derive work units by independently approvable outcomes, affected repositories, dependencies, and shared-file ordering. Do not make a unit per layer, folder, or specialist. Preserve a single unit when it is coherent.
5. Decide whether a feature refinement is needed:
   - Required for multiple units; shared-file ordering; changed shared contracts; or a material decision governing more than one unit / superseding a prior approved decision.
   - Omit for one simple unit with no cross-unit dependency or shared decision. The later `USnn/PLAN.md` or `TSnn/PLAN.md` owns that case's requirements and criteria.
   - `NO_CHANGE` is an evidence-backed repository disposition in the feature refinement, not an artificial implementation plan.
6. Set specialist signals from evidence. Security is evaluated whenever auth, secrets, PII, supply-chain, or trust boundaries appear; ambiguity about such a signal must be surfaced, never silently defaulted away. Route database, frontend, DevOps, API, domain/architecture, or repository-impact analysis only when the listed concern is actually in scope. No signal means no specialist call.
7. Ask only questions whose answers can change objective, scope, acceptance, unit boundaries, shared-file order, security posture, approval identity, or authorized action. Group them by decision, mark blocking vs important, and retain MINOR observations in the canonical document.

## Evidence and specialist handling

Prefer targeted repository evidence and direct source material. Label every conclusion `CONFIRMED`, `INFERRED`, or `GAP`, with source and limitation. A specialist result is evidence, not an operator decision or authorization. Request only a bounded question, relevant paths, the required evidence, and the affected decision/criterion IDs. Specialists return concise findings to the coordinator; no full transcript or separate analysis tree is created by default.

Use an available read-only specialist in a fresh, depth-one context when it materially reduces uncertainty. If the host cannot provide that role, either inspect the bounded evidence in the main context or leave a named gap. Do not claim isolation beyond what the host actually provides. Do not use fallback as a reason to skip required evidence or approval.

## Platform and integration constraints

Signal: a decision depends on an external platform, API, SDK, service, or integration. The triage:
- records the signal with the affected decision or criterion IDs;
- requests a primary source (official documentation, specification, or observed behavior) with its version or date;
- states the constraint verifiably and lists its open uncertainties; the specialist request carries these fields too;
- names a missing source for a constraint that affects a decision as a material gap in the triage output, never as an assumption.

## Minimum pre-plan readiness

Before routing to a planning stage, verify:

- target repository and feature storage are unambiguous and readable;
- material decisions needed for the selected unit are resolved;
- unit boundaries and shared-file dependencies are traceable when refinement is required;
- evidence needed to draft criteria and plan steps is available or explicitly marked as a gap;
- no stale approval or declared input identity is being carried forward.

If any item fails, stop only the dependent transition and report the missing evidence or decision. Do not manufacture a feature scaffold to make an incomplete demand appear ready.
