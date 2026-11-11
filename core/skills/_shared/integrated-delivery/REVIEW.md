# Integrated delivery review contract

Status: Stage 1 design contract for proportionate independent review and safe convergence.

## Required review points

1. One reader and one critic review the feature refinement after boundaries, decisions, evidence and unit definitions stabilize, before feature approval.
2. One reader and one critic review each unit/repository plan before plan approval and implementation.
3. After corrections, re-evaluate each prior finding and changed content with its affected context. A change to normative content or a declared input creates a new review identity; operational-only progress updates do not.

The cold reader and critic review the stabilized draft. Do not require legacy SDD draft validators, scorecards, or content-quality checklists as prerequisites. A targeted existing review may be used when it answers a material gap; it does not add a duplicate approval gate. The local Stage 1 comparison matrix is an experiment record, not a runtime prerequisite.

## Reviewer roles and input limits

- **Reader:** receives the exact target artifact only, produces two independent paraphrases before findings, then reports comprehension gaps and B/I/MINOR findings with location, evidence, and recommendation. It must not consult other artifacts.
- **Critic:** receives the exact target plus only the approved, material references needed to check consistency and evidence; it identifies contradictions, ambiguity, missing observable outcomes, and scope drift.
- Each reviewer uses a fresh context for every review. Neither edits files, spawns agents, or writes the durable review record.
- Host/tool restrictions are recorded as observed. Codex context-only roles do not prove filesystem isolation; report that limitation accurately.

## Finding disposition and convergence

- **B** and **I** block approval until corrected and re-reviewed, or contested with evidence available to the reviewer. Escalation alone does not resolve them.
- **MINOR** requires explicit disposition and reason; it does not block unless it exposes an unresolved material decision.
- The reviewer returns the complete findings set and lenses covered. The coordinator maps every finding to a disposition and evidence.
- Recheck prior findings plus changed material and affected context. New findings in unchanged content are marked late; both B and I block until corrected and re-reviewed or contested with evidence. Do not silently accept an I finding.
- Convergence occurs when no unresolved B/I remain and every MINOR has a disposition. For example, a corrected blocking finding is not closed until the reviewer checks the correction and affected context; a MINOR is closed by recording a reasoned disposition; changing a criterion invalidates approval and requires the affected review again. Do not use a fixed round count as a quality proxy. Record calls, elapsed time, findings, corrections, and outcome for the comparison protocol.
- If Goldfish is unavailable, stop and offer explicit operator bypass with reason. Without that choice, status remains `not_run`. Bypass never resolves B/I or approves content.

## Durable record

The coordinator alone writes a `delivery-review-record/v1` record under the reviewed target feature's local `features/NNN-slug/delivery-reviews/` directory, outside Git. Required fields:

| Field | Meaning |
|---|---|
| `schema` | `delivery-review-record/v1` |
| `target` | Portable path, artifact kind, review stage, exact content identity |
| `inputs[]` | Declared material input ID/path, hash or immutable revision, role and impacted IDs |
| `reviewers.reader` / `reviewers.critic` | Structured role result; reader has both paraphrases, each role has covered lenses and a complete findings array, including empty when none; host and observed isolation |
| `state` | `reviewed`, `bypassed`, or `not_run` |
| `dispositions[]` | Finding ID/severity, corrected, contested, accepted minor, or unresolved; evidence and reason |
| `operator_choice` | Required for a review bypass; choice, date, evidence reference |
| `provenance` | Requested model/effort and effective values only if host reports them |

Writer recalculates normalized content and input hashes, validates target/stage identity and schema, rejects unresolved B/I or findings without dispositions, and writes atomically under the feature's local `delivery-reviews/` directory. `reviewed` requires valid structured outputs from both roles. `bypassed` requires explicit operator evidence. Missing identity, malformed output, unresolved B/I, or failed durable write leaves the artifact blocked. The record is not cryptographic identity proof and does not independently authenticate operator or host behavior.

## Cost and reporting

Report review purpose, source hash, input hashes, round, calls, findings by severity/disposition, corrections, elapsed time where available, and unavailable measurements. One feature review and one review per unit plan are the intended stabilized points; additional review calls require a reason such as material content change or an unresolved finding. Never claim that a reduced review count is safe without coverage evidence from the Stage 1 matrix and representative tests.
