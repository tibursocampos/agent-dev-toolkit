## Optional legacy PLAN diagnostic

This command checks the legacy PLAN format. Use it only when the operator explicitly asks to diagnose that format:

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-plan.ps1" -Path <plan-path> -PrdPath <prd-path>
```

Current PLANs rely on the substantive review in `self-review.md`. A passing legacy result does not establish behavior, acceptance or validation. A failure is diagnostic: inspect the finding, fix it when it reveals a real content problem, and leave grammar-only or optional-field preferences non-blocking.

Do not use validator output as an authorization token, approval gate, or reason to create mandatory TASKS, CONTINUITY, CHANGE, section counts, or exact title grammar. Existing fixtures and static checks validate their own contracts; they do not establish that the host presents a live table.
