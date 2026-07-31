# Blazor Testing

bUnit for component tests; Playwright for E2E when configured. Follow `frontend-guidelines/frontend-testing.md`.

## bUnit component tests

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

- Use `TestContext` per test; dispose with `using`.
- Mock services via `Services.AddSingleton` on the context.
- `WaitForState` / `WaitForAssertion` for async rendering.

## Testing forms

- Set input values with `cut.Find("input").Change("value")`.
- Submit forms and assert validation messages or callback invocation.

## JS interop

- Mock `IJSRuntime` with `JsRuntimeMock` or bUnit helpers when components call JS.

## E2E (Playwright)

- Smoke critical paths: navigation, login, form submit.
- Run against deployed or `dotnet run` host per project CI setup.

## Commands

```bash
dotnet build
dotnet test
```

## Arrange shared setup

Place reusable mocks and test data in a `TestInfrastructure` or project test helpers folder - not duplicated in every test file.
