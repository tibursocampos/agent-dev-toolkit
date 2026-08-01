# test-coverage - reference

Commands, metrics, exclusions, and report templates for `skills/test-coverage/SKILL.md`. Keep `SKILL.md` under 500 lines; use this file for extended detail.

---

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

## Metrics (SonarQube alignment)

| SonarQube concept | This skill | How to compute |
|-------------------|------------|----------------|
| Coverage on new code | **New code** | Line coverage on changed production files only: covered lines / coverable lines, weighted by file |
| Coverage after merge (expected) | **Overall branch** | Line % from `Summary.txt` (all included assemblies) |
| Per-file on PR | **Per-file** | Line % per changed production file from Cobertura `class`/`line` nodes |

### Parsing Cobertura for per-file / new code

1. Load `coverage.cobertura.xml` from `TestResults`.
2. For each `<class filename="...">`, map `filename` to repo-relative path.
3. Match against changed production file list from git diff.
4. Line rate = `lines-covered / (lines-covered + lines-uncovered)` from class attributes or count `<line>` hits.

If multiple Cobertura files exist (multiple test projects), merge or take the union of covered lines per source file before calculating rates.

### Threshold evaluation

| Label | Rule |
|-------|------|
| **Threshold** | User/PRD argument or default **80%** on **new code** (weighted) |
| **Target** | **100%** - report gaps for any changed file below 100% even when Pass |
| **Pass** | New code ≥ threshold |
| **Fail** | New code &lt; threshold |

---

## On-disk artifacts (required)

After a successful run, these paths must exist (workspace-relative unless noted):

| Artifact | Path |
|----------|------|
| Cobertura (raw) | `TestResults/**/coverage.cobertura.xml` |
| Summary | `TestResults/CoverageReport/Summary.txt` |
| HTML report | `TestResults/CoverageReport/index.html` |
| Merged Cobertura | `TestResults/CoverageReport/Cobertura.xml` (when ReportGenerator emits it) |

The skill **must** list these paths in the final chat report and paste metrics from `Summary.txt`. Do not create a separate custom `.md` report path - consumer repos typically gitignore `TestResults/`.

## Report template (pt-BR)

```markdown
# Relatório de cobertura - [nome da feature ou branch]

## Artefatos no disco

- `TestResults/CoverageReport/Summary.txt`
- `TestResults/CoverageReport/index.html`
- `TestResults/.../coverage.cobertura.xml` - [caminho exato encontrado]

## Resumo

| Métrica | Valor | Status |
|---------|-------|--------|
| Cobertura em código novo (arquivos alterados) | [X%] | Passou ≥ [threshold]% / Abaixo do target |
| Cobertura geral (branch) | [Y%] | Informativo |
| Threshold | [80]% (mínimo) |
| Meta | 100% |
| Decisão | **Aprovado** / **Reprovado** |

**Branch:** [feature/...]  
**Base:** [main|develop]  
**Testes:** [projeto(s) executado(s)]  
**Limitações:** [Nenhuma | ex.: filtro de testes, coverlet ausente corrigido, etc.]

---

## Código novo (arquivos alterados)

| Arquivo | Linhas cobertas | Cobertura | vs meta 100% |
|---------|-----------------|-----------|--------------|
| `src/.../Handler.cs` | [n/m] | [X%] | OK / Gap |

**Agregado (new code):** [X%]

---

## Cobertura geral (branch)

[Colar linha relevante de Summary.txt ou resumo ReportGenerator]

---

## Lacunas (quando abaixo do threshold ou &lt; 100%)

### `src/.../Service.cs` - [X%]

- Métodos / linhas sem cobertura: [listar quando identificável]
- Sugestão: testes `Should_<Result>_When_<Condition>` em [TestProject]

---

## Bloco para code-review (colar se Pass)

```text
Cobertura validada via test-coverage:
- New code: [X%] (≥ [threshold]%)
- Branch overall: [Y%]
- Meta 100%: [N] arquivo(s) abaixo - documentado acima
```

---

## Próximos passos

- [ ] `/code-review` (se Pass)
- [ ] `/developer` / `sdd-develop` - adicionar testes (se Fail)
- [ ] Re-executar `/test-coverage` após novos testes
```

---

## Scoped discovery (large repos)

| Step | Action |
|------|--------|
| 1 | `git diff <base>...HEAD --name-only` -> infer feature area |
| 2 | Glob `**/*Tests*.csproj` near changed paths |
| 3 | `dotnet test <closest-test-project> --collect:"XPlat Code Coverage"` |
| 4 | Note in report that overall branch % may be partial |

---

## Integration with code-review

When `code-review` Step 5 invokes this skill:

1. Run full `test-coverage` process.
2. Paste **Resumo** table into the review report § Testes.
3. If **Reprovado**, `code-review` decision -> **Alterações necessárias** when PRD/user/threshold applies.

---

## Integration with PLAN (last step)

PLAN step template (in `plan/reference.md` after step 3 of PLAN_001):

```text
/test-coverage - <base-branch> - threshold 80
```

Attach report summary to PLAN step notes when completing the quality step.

---

## Explicit exclusions (toolkit policy)

Do **not** require or generate:

- SonarLint / Visual Studio extension workflows
- SonarQube server API, tokens, or `dotnet-sonarscanner` upload
- Mandatory corporate pipeline URLs
- Coverage gates in this toolkit repo itself (Markdown-only - validate in consumer .NET repos)

---

## Troubleshooting

| Problem | Action |
|---------|--------|
| No `coverage.cobertura.xml` | Verify `coverlet.collector`; check `--results-directory` |
| 0% on changed files | Wrong test project; tests do not exercise changed code |
| ReportGenerator not found | `dotnet tool install -g dotnet-reportgenerator-globaltool` |
| Path mismatch in XML | Normalize `\` vs `/` when matching filenames |
| Tests fail | `/repair-dotnet-build` first |
