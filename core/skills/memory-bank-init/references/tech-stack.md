## tech-stack.json fill

From inventory `stack_hints` + manifests:

| Hint | languages / frameworks examples |
|------|----------------------------------|
| node | `javascript`/`typescript`; frameworks from package.json deps if read |
| dotnet | `csharp`; `aspnet` / `efcore` if csproj evidence |
| python | `python`; FastAPI/Flask if pyproject/requirements mention |
| go / rust | as detected |

`generated_at` must match inventory run (ISO-8601 UTC).
