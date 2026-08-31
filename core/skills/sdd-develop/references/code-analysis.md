## Pre-implementation code analysis

| Area | Action |
|------|--------|
| Step file list | Read each path; note namespaces, patterns, test project layout |
| Similar types | Glob for `*Entity*.cs`, handlers, consumers named like the change |
| Tests | Read one existing test class; match naming (`Should_*_When_*`), framework (xUnit), assertions (Shouldly), mocks (Moq) |
| DI registration | Grep `AddScoped`, `AddTransient`, module extensions |
| Errors | Grep `Result<`, exceptions, validation style |
| Migrations | If step includes EF: list latest migrations for naming convention |

Record answers before coding: naming language, async rules, Result vs exceptions, nullable style.

---
