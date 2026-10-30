# C# runtime and modern patterns

> Companion to `csharp-patterns.md` (style and structure). Load only when the step touches these topics.

---

### Async/await

- Async methods must use the `Async` suffix.
- Always use `await`.
- Do not use `.Result` or `.Wait`.
- Do **not** use `ConfigureAwait` in application code (ASP.NET Core APIs, workers, handlers). Prefer plain `await` end-to-end and propagate `CancellationToken`.

```csharp
// Correct
public async Task<Order> GetOrderAsync(int id, CancellationToken cancellationToken = default)
{
    return await _orderRepository.GetByIdAsync(id, cancellationToken);
}

// Wrong - deadlock risk / sync-over-async
public Order GetOrder(int id)
{
    return _orderRepository.GetByIdAsync(id).Result;
}

// Wrong - do not sprinkle ConfigureAwait in app code
return await _orderRepository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
```

### Modern C# (primary constructors, collection expressions, `required`)

- **New types / new files** with no established local style: prefer primary constructors, collection expressions (`[1, 2, 3]`), and `required` members when they fit the type.
- **Existing code / repo already using classic constructors or array syntax:** match the project - do not rewrite only to modernize.

```csharp
// Preferred for new types
public sealed class OrderService(IOrderRepository repository)
{
    public async Task<Order?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        await repository.GetByIdAsync(id, cancellationToken);
}

public sealed class OrderDto
{
    public required string OrderNumber { get; init; }
}

int[] statusCodes = [1, 2, 3];
```

### Nullable reference types

```csharp
// Correct
public string OrderNumber { get; init; } = string.Empty;
public string? Notes { get; init; }

// Avoid
public string OrderNumber { get; set; }  // May be null unintentionally
```

### Record types

```csharp
public record OrderDto(int Id, string OrderNumber, DateTime CreatedAt);
public record OrderReference(string Code, string ProductionLine);
```

### Dependency injection

```csharp
public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Order>> GetAllAsync(CancellationToken cancellationToken = default);
}

services.AddScoped<IOrderRepository, OrderRepository>;
services.AddTransient<IValidator<RegisterOrderCommand>, RegisterOrderCommandValidator>;
```

### IOptions pattern

```csharp
public class OrderService
{
    private readonly OrderOptions _options;

    public OrderService(IOptions<OrderOptions> options)
    {
        _options = options.Value;
    }
}

services.Configure<OrderOptions>(configuration.GetSection("Order"));
```

### Resource management

```csharp
await using var connection = new SqlConnection(connectionString);
await connection.OpenAsync(cancellationToken);

public class IntegrationClient
{
    private readonly HttpClient _httpClient;

    public IntegrationClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }
}
```

---
