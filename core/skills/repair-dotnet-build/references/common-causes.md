## Common causes (tests and build)

### Culture and parsing

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| `decimal.Parse` mismatch across OS | Implicit culture (en-US vs pt-BR) | `CultureInfo.InvariantCulture` or explicit culture matching data source |
| FluentValidation message mismatch | `CurrentUICulture` vs agent locale | Set `CultureInfo.DefaultThreadCurrentUICulture` in test fixture |
| xUnit collection fixture order | Culture set too late | Set default thread cultures in fixture constructor before tests run |

### Dates and time zones

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Off-by-hours in assertions | `DateTime.Now` vs UTC | Prefer `DateTime.UtcNow` or explicit `TimeZoneInfo.ConvertTime` |
| Flaky “today” tests | Hardcoded date relative to run day | Inject `TimeProvider` / clock abstraction or freeze test time |

### Random / generated data

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Intermittent assertion values | Bogus or random without fixed seed | Fix seed in test infrastructure or use deterministic builders |
| Mapper vs fake culture drift | Both parse decimals without culture | Align fake and mapper to same explicit `CultureInfo` |

### Restore and compile

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Package not found | Missing feed in `NuGet.Config` | Document feed in repo README; do not invent corporate URLs |
| Linux CI glob not expanding | `**/*.Test*.csproj` without globstar | Use solution file path in pipeline (when user shares YAML) |

---
