## PLAN update protocol

After the step’s code and targeted tests pass, edit the PLAN file in place (repo or global path).

### 1. Step block

Update the completed step section:

| Field | Value |
|-------|--------|
| Heading marker | Change `⏳` to `✅` in the step heading (optional) |
| **Status:** | `Completed` |
| **Completed:** | `YYYY-MM-DD` |
| Notes | Short bullet list: what was done, test count, caveats |

Example:

```markdown
### ✅ STEP 1: Add domain property

**Status:** Completed | **Completed:** 2026-05-21 | **Deps:** none

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
- Session ended at context ≥ 40% **before** PLAN write - still write PLAN with **In progress** or leave Pending and note partial work in notes

### 8. Recovery

If a session crashed mid-step: set **Status:** `In progress`, list files touched in notes, resume in a new chat with the same step number.

---
