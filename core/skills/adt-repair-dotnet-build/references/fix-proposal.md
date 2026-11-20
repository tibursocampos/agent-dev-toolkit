## Fix proposal template

```markdown
## Proposed fixes

1. **src/.../Mapper.cs:28** - implicit `decimal.Parse`
   - **Cause:** culture-dependent parsing on Linux CI
   - **Fix:** `decimal.Parse(value, CultureInfo.InvariantCulture)`

Apply these fixes? Single select; ids `confirm` (apply all listed fixes), `adjust` (change the list first), `cancel` (apply none). Render labels in the user chat language; answer mapping: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`.
```

---
