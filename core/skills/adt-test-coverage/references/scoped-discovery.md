## Scoped discovery (large repos)

| Step | Action |
|------|--------|
| 1 | `git diff <base>...HEAD --name-only` -> infer feature area |
| 2 | Glob `**/*Tests*.csproj` near changed paths |
| 3 | `dotnet test <closest-test-project> --collect:"XPlat Code Coverage"` |
| 4 | Note in report that overall branch % may be partial |

---
