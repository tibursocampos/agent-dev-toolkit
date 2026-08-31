## EF tool

### Check global CLI

```bash
dotnet ef --version
```

### Repo-local tool (optional)

Some repos ship `dotnet-ef` under the repo root:

```bash
./dotnet-ef --version
```

### Install when missing

Prefer matching the repo’s target framework. Read `global.json`, `Directory.Build.props`, or main `.csproj` `TargetFramework` before installing.

**Global (example - adjust version to repo):**

```bash
dotnet tool install --global dotnet-ef
```

**Local tool-path (example - no version pinned in SKILL):**

```bash
dotnet tool install dotnet-ef --tool-path . --ignore-failed-sources
```

Document the version used in the session summary if the repo has no standard.

---
