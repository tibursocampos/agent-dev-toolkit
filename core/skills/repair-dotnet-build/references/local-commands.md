## Local commands

```bash
# Full solution (default)
dotnet build
dotnet test --no-build

# Large repo - scoped
dotnet test path/to/TestProject.csproj --filter "FullyQualifiedName~MyFeatureTests"
dotnet test --no-build --filter "FullyQualifiedName~MyFeatureTests"
```

Capture tail of output for diagnosis; read full lines for file paths and test names.

---
