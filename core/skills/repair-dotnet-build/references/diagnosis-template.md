## Diagnosis template (extended)

```markdown
## Build diagnosis

**Source:** local | pasted log | GitHub Actions (run <id>)
**Branch:** feature/...
**Failures:** 2

### 1. [Test] Should_ReturnTotal_When_ItemsAdded
- **File:** tests/.../OrderTests.cs:42
- **Expected:** 10.5
- **Actual:** 10,5
- **Hypothesis:** culture - see § Culture and parsing

### 2. [Compile] CS0246 in Handler.cs:12
- **Hypothesis:** missing using or renamed type
```

---
