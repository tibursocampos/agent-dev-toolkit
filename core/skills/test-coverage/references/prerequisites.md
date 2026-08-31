## Prerequisites

### coverlet.collector (per test project)

The test `.csproj` must reference the collector package:

```xml
<PackageReference Include="coverlet.collector" Version="6.*" />
```

**Detect:**

```bash
# From repo root - replace path when scoped
grep -l "coverlet.collector" **/*Tests*.csproj **/*.Tests.csproj 2>/dev/null
```

On PowerShell:

```powershell
Get-ChildItem -Recurse -Filter *.csproj | Where-Object { $_.Name -match 'Tests?' } |
  ForEach-Object { Select-String -Path $_.FullName -Pattern 'coverlet.collector' -Quiet; if ($?) { $_.FullName } }
```

If missing, instruct the user to add the package and re-run - do not proceed with a fake Pass.

### dotnet-reportgenerator-globaltool (once per machine)

```bash
dotnet tool install -g dotnet-reportgenerator-globaltool
reportgenerator -?
```

If install fails (permissions), document limitation and parse `coverage.cobertura.xml` manually when feasible.

### Tests must pass

Run `dotnet build` first. Coverage on failing tests is misleading - fix via `/repair-dotnet-build` before coverage collection.

---
