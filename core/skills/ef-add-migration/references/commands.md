## Commands

### Add migration

```bash
dotnet ef migrations add <MigrationName> \
  -s <StartupProject.csproj> \
  -p <TargetProject.csproj> \
  -c <DbContextName>
```

Local tool variant: `./dotnet-ef migrations add ...` with the same flags.

### Apply locally (user-requested only)

```bash
dotnet ef database update \
  -s <StartupProject.csproj> \
  -p <TargetProject.csproj> \
  -c <DbContextName>
```

---
