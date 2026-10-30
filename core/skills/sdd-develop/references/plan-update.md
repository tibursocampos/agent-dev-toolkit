## PLAN update protocol

Mark `IN_PROGRESS` and re-read the PLAN before editing code. On failure, set `BLOCKED` with the evidence and leave dependents `PENDING`. Resume `BLOCKED` only when that evidence is no longer in the file. `COMPLETED` only with this step's acceptance and tests. No duration.

After the step’s code and targeted tests pass, edit the PLAN file in place (repo or global path). Persist at the end of the step before handoff.

### 1. Step block

Update the completed step section:

| Field | Value |
|-------|--------|
| Heading marker | Change `⏳` to `✅` in the step heading (optional) |
| **Status:** | `COMPLETED` |
| **Completed:** | `YYYY-MM-DD` |
| Notes | Short bullet list: what was done, test count, caveats |

Example:

```markdown
### ✅ STEP 1: Add domain property

**Status:** COMPLETED | **Deps:** none

**Implementation notes:**
- Added nullable property and setter validation on Entity
- 3 unit tests: `Should_*_When_*` pattern
- `dotnet build` and filtered `dotnet test` passed
- (delivery-baseline — no duration/effort estimates; see `plan-contract.md`)
```

### 2. Deliverables and acceptance

- Check `[ ]` -> `[x]` for deliverables and acceptance items **fully** met by this step only.
- Each checked **Aceite** line must map to a cited **REQ-NNN** and/or CA from the step block; do not check REQ items owned by later steps.
- Do not check items owned by later steps.

### 3. Progress header

Update the table near the top:

```markdown
| **Progress** | 1/6 |
```

Progress bar (adjust emoji count to total steps):

```markdown
[🟢⚪⚪⚪⚪⚪] 17% (1/6)
```

### 4. Next step line

Under **Execution order** or equivalent:

```markdown
**Next step:** STEP 2 - [short title from PLAN]
```

### 5. Navigation `## Related` (006 REQ-009 — not 007 develop pacing)

When editing the PLAN (and PRD only if this step touches it):

- Preserve section title `## Related` (never `## See also`).
- If both PRD and PLAN exist on disk: keep/refresh **mutual** portable-path cites under Related.
- Cite STORY / FEATURE / CONTINUITY / ARCH… only when on-disk (**omit-if-absent** — never stub).
- Normative shape: `STORAGE.md` § Navigation block.

### 6. Objectives (optional)

If an objective (O1, O2, …) is fully satisfied by this step alone, mark its checkbox `[x]`.

### 7. When not to mark Completed

- Build or targeted tests still failing
- User chose not to commit and step acceptance requires pushed commit (rare - note in PLAN)
- Dependency steps incomplete
Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 8. Recovery

If a session crashed mid-step: set **Status:** `IN_PROGRESS`, list files touched in notes, resume in a new chat with the same step number.

#### Partial reopen

- A `COMPLETED` step reopened for material rework returns to `IN_PROGRESS` (or `BLOCKED` with evidence) and records the reason in its notes.
- Reconcile the evidence that depends on the reopened step: mark dependent acceptance and evidence as pending until re-proven.
- Preserve evidence that stays independent of the reopened step and remains applicable.
- Dependent steps that already passed stay `COMPLETED` only if their own acceptance still holds; otherwise set them to `PENDING` with the cause.
- Completing one step never closes the PLAN while any later step is `PENDING` or `BLOCKED`.

### 9. Single edit

The `sdd-develop` session that executes a step is the sole writer of that step's `Implementation progress` row, status/evidence, checkpoint, and permitted related boxes. In O3, the parent validates the child's persisted checkpoint read-only and never rewrites the same step; it may update its separately owned `CONTINUITY.md` synthesis. One edit covers the owned PLAN fields and only checklist fields applicable to the resolved invocation context: `direct` does not read or write a checklist unless the invocation explicitly adopted a consistently related checklist; `orchestrated` preserves the O3 parent's required scoped inputs and updates only this step's applicable rows. Do not create task rows or a checklist as a fallback. In `step_by_step`, the chat before the edit is the narrative summary, what the PLAN says to do, and the blocking question (`execution-display.md`). When the step closes, show that ledger for every step and applicable task rows only. Do not show the stage-weight table, redraw it, emit `Develop:`, or dump the ledger. Re-read the file. If it changed in the middle of the edit, stop. Do not merge by guess. If the checkpoint branch or commit does not match, stop and do not zero the progress. A `BLOCKED` step returns only when the block evidence is no longer in the file. A plan whose implementation status is `COMPLETED` does not restart without an explicit request.

For O3 closure, receipt validation precedes this persistence. After saving, re-read the PLAN before showing the step ledger and the short result. Only then may the orchestrator evaluate the next spawn; `continuous` retains its authorization after this sequence, while `step_by_step` still requires confirmation per spawn. A receipt `status` outside `done`, `blocked`, and `failed`, or an implementation outside the PLAN acceptance, blocks the step, asks the deviation, and does not delegate the next step. Do not invent a fix and do not rewrite the PLAN. A missing, incomplete, inconsistent, blocked, or failed receipt leaves the step pending/blocked and dependents paused.

### 10. Companion PRD when Implementation status is COMPLETED

When this edit sets the PLAN header **Implementation status** to `COMPLETED` (every step is `COMPLETED`, progress `N/N`, every required validation passes, and explicit whole-PLAN close authorization is present in this invocation or the persisted bounded authorization), close the cited PRD in the same edit. If close authorization is absent, leave the PLAN open and request it separately. A `SKIPPED` step or result cannot count as `COMPLETED` or close the PLAN; reconcile omitted scope through the PLAN owner before closure.

1. Read the portable path in the PLAN metadata row `**PRD**`. If the row or the file is absent, say so in the session report and do not invent a PRD.
2. Set that PRD metadata **Status** to `Implementado` when the PRD prose is pt-BR, or `Implemented` when it is English. Leave acceptance criteria, scope, and requirements unchanged.
3. In `## Definição de pronto` or `## Definition of done`, check only the boxes whose text is implementation alignment, tests or fixtures, and build or structural validation. Leave spec-quality boxes (REQ coverage, explicit OOS) as they already are.
4. If `## Histórico de alterações` or `## Change history` exists, append one row: today's date, the next version number, `sdd-develop`, and that the PLAN **Implementation status** reached `COMPLETED`.
5. If the PLAN is already `COMPLETED` and the PRD status is still `Pronto para planejamento` or `Ready for planning`, apply this close once, only when the persisted close authorization is present. That repair is not a restart of implementation.

`/code-review` and `/commit` do not write this status. A review that finds PLAN `COMPLETED` with PRD still `Pronto para planejamento` / `Ready for planning` flags the drift and hands the close back here.

### 11. Terminal gate lifecycle (strict order)

Finish every implementation/artifact edit, re-read the final artifacts, and complete all required validations first. Only after their results are ready, call `tests-run` once and update the PLAN/task status and evidence while the gate is still active. Then call `reset` as the final operation in this develop scope. Reset clears both gates and is terminal: after a successful reset, do not call any session helper, validator, or make any further file/artifact edit in this scope. If a post-reset correction is necessary, stop and begin a fresh, explicitly authorized develop scope/session with its gate confirmed; never repeat `tests-run` against cleared gates. A failed helper remains a hard stop under the session-helper rule in `SKILL.md` (STOP block).


## Write-consistency rules (SDDW)

Rule ids `SDDW-NN` are contract text only; no repository script validates them. Apply each rule in the same edit that changes the fields it names, then run its reconciliation check before reporting the step or PLAN done.

- **SDDW-02 (PLAN status agreement):** One edit sets the header `Implementation status`, the header `Progresso` (`N/M`, where `N` counts `COMPLETED` step headers and `M` counts step headers), each step `**Status:**`, the sequence rows, the Progresso table row, and the checkpoint. Reconciliation: each table row status equals its step header status; a row is never `PENDING` while its header is `COMPLETED`.
- **SDDW-04 (boxes under COMPLETED steps):** Set a step to `COMPLETED` only after every checklist box that the step acceptance covers is `[x]`. A `COMPLETED` step block keeps no unchecked `- [ ]` box. Boxes owned by later steps stay `[ ]` and do not block the step.
- **SDDW-03 (status rows after PLAN close):** When the PLAN `Implementation status` becomes `COMPLETED`, no PLAN row may still show `IN_PROGRESS` (checkpoint global state, portability row, or any other status row). Set each one to its final value in the same edit.
- **SDDW-01 (REFINE summary):** When a step status changes in `REFINE/tasks.md`, the same edit updates the step header, the group Status cell of the summary table, and the `Progresso` counter (`N/M grupos`). Reconciliation: counter `N` equals the COMPLETED step headers, `M` equals the step count, and each summary row equals its step header and the PLAN step status.
- **SDDW-07 (PRD version):** The companion PRD close (section 10) sets the PRD header `Versão` to the version of the history row it appends, in the same edit. Reconciliation: the header `Versão` equals the last row of `Histórico de alterações`. Criterion, scope, and requirement text stay unchanged in that edit.
---
