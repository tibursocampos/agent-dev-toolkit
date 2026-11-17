## Optional PRD structure diagnostic

`validate-prd` may be run when its feedback helps locate a concrete issue. It is not required before handoff and its accepted headings, ID format, or optional sections do not define whether a PRD is substantively usable.

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-prd.ps1" -Path <prd-path>
```

If it reports a structural mismatch, inspect the content directly and decide whether behavior, acceptance, scope, or a relevant contract is actually unclear. Correct material omissions; do not rewrite equivalent content solely to satisfy document grammar.
