## Integration with code-review

When `code-review` Step 5 invokes this skill:

1. Run full `test-coverage` process.
2. Paste **Resumo** table into the review report § Testes.
3. If **Reprovado**, `code-review` decision -> **Alterações necessárias** when PRD/user/threshold applies.

---

## Integration with PLAN (last step)

PLAN step template (in `plan/reference.md` after step 3 of PLAN_001):

```text
/test-coverage - <base-branch> - threshold 80
```

Attach report summary to PLAN step notes when completing the quality step.

---
