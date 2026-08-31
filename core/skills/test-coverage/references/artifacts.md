## On-disk artifacts (required)

After a successful run, these paths must exist (workspace-relative unless noted):

| Artifact | Path |
|----------|------|
| Cobertura (raw) | `TestResults/**/coverage.cobertura.xml` |
| Summary | `TestResults/CoverageReport/Summary.txt` |
| HTML report | `TestResults/CoverageReport/index.html` |
| Merged Cobertura | `TestResults/CoverageReport/Cobertura.xml` (when ReportGenerator emits it) |

The skill **must** list these paths in the final chat report and paste metrics from `Summary.txt`. Do not create a separate custom `.md` report path - consumer repos typically gitignore `TestResults/`.
