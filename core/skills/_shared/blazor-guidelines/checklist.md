# Blazor delivery checklist

Use before opening a pull request for Blazor (WASM / Server / Hybrid) work. Prefer bUnit on greenfield component tests; otherwise match the project’s test stack.

When ARCH or CONTINUITY needs frontend folder layout, load `../frontend-guidelines/frontend-architecture.md` (shared hub). When the solution also hosts a concentric .NET API beside Blazor UI, load `../dotnet-guidelines/clean-architecture.md` for API rings — do not duplicate full CA inside this Blazor pack.

---

## Preparation

- [ ] `AGENTS.md` / README and host type detected (WASM / Server / Auto / Hybrid)
- [ ] PLAN step (if applicable) understood; acceptance criteria clear
- [ ] Loaded only needed files from this pack + `frontend-guidelines/`
- [ ] DESIGN-BRIEF consulted when present (do not reinterpret visuals)

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Components and state

- [ ] Parameters / `EventCallback` / lifecycle per `blazor-components.md`
- [ ] UI state local; shared state via existing services or cascading values (`blazor-state.md`)
- [ ] Forms: `EditForm` + project validators; submit guarded against double-post
- [ ] Disposables registered for subscriptions / JS modules
- [ ] No UI-thread blocking on Interactive Server

---

## Render modes, routing, JS

- [ ] Render mode matches siblings / host (`blazor-render-modes.md`) — no silent global mode change
- [ ] Routes + `[Authorize]` / policies aligned (`blazor-routing-auth.md`)
- [ ] JS interop via modules + dispose (`blazor-js-interop.md`)
- [ ] Perf changes measured first (`blazor-performance.md`)

---

## Tests

- [ ] bUnit (or project equivalent) covers changed behavior (`blazor-testing.md`)
- [ ] JS / auth / HttpClient faked via TestInfrastructure helpers
- [ ] Arrange / Act / Assert structure when the repo uses it
- [ ] Names: `Should_<result>_When_<condition>` (or repo equivalent)
- [ ] E2E smoke only for critical paths when Playwright (etc.) exists

---

## Validate

```bash
dotnet build
dotnet test
```

- [ ] Failures in scope fixed before handoff
- [ ] No secrets in WASM bundles or client config
- [ ] Identifiers/comments in **English**
- [ ] `/commit` offered — do not auto-commit

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| ARCH / CONTINUITY needs FE structure | Prefer load `../frontend-guidelines/frontend-architecture.md` |
| API + Blazor under concentric .NET | Prefer load `../dotnet-guidelines/clean-architecture.md` + FE hub above |
| DESIGN-BRIEF present | Treat as acceptance; do not reinterpret visuals |
| .NET 8+ render modes | Prefer island interactivity over blanket Interactive |
| Fluxor / MediatR | Extend existing store/mediator; do not add a parallel one |
| Hybrid MAUI | Note platform constraints; test on target when chrome differs |

### Pack map (load only what you need)

| Concern | File |
|---------|------|
| Components / lifecycle | `blazor-components.md` |
| State / forms | `blazor-state.md` |
| Render modes | `blazor-render-modes.md` |
| JS interop | `blazor-js-interop.md` |
| Routing / auth | `blazor-routing-auth.md` |
| Performance | `blazor-performance.md` |
| Tests | `blazor-testing.md` |

---

## References

- Pack files in this folder
- [ASP.NET Core Blazor docs](https://learn.microsoft.com/en-us/aspnet/core/blazor/)
- [bUnit](https://bunit.dev/)
- Hub: `frontend-guidelines/frontend-practices.md`, `frontend-testing.md`
