## Commands

### Resolve changed production files

```bash
git fetch origin
git diff <base>...HEAD --name-only -- "*.cs"
```

Filter interactively or with script: drop paths matching § Exclusions.

### Run tests with coverage

**Full solution (default):**

```bash
dotnet test --collect:"XPlat Code Coverage" --results-directory ./TestResults
```

**Scoped project:**

```bash
dotnet test path/to/MyApp.Tests.csproj --collect:"XPlat Code Coverage" --results-directory ./TestResults
```

**Large repo - filter:**

```bash
dotnet test --collect:"XPlat Code Coverage" --results-directory ./TestResults --filter "FullyQualifiedName~MyFeatureTests"
```

Coverage files appear under `TestResults/**/coverage.cobertura.xml`.

### Generate human-readable summary

```bash
reportgenerator \
  -reports:"TestResults/**/coverage.cobertura.xml" \
  -targetdir:"TestResults/CoverageReport" \
  -reporttypes:"TextSummary;Html;Cobertura"
```

Read `TestResults/CoverageReport/Summary.txt` for overall line/branch rates.

On Windows PowerShell (single line):

```powershell
reportgenerator "-reports:TestResults/**/coverage.cobertura.xml" "-targetdir:TestResults/CoverageReport" "-reporttypes:TextSummary;Html;Cobertura"
```

---

---
