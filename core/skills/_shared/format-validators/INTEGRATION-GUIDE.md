# Format Validators - Integration Guide

How to wire validators into agent-dev-toolkit skills (Git-only).

## Overview

```
format-validators
  ├── validate-prd.ps1          -> sdd-spec / sdd-plan (executable PRD structure gate)
  ├── feature-validator.md      -> PRD authoring checklist (non-executable)
  ├── commit-message-validator.md -> commit, code-review
  └── pr-comment-validator.md   -> code-review
```

---

## spec

**Executable gate:** `scripts/validation/validate-prd.ps1`
**When:** After writing PRD and before handoff to `/sdd-plan`; `/sdd-plan` runs it again against its source PRD. `feature-validator.md` is an authoring checklist, not the executable gate. Storage: `sdd-artifacts/STORAGE.md`. Language: content-language per `agents/LANGUAGE.md`.

| Context | Level | Behavior |
|---------|-------|----------|
| PRD generation | script structural gate | Block handoff when required sections, REQ ids, or CA headings are missing |
| Content review | checklist guidance | Review matching locale; the script does not enforce every template section |

---

## commit

**Validator:** `commit-message-validator.md`  
**When:** After user approves message, before `git commit`

1. Validate proposed first line (+ optional body/footer).
2. Reject Cursor `Co-authored-by` trailers (message or `--trailer`) - Rule 4 in validator.
3. If invalid: show issues and `suggestedFix`.
4. Apply user-approved fix; then commit (`git commit -m` only - no `--trailer`).

Also referenced from `developer-common/step-4-commits-pr.md`.

---

## code-review

**Validators:** `commit-message-validator.md`, `pr-comment-validator.md`

**Commits (optional step):**

- Validate each commit in range `base...HEAD`
- Include summary in review report (do not post inline on commits unless user asks)

**Comments (when drafting inline review):**

- Validate each generated comment before posting
- Auto-fix trivial formatting when safe
- Skip comments that fail structural validation

| Mode | Commit validation | Comment validation |
|------|-------------------|--------------------|
| `--blockers-only` | Skip | Structure only |
| default | Type + description | Full |
| `--strict` | + description quality | + language consistency |

---

## developer (shortcut)

**Validator:** `commit-message-validator.md` only (via `step-4-commits-pr.md` when committing).

---

## Best practices

1. **Fail gracefully:** Validator errors should warn, not crash the skill, unless the user requested strict mode.
2. **Progressive levels:** Start with `structure`; increase to `content` / `quality` when stable.
3. **Clear feedback:** Section + problem + expected + actual + suggestion.
4. **Cautious auto-fix:** Only spacing, signatures, and language tags - never rewrite logic.

---

**Version:** 1.0.0 (agent-dev-toolkit)
