## PLAN update protocol

Mark `IN_PROGRESS` and re-read the PLAN before editing code. On failure, set `BLOCKED` with the evidence and leave dependents `PENDING`. Resume `BLOCKED` only when that evidence is no longer in the file. `COMPLETED` only with this step's acceptance and tests. No duration.

After the step’s code and targeted tests pass, edit the PLAN file in place (repo or global path).

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
- Session ended at context ≥ 40% **before** PLAN write - still write the PLAN with **Status:** `IN_PROGRESS` or leave `PENDING` and note the partial work

### 8. Recovery

If a session crashed mid-step: set **Status:** `IN_PROGRESS`, list files touched in notes, resume in a new chat with the same step number.

### 9. Single edit

One edit covers the `Implementation progress` ledger (status and evidence; keep `Analysis weight`), the step glyph (`☑` when `COMPLETED`), the matching `- [x]` boxes in `REFINE/tasks.md`, the counters, and the checkpoint. In `step_by_step`, the chat before the edit is the narrative summary, what the PLAN says to do, and the blocking question (`execution-display.md`). When the step closes, show that ledger for every step and those boxes. Do not show the stage-weight table, redraw it, emit `Develop:`, or dump the ledger. Re-read the file. If it changed in the middle of the edit, stop. Do not merge by guess. If the checkpoint branch or commit does not match, stop and do not zero the progress. A `BLOCKED` step returns only when the block evidence is no longer in the file. A plan whose implementation status is `COMPLETED` does not restart without an explicit request.

For O3 closure, receipt validation precedes this persistence. After saving, re-read the PLAN before showing the step ledger and the short result. Only then may the orchestrator evaluate the next spawn; `continuous` retains its authorization after this sequence, while `step_by_step` still requires confirmation per spawn. A receipt `status` outside `done`, `blocked`, and `failed`, or an implementation outside the PLAN acceptance, blocks the step, asks the deviation, and does not delegate the next step. Do not invent a fix and do not rewrite the PLAN. A missing, incomplete, inconsistent, blocked, or failed receipt leaves the step pending/blocked and dependents paused.

### 10. Companion PRD when Implementation status is COMPLETED

When this edit sets the PLAN header **Implementation status** to `COMPLETED` (every step `COMPLETED` or `SKIPPED`, progress `N/N`), close the cited PRD in the same edit.

1. Read the portable path in the PLAN metadata row `**PRD**`. If the row or the file is absent, say so in the session report and do not invent a PRD.
2. Set that PRD metadata **Status** to `Implementado` when the PRD prose is pt-BR, or `Implemented` when it is English. Leave acceptance criteria, scope, and requirements unchanged.
3. In `## Definição de pronto` or `## Definition of done`, check only the boxes whose text is implementation alignment, tests or fixtures, and build or structural validation. Leave spec-quality boxes (REQ coverage, explicit OOS) as they already are.
4. If `## Histórico de alterações` or `## Change history` exists, append one row: today's date, the next version number, `sdd-develop`, and that the PLAN **Implementation status** reached `COMPLETED`.
5. If the PLAN is already `COMPLETED` and the PRD status is still `Pronto para planejamento` or `Ready for planning`, apply this close once. That repair is not a restart of implementation.

`/code-review` and `/commit` do not write this status. A review that finds PLAN `COMPLETED` with PRD still `Pronto para planejamento` / `Ready for planning` flags the drift and hands the close back here.

---
