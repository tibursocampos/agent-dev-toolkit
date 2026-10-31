# Example: new .NET endpoint

> Illustrative example of the layer format. This is not code generated in this toolkit repository. The names (`Orders`, `Payments`) are fictional. Adapt to the real project's pattern, which takes precedence.

This example shows a new `POST /orders` endpoint that creates an order and calls an external payment service. It follows the layer separation used in [core/skills/_shared/dotnet-guidelines](../../core/skills/_shared/dotnet-guidelines/). The snippets are short and show only the essentials.

## Call path

```
HTTP POST /orders
  └─ OrdersController           (HTTP entry, contract validation)
       └─ OrderFacade           (orchestrates the operation, maps DTOs)
            └─ OrderService     (application rule, transaction)
                 ├─ Order       (domain entity, invariants)
                 └─ IPaymentGatewayClient
                      └─ HttpClient created by IHttpClientFactory
```

Dependency rule: the controller knows the facade. The facade knows the services. The services know the entities and the outbound interfaces. Nothing from the outer layers appears in the domain.

## Controller

```csharp
[ApiController]
[Route("orders")]
public class OrdersController(IOrderFacade orderFacade) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<OrderResponse>> Create(CreateOrderRequest request, CancellationToken ct)
    {
        var response = await orderFacade.CreateAsync(request, ct);
        return CreatedAtAction(nameof(Get), new { id = response.Id }, response);
    }
}
```

## Facade

```csharp
public class OrderFacade(IOrderService orderService) : IOrderFacade
{
    public async Task<OrderResponse> CreateAsync(CreateOrderRequest request, CancellationToken ct)
    {
        var order = await orderService.CreateAsync(request.ToCommand(), ct);
        return OrderResponse.From(order);
    }
}
```

The facade contains no business rule. It converts the HTTP contract into an application command and returns the response DTO.

## Application service

```csharp
public class OrderService(IOrderRepository repository, IPaymentGatewayClient payments) : IOrderService
{
    public async Task<Order> CreateAsync(CreateOrderCommand command, CancellationToken ct)
    {
        var order = Order.Create(command.CustomerId, command.Items);
        await payments.AuthorizeAsync(order.Id, order.Total, ct);
        await repository.AddAsync(order, ct);
        return order;
    }
}
```

## Entity

```csharp
public class Order
{
    private Order() { }

    public Guid Id { get; private set; }
    public Guid CustomerId { get; private set; }
    public decimal Total { get; private set; }

    public static Order Create(Guid customerId, IReadOnlyList<OrderItem> items)
    {
        if (items.Count == 0) throw new DomainException("An order needs at least one item.");
        return new Order { Id = Guid.NewGuid(), CustomerId = customerId, Total = items.Sum(i => i.Subtotal) };
    }
}
```

Invariants live in the entity, not in the controller.

## External client with HttpClientFactory

Registration:

```csharp
builder.Services.AddHttpClient<IPaymentGatewayClient, PaymentGatewayClient>(client =>
{
    client.BaseAddress = new Uri(configuration["Payments:BaseUrl"]!);
});
```

Client:

```csharp
public class PaymentGatewayClient(HttpClient httpClient) : IPaymentGatewayClient
{
    public async Task AuthorizeAsync(Guid orderId, decimal amount, CancellationToken ct)
    {
        var response = await httpClient.PostAsJsonAsync("authorizations", new { orderId, amount }, ct);
        response.EnsureSuccessStatusCode();
    }
}
```

`IHttpClientFactory` manages the handler lifecycle and avoids socket exhaustion. If the team uses **RestEase** instead, the interface becomes a declarative contract and the implementation is generated. The tests and the application layer do not change.

## Tests

Use the project's pattern. The toolkit uses xUnit and Moq, see `dotnet-test-patterns.md`.

Facade unit test, with the service mocked:

```csharp
[Fact]
public async Task CreateAsync_ShouldReturnResponse_WhenServiceCreatesOrder()
{
    var service = new Mock<IOrderService>();
    service.Setup(s => s.CreateAsync(It.IsAny<CreateOrderCommand>(), default))
           .ReturnsAsync(OrderFixtures.Single());
    var facade = new OrderFacade(service.Object);

    var response = await facade.CreateAsync(OrderFixtures.RequestWithOneItem(), default);

    Assert.NotEqual(Guid.Empty, response.Id);
}
```

Service unit test, with the repository and gateway mocked. Verify the gateway call and the persistence:

```csharp
[Fact]
public async Task CreateAsync_ShouldAuthorizePayment_BeforePersisting()
{
    var repository = new Mock<IOrderRepository>();
    var payments = new Mock<IPaymentGatewayClient>();
    var service = new OrderService(repository.Object, payments.Object);

    await service.CreateAsync(OrderFixtures.CommandWithOneItem(), default);

    payments.Verify(p => p.AuthorizeAsync(It.IsAny<Guid>(), It.IsAny<decimal>(), default), Times.Once);
    repository.Verify(r => r.AddAsync(It.IsAny<Order>(), default), Times.Once);
}
```

Controller test, with the facade mocked. Verify the HTTP status and the response contract:

```csharp
[Fact]
public async Task Create_ShouldReturnCreated_WhenFacadeSucceeds()
{
    var facade = new Mock<IOrderFacade>();
    facade.Setup(f => f.CreateAsync(It.IsAny<CreateOrderRequest>(), default))
          .ReturnsAsync(OrderFixtures.ResponseSingle());
    var controller = new OrdersController(facade.Object);

    var result = await controller.Create(OrderFixtures.RequestWithOneItem(), default);

    Assert.IsType<CreatedAtActionResult>(result.Result);
}
```

An optional integration test of the external client can use a fake `HttpMessageHandler`, without calling the real service.
