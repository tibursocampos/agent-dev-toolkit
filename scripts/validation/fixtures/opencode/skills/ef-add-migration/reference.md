# ef-add-migration - reference

Detailed discovery and EF commands for `skills/ef-add-migration/SKILL.md`. Keep `SKILL.md` under 500 lines; use this file for extended detail.

---

## Discovery (Glob / Grep)

Run from the **target repository** root.

| Goal | Approach |
|------|----------|
| Solution | Glob `**/*.sln` (depth ≤ 3 if noisy) |
| Startup | Glob `**/Program.cs`, `**/Startup.cs`; exclude `bin/`, `obj/`; prefer path segments containing `Api`, `Host`, `Web`, `Worker` |
| DbContext | Grep `class \w+DbContext` in `*.cs`; exclude `bin/`, `obj/` |
| Migrations folder | Glob `**/Migrations/*.cs` or read target `.csproj` for `Migrations` output |
| Target `.csproj` | Parent folder of the file declaring the chosen `DbContext` |

**Multiple candidates:** prefer startup with `Api` in the name; prefer target that owns the migrations folder already used in the repo.

---

## Naming patterns

| Change | Pattern | Example |
|--------|---------|---------|
| New entity | `Create<Entity>` | `CreateOrderLine` |
| Add column | `Add<Property>To<Entity>` | `AddExternalCodeToMaterial` |
| Remove column | `Remove<Property>From<Entity>` | `RemoveLegacyIdFromCustomer` |
| Schema tweak | `Alter<Entity>` | `AlterInvoice` |
| Seed data | `<Entity>Seed` or `<Description>Seed` | `PermissionsSeed` |

Infer from `git diff` / `git status` when the user does not supply a name.

---

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

## Expected artifacts

After `migrations add`:

- `<timestamp>_<MigrationName>.cs`
- `<timestamp>_<MigrationName>.Designer.cs`
- `<DbContext>ModelSnapshot.cs` updated

List the newest files in the migrations directory to confirm.

---

## SDD cross-cut

When a PLAN step says “add EF migration”, the **implement** skill hands off here instead of embedding `dotnet ef` steps in the PLAN body. After migration files exist, resume:

```
/sdd-develop - <full-plan-path> - Step N
```

Use the **same** SDD PLAN path `sdd-develop` passed in (`features/**/PLAN/PLAN_*.md` or global `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/opencode/sdd/<repo-id>/features/**/PLAN/` per `STORAGE.md`). Do not use root/flat `PLAN/` or `docs/documentation-plan/plan.md`.
