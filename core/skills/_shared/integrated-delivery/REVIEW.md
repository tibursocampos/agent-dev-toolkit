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
- Recheck prior findings plus changed material and affected context. New findings in unchanged content are marked `late`; both B and I block until corrected and re-reviewed or contested with evidence. Do not silently accept an I finding.
- Convergence occurs when no unresolved B/I remain and every MINOR has a disposition. For example, a corrected blocking finding is not closed until the reviewer checks the correction and affected context; a MINOR is closed by recording a reasoned disposition; changing a criterion invalidates approval and requires the affected review again. Do not use a fixed round count as a quality proxy. Record calls, elapsed time, findings, corrections, and outcome for the comparison protocol.
- A draft review is bound to the exact bytes in the feature-local snapshot and the intended canonical target path. Before presenting a draft for approval, validate that exact snapshot with the target's applicable preapproval preflight (including declared-input identity); a successful review record does not replace preflight. After approval, write only the displayed content to the canonical path and verify its identity. Any normative edit after review or approval requires a fresh affected review and approval.
- If Goldfish is unavailable, stop and offer explicit operator bypass with reason. Without that choice, status remains `not_run`. Bypass never resolves B/I or approves content.

## Durable record

The coordinator alone writes a `delivery-review-record/v2` record under the reviewed target feature's local `features/NNN-slug/delivery-reviews/` directory, outside Git. Read-only compatibility for unapproved v1 records is retained; an approved v1 record fails closed and must be regenerated from the reviewed draft and approved again. Required fields:

| Field | Meaning |
|---|---|
| `schema` | New records use `delivery-review-record/v2`; v1 review records retain legacy review-only compatibility, but an approved v1 record is rejected because approval is not bound to reviewer results and dispositions |
| `target` | Portable path, artifact kind, review stage, exact content identity, and record binding identity in v2 |
| `inputs[]` | Declared material input ID/path, hash or immutable revision, role and impacted IDs; an author evidence package uses role `evidence_package`. An external input cites its `alias:<name>` path and an optional `source` (`file`, `fileset`, `revision`); see `SCHEMAS.md` section 10.3 |
| `material_input_identity` | v2 set identity over current material input IDs, paths, hashes, roles and impacted IDs |
| `reviewers.reader` / `reviewers.critic` | Structured role result; reader has both paraphrases, each role has covered lenses and a complete findings array, including empty when none; host and observed isolation |
| `state` | `reviewed`, `bypassed`, or `not_run` |
| `dispositions[]` | Per finding ID: `resolved`, `contested`, or `accepted_minor`, with evidence for B/I and a reason for MINOR; a finding without a disposition entry is unresolved and blocks. |
| `operator_choice` | Bypass: `operator_choice` with choice `bypass`, evidence and date, plus a top-level `reason`; content approval is recorded separately under `approval.operator_choice` with choice `content_approval` and evidence. |
| `provenance` | Requested model/effort and effective values only if host reports them |
| `round` / `prior_review_identity` | Optional round (integer >= 1). `prior_review_identity` (64 uppercase hex) is required when round >= 2 and absent otherwise |
| `rounds[]` | Optional cost entries `{round, role, inputs, reported_tokens, reported_tool_calls, duration_s}`; host-reported figures only, `null` means unknown |

Writer recalculates normalized content and input hashes, validates target/stage identity and schema, binds the v2 record identity to review state, reviewer results, findings, dispositions and material-input identity, rejects unresolved B/I or findings without dispositions, and writes atomically under the feature's local `delivery-reviews/` directory. `reviewed` requires valid structured outputs from both roles. `bypassed` requires explicit operator evidence. Missing identity, malformed output, unresolved B/I, or failed durable write leaves the artifact blocked. An external input the source machinery cannot verify blocks with `input_source_unavailable`. The record is not cryptographic identity proof and does not independently authenticate operator or host behavior.

## Cost and reporting

Report review purpose, source hash, input hashes, round, calls, findings by severity/disposition, corrections, elapsed time where available, and unavailable measurements. One feature review and one review per unit plan are the intended stabilized points; additional review calls require a reason such as material content change or an unresolved finding. Never claim that a reduced review count is safe without coverage evidence from the Stage 1 matrix and representative tests.

## Re-audit and cost control

- Only the critic receives the re-audit handoff: the previous and current snapshots (or a verifiable diff), the complete list of prior findings with dispositions, justifications and evidence, and the affected context. The reader re-reads only the current target, with no prior findings. The handoff is a declared input, not author conversation; isolation limits are unchanged.
- The critic sets `late` (true when the concern is in text unchanged since the previous round) and `repeats` (id of the prior finding it repeats; a repeat is not new). The builder accepts both from either role. Either role may raise category `EVIDENCE_GAP` (a claim, term or origin not verifiable from the declared inputs); it is not an invented defect and resolves when evidence is attached in a later round or is contested.
- Critic inputs each carry a stated reason and are read by section or symbol where possible. The author may attach an evidence package as role `evidence_package`.
- The coordinator keeps a summary `{ rounds:[{round, blocking_open, reported_tokens, input_bytes}] }` and runs `Test-DeliveryReviewBudget.ps1 -SummaryPath <file> [-StallRounds 2] [-MaxTokens n] [-MaxInputBytes n]` after each round. The helper is read-only: exit 0 continues; exit 3 (`no_convergence`, `token_budget_exceeded`, `input_budget_exceeded`) stops the coordinator and consults the operator before any further review call; exit 1 is an error. `no_convergence` includes a flat, rising, or oscillating recent window with no net reduction in open B/I.
- Preserve each round's exact reviewer JSON, snapshot/diff, dispositions and rationale, handoff, and budget summary under feature-local `scratch/delivery-review/` using distinct round-specific names. Do not overwrite prior round evidence. The final durable record binds to the final review; earlier round artifacts remain available to verify convergence and reported cost.
- Escalation reports open B/I findings, accumulated cost and the options: continue, contest with evidence, adjust scope, or bypass (only when a reviewer is unavailable). Continue is an operator decision, not an automatic retry. Neither the helper nor the escalation closes or resolves a finding. There is no round cap that ends the review.
