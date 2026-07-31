# PR Comment Format Validator

Validates inline pull-request review comments for consistent structure (GitHub/generic).

**Related:** `skills/code-review/SKILL.md`

## Expected format

```markdown
{🔴 BLOCKING | 🟡 SUGGESTION}

[brief description]

**Current code:**
```{lang}
[exact current code]
```

**Suggested fix (copy-paste):**
```{lang}
[complete fixed code]
```

<details>
<summary>Details</summary>

**Reason:** [technical explanation]
**Impact:** [consequences]
**Priority:** [Critical/High/Medium/Low]

**How to apply:**
1. [step 1]
2. [step 2]

</details>

---
_Review comment - cursor-dev-toolkit code-review_
```

## Validation rules

### Rule 1: Severity marker (required - error)

Comment must start with `🔴 BLOCKING` or `🟡 SUGGESTION`.

### Rule 2: Code blocks (required - error)

- Must include `**Current code:**` with a non-empty fenced block
- Must include `**Suggested fix`** with a non-empty fenced block
- Fences must have a language tag (`csharp`, `typescript`, etc.)

### Rule 3: Details section (required - error)

- Closed `<details>` … `</details>`
- Inside: `**Reason:**`, `**Impact:**`, `**Priority:**` (required)
- `**How to apply:**` recommended (warning if missing)

### Rule 4: Language (warning)

Body text should match the repository convention (English by default in this toolkit). Flag mixed-language field labels if the repo standard is English.

### Rule 5: Footer signature (warning - auto-fixable)

Optional footer regex: `/_Review comment - .+/`

### Rule 6: Line reference (required for inline - error)

Line number must be valid for the diff hunk.

## Validation result

`{ isValid, issues[], warnings[], canAutoFix, autoFix? }`

- `isValid = true` when there are zero errors (warnings allowed)
- `canAutoFix = true` for trivial warnings (missing signature, missing language tag)

## Auto-fix behavior

**Auto-fixable (warnings only):**

- Append standard footer if missing
- Add generic language tag to untagged fences

**Not auto-fixable (errors):**

- Missing current-code section
- Missing suggested-fix section
- Missing `<details>` block
- Empty code blocks
- Invalid line reference

## Output example

```text
Comment validation:
  ✅ OrderService.cs (line 45): Valid
  ⚠️  UserRepo.cs (line 89): Missing signature - auto-fixed
  ❌ PaymentService.cs (line 102): Missing "Current code:" - skipped

Totals: 3 | Valid: 1 | Auto-fixed: 1 | Skipped: 1
```

---

**Version:** 1.0.0 (cursor-dev-toolkit)
