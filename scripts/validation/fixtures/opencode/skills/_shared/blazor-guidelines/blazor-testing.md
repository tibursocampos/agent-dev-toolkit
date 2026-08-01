# Blazor testing

bUnit for component tests; Playwright (or project E2E) for critical paths. Follow hub `frontend-guidelines/frontend-testing.md` for cross-stack habits — specialize here for Razor/bUnit.

---

## MUST

- Prefer **bUnit** `TestContext` for component behavior when the repo already references bUnit; otherwise match the existing test stack.
- Structure tests with **Arrange / Act / Assert** comments when that is the workspace convention.
- Name tests to express behavior (`Should_RenderTitle_When_TitleProvided` or the repo’s equivalent).
- Register doubles on `ctx.Services` the same way production registers neighbors (`AddSingleton` / `AddScoped`).
- Use `WaitForState` / `WaitForAssertion` for async renders instead of fixed `Thread.Sleep`.
- Mock `IJSRuntime` (bUnit JSInterop helpers or project mocks) whenever the component invokes JS.
- Place shared builders, fakers, and mocks under `TestInfrastructure` (or the repo’s test-helpers folder) — do not duplicate arrange blocks in every test class.
- Cover meaningful paths: render, user interaction, validation failure, authorize not-authorized — not line-coverage-only stubs.

```csharp
[Fact]
public void Should_RenderTitle_When_TitleProvided()
{
    // Arrange
    using var ctx = new TestContext();
    var cut = ctx.RenderComponent<UserCard>(parameters => parameters
        .Add(p => p.Title, "Ada"));

    // Act
    var heading = cut.Find("h2");

    // Assert
    heading.TextContent.Should().Be("Ada");
}
```

---

## MUST NOT

- Assert only that `Markup` is non-empty when a specific role/text/callback is the behavior under test.
- Reach into `private` fields via reflection when public render output or callbacks can observe the behavior.
- Hit real networks inside bUnit tests when an `HttpClient` fake / `HttpMessageHandler` stub exists in TestInfrastructure.
- Copy-paste identical service registration into dozens of tests — extract a shared context helper if the project pattern allows.
- Skip disposal of `TestContext` (`using`) when the suite expects it.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Shouldly / xUnit / NUnit / MSTest | Prefer Shouldly + xUnit for new tests; otherwise match existing assertion + runner libraries |
| Auth components | bUnit `AddAuthorization` / cascading auth helpers already used |
| `EditForm` features | `Change` + submit; assert validation text or callback |
| Render modes | Test interactive components with the host helpers the suite already uses |
| Playwright/Cypress present | Smoke navigation, login, and one happy-path form — do not re-test every unit case in E2E |

### Forms and JS

- Set inputs with `cut.Find("input").Change("value")` (or bUnit input helpers).
- Submit and assert validation messages or `EventCallback` invocations.
- Configure `ctx.JSInterop.Mode` / setup per existing tests when JS is required.

### Commands

```bash
dotnet build
dotnet test
```

Run the impacted test project first on large solutions; full suite when CI requires it.

### Pack map

| Concern | File |
|---------|------|
| Components / lifecycle | `blazor-components.md` |
| Forms / state | `blazor-state.md` |
| Render modes | `blazor-render-modes.md` |
| JS interop mocks | `blazor-js-interop.md` |
| Routing / auth | `blazor-routing-auth.md` |

---

## References

- [bUnit documentation](https://bunit.dev/)
- [ASP.NET Core Blazor test components](https://learn.microsoft.com/en-us/aspnet/core/blazor/test)
- [Blazor forms and validation](https://learn.microsoft.com/en-us/aspnet/core/blazor/forms/)
