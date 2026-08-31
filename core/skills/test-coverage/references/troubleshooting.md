## Troubleshooting

| Problem | Action |
|---------|--------|
| No `coverage.cobertura.xml` | Verify `coverlet.collector`; check `--results-directory` |
| 0% on changed files | Wrong test project; tests do not exercise changed code |
| ReportGenerator not found | `dotnet tool install -g dotnet-reportgenerator-globaltool` |
| Path mismatch in XML | Normalize `\` vs `/` when matching filenames |
| Tests fail | `/repair-dotnet-build` first |
