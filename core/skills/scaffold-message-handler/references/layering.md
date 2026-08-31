## Layering (when generating .NET code)

Load `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md` before writing code.

Typical placement (adapt to repo):

| Piece | Layer |
|-------|--------|
| Message contract | Application.Contracts / Domain events / shared Messages project |
| Consumer / handler | Infrastructure or Application (match existing consumers) |
| Business logic | Application handler or domain service invoked by consumer |
| Persistence | Infrastructure |

Do not introduce new projects or folders without user confirmation.

---
