# .NET Test Patterns

Load this guide when creating, changing, or reviewing .NET tests. For production C# conventions shared with test code (such as named constants), also load [`csharp-patterns.md`](./csharp-patterns.md) only when those conventions apply.

## Authority and applicability

In an existing repository, first inspect its instructions, test projects, dependencies, and representative tests. Follow the demonstrated project baseline for the test framework, mocking and assertion libraries, naming, fixtures, and test-data patterns. Do not replace or block that baseline to enforce this guide. The toolkit patterns below are defaults for a project with no verifiable baseline; select only the tools and patterns that fit the scenario.

## .NET test patterns

### Toolkit framework defaults (when no repository baseline exists)

| Framework | Usage |
|-----------|--------|
| **xUnit** | `[Fact]`, `[Theory]`, `[InlineData]`, `IClassFixture<T>` |
| **Shouldly** | Assertions via `ShouldBe`, `ShouldNotBeNull`, `ShouldBeTrue`, etc. |
| **Moq** | Mocks via `new Mock<T>()` / `Mock.Of<T>()` |
| **WireMock.Net** | HTTP stubbing in integration/infrastructure tests (when needed) |

When no baseline exists, prefer **xUnit + Moq + Shouldly** for new tests when each library fits the scenario. In a repository with another established stack, continue using it for new scenarios; do not rewrite existing tests unless asked.

### Toolkit test-naming default (when no repository baseline exists)

```
Should_<ExpectedResult>_When_<Condition>
```

**Examples:**

- `Should_Register_Order_When_Data_Is_Valid`
- `Should_Return_Error_When_Order_Not_Found`
- `Should_Throw_When_Customer_Is_Inactive`
- `Should_Update_Status_When_Order_Is_Pending`
- `Should_Not_Allow_Delete_When_Order_Is_Approved`
- `Should_Return_Empty_List_When_No_Orders_Exist`

**Rules:**

- Use English identifiers.
- Do not use `Given_When_Then` naming.
- Avoid extra underscores beyond the pattern.

---

### Test structure

- Structure each test with **Arrange / Act / Assert** - use `// Arrange`, `// Act`, and `// Assert` section comments.
- One test validates **one behavior**.
- No loops or conditional logic inside tests.

```csharp
public class RegisterOrderHandlerTests : IAsyncLifetime
{
    private readonly Mock<IOrderRepository> _orderRepositoryMock = new();
    private IServiceProvider _serviceProvider = null!;

    public async Task InitializeAsync()
    {
        var services = new ServiceCollection();
        services.AddScoped(_ => _orderRepositoryMock.Object);
        services.AddScoped<RegisterOrderHandler>();
        _serviceProvider = services.BuildServiceProvider();
        await Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        if (_serviceProvider is IAsyncDisposable asyncDisposable)
            await asyncDisposable.DisposeAsync();
        else if (_serviceProvider is IDisposable disposable)
            disposable.Dispose();
    }

    [Fact]
    public async Task Should_Return_Order_When_Id_Is_Valid()
    {
        // Arrange
        var order = OrderFake.CreateValid();
        _orderRepositoryMock
            .Setup(r => r.GetByIdAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(order);
        var command = OrderFake.CreateValidCommand();

        await using var scope = _serviceProvider.CreateAsyncScope();
        var handler = scope.ServiceProvider.GetRequiredService<RegisterOrderHandler>();

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        result.ShouldNotBeNull();
        result.Id.ShouldBe(order.Id);
    }
}
```

**Lifecycle:**

- Prefer **fixture-level** setup (`IAsyncLifetime`, `IClassFixture<T>`) for expensive DI registration and `ServiceProvider` build.
- Per-test reset: `Mock.Reset()` or reconfigure setups when mocks need a clean state.
- Resolve the SUT inside each test with `CreateScope()` when scoped services are involved.

---

### SUT via dependency injection (required)

**Resolve the system under test from the container; do not `new` handlers/services with manual constructor wiring when DI is available.**

Why:

- Constructor changes do not break every test that used `new Handler(dep1, dep2, ...)`.
- DI registration is exercised by tests.
- Mock overrides stay in one place.

```csharp
// Correct
await using var scope = _serviceProvider.CreateAsyncScope();
var handler = scope.ServiceProvider.GetRequiredService<RegisterOrderHandler>();

// Wrong for application services
var handler = new RegisterOrderHandler(_repoMock.Object, _loggerMock.Object);
```

**Override dependencies:**

```csharp
services.AddScoped(_ => _orderRepositoryMock.Object);
services.AddScoped<RegisterOrderHandler>();
```

---

### Naming in tests

- Variables, properties, and methods in **English**.
- Mock variables must use the `Mock` suffix.

```csharp
var orderRepositoryMock = new Mock<IOrderRepository>();
```

---

### Toolkit test-data default (when no repository baseline exists)

**All DTOs, entities, and collections used in arrange belong in reusable static `*Fake` classes.**

- Place fakes under `Fake/` or `Fixtures/` in the test project.
- Reuse named constants in **PascalCase** (see § **Named constants (no magic literals)** for production rules).
- Factory methods named `Create*` or `Get*` as appropriate.
- Search for existing `*Fake.cs` before adding a new one.
- Do not duplicate construction logic inline in tests.

```csharp
public static class OrderFake
{
    public const string DefaultOrderNumber = "ORD-001";

    public static Order CreateValid(string orderNumber = DefaultOrderNumber) =>
        new() { OrderNumber = orderNumber, IsActive = true };
}
```

**Exception:** static methods that build `[MemberData]` / `[ClassData]` inputs are acceptable on the test class when they are test infrastructure, not domain arrange data.

---

### Moq usage

```csharp
var orderRepositoryMock = new Mock<IOrderRepository>();

orderRepositoryMock
    .Setup(r => r.GetByIdAsync(It.Is<int>(id => id == OrderFake.DefaultId), It.IsAny<CancellationToken>()))
    .ReturnsAsync(order);

orderRepositoryMock
    .Setup(r => r.GetByIdAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
    .ReturnsAsync(order);

await handler.Handle(command, CancellationToken.None);

orderRepositoryMock.Verify(
    r => r.SaveAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()),
    Times.Once);
```

---

### Shouldly

```csharp
result.ShouldNotBeNull();
result.ShouldBeTrue();
result.ShouldBeFalse();
result.ShouldBeNull();
result.Count.ShouldBe(3);
result.ShouldContain(x => x.Id == expectedId);
Should.Throw<InvalidOperationException>(() => action());

// Avoid classic Assert.That / Assert.Equal for new tests
// Avoid FluentAssertions `.Should().*` in new tests (use Shouldly)
```

---

### Parameterized tests

Prefer `[Theory]` + `[InlineData]` or `[MemberData]` for multiple scenarios:

```csharp
[Theory]
[InlineData(true)]
[InlineData(false)]
public void Should_Validate_Command(RegisterOrderCommand command, bool expectedValid)
{
    var result = _validator.Validate(command);
    result.IsValid.ShouldBe(expectedValid);
}
```

---

### Deterministic tests

- Do not use `DateTime.Now` directly - inject `TimeProvider` or a clock abstraction.
- Do not use uncontrolled `Guid.NewGuid()` when assertions depend on the value.
- Encapsulate non-determinism in fakes or providers.
- Do not rely on implicit ordering.

---

### Integration tests

```csharp
public class OrderApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public OrderApiTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Should_Return_200_When_Order_Exists()
    {
        var response = await _client.GetAsync("/api/orders/1");
        response.StatusCode.ShouldBe(HttpStatusCode.OK);
    }
}
```

---

## Toolkit anti-pattern checks (review checklist)

Apply these checks to new `*Test*.cs` / `*Tests.cs` files when the toolkit defaults apply or when they do not conflict with the established project baseline. Review genuine correctness or reliability issues independently; a different established framework or convention is not itself an anti-pattern.

| # | Anti-pattern | Fix |
|---|--------------|-----|
| 1 | Manual `new` on injectable handlers/services | Resolve via `GetRequiredService<T>()` |
| 2 | Full DI rebuild in every test method | Move registration to fixture / `IAsyncLifetime` |
| 3 | Inline `new DomainEntity { ... }` in tests | Move to `*Fake` |
| 4 | Private `Create*` / `Build*` helpers on fixture for domain data | Move to `*Fake` |
| 5 | Classic `Assert.*` or FluentAssertions in new tests | Use Shouldly (`ShouldBe`, `ShouldNotBeNull`, …) |
| 6 | Test name not `Should_*_When_*` | Rename |
| 7 | `.Result` / `.Wait()` on tasks | Use `await` |

**Accepted patterns:** `IClassFixture<T>`, `CreateScope()`, `*Fake.*`, `Mock<T>`, Shouldly, `[Theory]`, `Should_*_When_*`.

**Legitimate exceptions:**

- Pure domain entity tests with no DI: `new OrderLine(...)` is fine when the type has no injectable dependencies - still use fakes for complex arrange data.
- `[MemberData]` builders on the test class for xUnit data sources.

Document a deviation when choosing a toolkit default over another applicable option; do not treat the project's established baseline as an exception that needs justification.
