## Optional structural diagnostics

The repository may provide a structural PLAN validator, for example:

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-plan.ps1" -Path <plan-path> -PrdPath <prd-path>
```

Use it when it can help find a concrete artifact issue or when the operator requests it. A passing result is not proof that behavior, acceptance, or validation are substantively sufficient. A failure is diagnostic: inspect the finding, fix it when it reveals a real content problem, and leave grammar-only or optional-field preferences non-blocking.

Do not use validator output as an authorization token, approval gate, or reason to create mandatory TASKS, CONTINUITY, CHANGE, section counts, or exact title grammar. Existing fixtures and static checks validate their own contracts; they do not establish that the host presents a live table.
