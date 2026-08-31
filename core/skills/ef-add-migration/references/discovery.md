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
