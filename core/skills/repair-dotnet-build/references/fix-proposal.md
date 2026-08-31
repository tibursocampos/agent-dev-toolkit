## Fix proposal template

```markdown
## Proposed fixes

1. **src/.../Mapper.cs:28** - implicit `decimal.Parse`
   - **Cause:** culture-dependent parsing on Linux CI
   - **Fix:** `decimal.Parse(value, CultureInfo.InvariantCulture)`

Apply these fixes? (wait for user yes/no)
```

---
