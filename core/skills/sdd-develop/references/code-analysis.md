## Pre-implementation code analysis

| Area | Action |
|------|--------|
| Step file list | Read each path; note namespaces, patterns, test project layout |
| Similar types | Glob for `*Entity*.cs`, handlers, consumers named like the change |
| Tests | Read project instructions, test configuration, and a representative test class; follow the established framework, libraries, naming, and structure. Use applicable `dotnet-test-patterns.md` defaults only when no baseline is verifiable |
| DI registration | Grep `AddScoped`, `AddTransient`, module extensions |
| Errors | Grep `Result<`, exceptions, validation style |
| Project vs toolkit style | If the touched type already uses a style the toolkit bar rejects, record it and ask. Do not restyle existing members before the answer. An operator order to keep the project pattern wins |
| Migrations | If step includes EF: list latest migrations for naming convention |

Record answers before coding: naming language, async rules, Result vs exceptions, nullable style.

A migration waits for the `database` specialist. A contract divergence goes back to `sdd-plan`.

---
