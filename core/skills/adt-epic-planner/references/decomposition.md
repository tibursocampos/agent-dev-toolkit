# Feature decomposition

## Shape outcomes, not layers

Create a coherent shared initiative outcome, goals or signals of success, and candidate features. A feature should describe a recognizable outcome, capability, journey, or meaningful increment—not a UI/API/database/infrastructure layer. For greenfield work, include setup in the first outcome that needs it unless an independent obligation justifies a separate feature.

For each proposed boundary, ask whether the outcome has meaningful value on its own, what depends on it, and whether the cut hides a distinct user or operator result. Independent delivery is useful evidence, not an absolute rule: genuine outcome dependencies are valid. Distinguish a real prerequisite from association, preference, or commercial priority. Order features by known dependency and explain material sequencing.

Respect a coherent structure the user proposed. If it cuts across layers or combines distinct outcomes, explain the consequence and offer an alternative. Do not set universal limits on features, stories, criteria, or effort. If the initiative contains unrelated beneficiaries or outcomes with no useful shared direction, suggest separate EPICs with a reason; do not split automatically by a numeric threshold.

## Proportional detail

Every EPIC must preserve enough context to resume discovery: problem and relevant actors; desired outcome and plausible success signals; scope, constraints and non-goals; feature map and grouping rationale; and for each feature, outcome/value, preliminary boundary, known behavior, evidence/references, dependencies and open questions. Decisions belong in their relevant content and may also be indexed in Decisions.

Keep a small initiative concise without reducing it to a bare list. For higher-risk or complex brownfield work, deepen evidence, dependencies, risks, and success criteria. Optional sections may be omitted when they add no value. Do not invent metrics to fill a template. Criteria are candidates only where understanding supports observable statements; they are not a substitute for O1's feature/story work.

## Feature brief for later selection

Each feature brief should make it possible to select it by stable ID and give O1 enough relevant context to begin, without pre-writing O1 analysis. Include as useful:

- outcome and value, including who can do what;
- problem or journey and relevant current behavior;
- preliminary included behavior and boundary from adjacent work;
- non-goals;
- observable candidate criteria, when sufficiently understood;
- dependencies, distinguishing actual precedence from association;
- evidence, risks, and feature-specific questions.

O1 remains authoritative for its `FEATURE.md`, stories, and concrete cut. It may rename, divide, combine, or reorder features after analysis. The user may update the EPIC later; no reconciliation is required.
