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

**Status:** Completed | **Completed:** 2026-05-21 | **Deps:** none | **Token budget:** ~20k | **Time:** 30 min

**Implementation notes:**
- Added nullable property and setter validation on Entity
- 3 unit tests: `Should_*_When_*` pattern
- `dotnet build` and filtered `dotnet test` passed
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

### 5. Objectives (optional)

If an objective (O1, O2, …) is fully satisfied by this step alone, mark its checkbox `[x]`.

### 6. When not to mark Completed

- Build or targeted tests still failing
- User chose not to commit and step acceptance requires pushed commit (rare - note in PLAN)
- Dependency steps incomplete
- Session ended at context ≥ 40% **before** PLAN write - still write PLAN with **In progress** or leave Pending and note partial work in notes

### 7. Recovery

If a session crashed mid-step: set **Status:** `In progress`, list files touched in notes, resume in a new chat with the same step number.

---
