## Optional legacy PRD diagnostic

`validate-prd` checks the legacy PRD format. Use it only when the operator explicitly asks to diagnose that format. Review the contracts, behavior and acceptance directly in current PRDs.

```text
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-prd.ps1" -Path <prd-path>
```

If it reports a structural mismatch, inspect the content directly and decide whether behavior, acceptance, scope, or a relevant contract is actually unclear. Correct material omissions; do not rewrite equivalent content solely to satisfy document grammar.
