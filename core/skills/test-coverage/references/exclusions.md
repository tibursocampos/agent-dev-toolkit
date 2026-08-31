## Exclusions (new-code denominator)

**Include** in changed-file set:

- Production `.cs` under `src/`, `Source/`, layer folders (`Domain`, `Application`, `Infrastructure`, `Api`, etc.)

**Exclude** from new-code metrics (still may appear in overall branch):

| Pattern | Reason |
|---------|--------|
| `**/Migrations/**` | EF migrations - SonarQube new-code exclusion |
| `**/*.g.cs` | Generated |
| `**/*.Designer.cs` | Generated |
| `**/obj/**`, `**/bin/**` | Build output |
| `**/*Tests/**`, `**/*.Tests/**`, `**/*Test*.csproj` | Test code |
| `**/Program.cs` | Host bootstrap only - optional per repo; document if excluded |

Normalize paths (forward slashes) when matching Cobertura `filename` attributes.

---

## Explicit exclusions (toolkit policy)

Do **not** require or generate:

- SonarLint / Visual Studio extension workflows
- SonarQube server API, tokens, or `dotnet-sonarscanner` upload
- Mandatory corporate pipeline URLs
- Coverage gates in this toolkit repo itself (Markdown-only - validate in consumer .NET repos)

---
