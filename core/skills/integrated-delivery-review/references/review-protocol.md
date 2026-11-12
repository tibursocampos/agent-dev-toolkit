# Review protocol

## Eligible target and stage

| Target kind | Stage |
|---|---|
| `REFINEMENT.md` | `delivery_refinement_review` |
| `PLAN.md` | `delivery_unit_plan_review` |

The target path is the intended repository-relative canonical file under the selected feature. Review the exact stabilized draft, whether it is held in memory or a temporary snapshot; the review record binds to the intended canonical path and draft bytes. When the record writer needs an on-disk snapshot before the canonical file exists, pass `SnapshotPath` under that feature's `scratch/delivery-review/` directory and remove the temporary snapshot after the review record is saved. Store the durable record under that feature's local ignored `delivery-reviews/` directory. Never store reviewer transcripts in scratch unless needed as concise evidence.

## Reviewer output and record assembly

Each reviewer's final message is one JSON object, defined by `../../_shared/agents/prompts/cold-reader.md` and `cold-critic.md`. The reader returns `paraphrases`, `lenses`, and `findings`; the critic returns `lenses` and `findings`. Finding IDs are `R<round>-<nnn>` for the reader and `C<round>-<nnn>` for the critic, with the round taken from the handoff (default 1) and never reused across rounds. `scripts/runtime/New-DeliveryReviewRecord.ps1` assembles the record from those outputs, maps `location` to `section`, normalizes severity, and lists undisposed finding IDs; it requires `-RepoPath`, confines `-OutPath` to `features/NNN-slug/scratch/delivery-review/`, and checks record shape with the library; identity validation remains the writer's responsibility. Optional `-RequestedModel` and `-RequestedEffort` (given together) fill `provenance` only when the host reports the requested pair; the record never claims an effective model.

## Identity and convergence

Identity is the normative projection of the document plus ordered material-input tuples (portable path, recomputed SHA-256, role, impacted IDs). Projection and marker rules are defined in `../../_shared/integrated-delivery/SCHEMAS.md` (sections 1 and 4) and implemented in `scripts/_lib/DeliveryGrammar.ps1`.

Each review round returns the full findings set and covered lenses. On re-audit, include prior findings, changed normative content, and affected context. A finding first found in unchanged content is `late`. Keep open B/I blocked until evidence-backed resolution or contestation. MINOR requires explicit disposition and reason. Convergence has no fixed round/call budget.

## Re-audit handoff

A re-review passes `round` (>= 2) and `prior_review_identity` (the 64-character uppercase identity of the previous round's review).

- Reader: the exact current target only, as in a first round. No prior findings and no previous snapshot.
- Critic: the re-audit handoff, which is:
  1. Previous snapshot and current snapshot, or a verifiable diff.
  2. The complete list of prior findings with dispositions, justifications and evidence.
  3. The affected context.

The handoff is a declared input, not author conversation. Isolation limits are unchanged: no author chat and no reader result. The critic sets `late` and `repeats`; a repeated finding is not counted as new.

## Evidence package

The author may attach a concise evidence package (glossary, term origins, cited sources, verification results) as a declared input with role `evidence_package`, identified like any other input. It is not author conversation.

## External inputs

An input may cite a controlled external source by its `alias:<name>` path, with an optional `source` object (`SCHEMAS.md` section 10.3). Never pass a private root. When any input uses an alias, the coordinator passes `-AliasCatalogPath` to `Write-DeliveryReviewRecord.ps1`, `Test-DeliveryReviewRecord.ps1`, and the plan preflight. A source that cannot be verified blocks with `input_source_unavailable`. One `InputsPath` entry per kind:

```json
[
  { "id": "IN-01", "path": "alias:brief/source.md", "role": "reference", "impacted_ids": ["CA-001"], "source": { "kind": "file" } },
  { "id": "IN-02", "path": "alias:brief/specs", "role": "reference", "impacted_ids": ["CA-002"], "source": { "kind": "fileset", "files": ["a.md", "tables/b.md"] } },
  { "id": "IN-03", "path": "alias:legacy-api", "role": "evidence_package", "impacted_ids": ["D-004"], "source": { "kind": "revision", "revision": "0123456789abcdef0123456789abcdef01234567" } }
]
```

A repository-relative plain file omits `source`. The builder (`New-DeliveryReviewRecord.ps1`) only passes alias paths and `source` through unchanged and never resolves them; verification belongs to the writer, the gate, and the preflight.

## Optional finding fields

Besides `id`, `severity`, `category`, `section`, `evidence` and `recommendation`, a finding may carry `late` (boolean) and `repeats` (prior finding id). Category `EVIDENCE_GAP` applies to a claim, term or origin that cannot be verified from the declared inputs. Example critic output on round 2:

```json
{"lenses":["consistency"],"findings":[{"id":"C2-003","severity":"I","category":"CONTRADICTION","section":"3","evidence":"...","recommendation":"...","late":true,"repeats":"C1-002"}]}
```

`scripts/runtime/New-DeliveryReviewRecord.ps1` gains `-Round`, `-PriorReviewIdentity` (required when round >= 2) and `-RoundsPath` (cost entries). Its output gains `late` and `repeats` counts. Budget checks use `Test-DeliveryReviewBudget.ps1` on the coordinator summary; it does not change any finding.

## Review and validation consolidation

| Existing purpose | New-flow handling | Boundary |
|---|---|---|
| Functional critique and bias/assumption challenge (M12, M21) | Include explicit functional outcome, scope, evidence, and assumption lenses in the critic assignment; keep every finding traceable and dispositioned. | Do not erase contestation or convert an unsupported claim into a resolved finding. |
| Requirement review (M13) | Invoke only when triage identifies a material uncovered functional/technical gap; do not repeat a question already represented and answered in the current review. | Conditional routing, not globally removed. Security triage remains. |
| PRD/PLAN cold review (M22, M28) | Use reader plus critic at the new refinement and unit-plan gates. | No separate legacy structural/content-validation gate is required. |
| Plan author consistency and handoff checklist (M26, M27) | Consolidate the useful traceability into the single canonical plan; no separate task checklist. | Legacy SDD validators and quality checklists are not prerequisites for this flow. The cold review checks the plan's material coherence; operational state is checked only as needed to execute and resume safely. |
| Architecture/security review (M08, M30) | Keep specialist review conditional on its signal; security is always triaged. | A generic cold critic does not replace specialist coverage. |
| QA checklist, code review, run-tests, pre-commit (M31 and closure candidates) | Preserve existing closeout obligations unless a later measured equivalence is approved. | Stage 4 does not claim these controls are redundant or removed. |

This is an integration policy for the new experimental flow. It does not rewire or disable existing SDD/O1/O2 skills. Their validators and content gates do not become prerequisites in this flow.

## Host limits

Fresh contexts are not proof of filesystem isolation. Record the host, requested/effective capabilities if observable, and the actual evidence for restrictions. Codex context-only is explicitly a context boundary, not tool or filesystem enforcement. If review is unavailable, offer bypass; without explicit operator choice the record remains `not_run`. A bypass records the reason and evidence and cannot resolve B/I.
