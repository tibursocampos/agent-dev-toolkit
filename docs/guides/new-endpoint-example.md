# Exemplo: endpoint novo em .NET

> Exemplo ilustrativo do formato de camadas. Não é código gerado no repositório deste toolkit. Os nomes (`Orders`, `Payments`) são fictícios. Adapte ao padrão do projeto real, que tem precedência.

Este exemplo mostra um endpoint `POST /orders` que cria um pedido e consulta um serviço de pagamento externo. Ele segue a separação em camadas usada em [core/skills/_shared/dotnet-guidelines](../../core/skills/_shared/dotnet-guidelines/). Os trechos são curtos e mostram só o essencial.

## Caminho de chamada

```
HTTP POST /orders
  └─ OrdersController           (entrada HTTP, validação de contrato)
       └─ OrderFacade           (orquestra a operação, traduz DTOs)
            └─ OrderService     (regra de aplicação, transação)
                 ├─ Order       (entidade de domínio, invariantes)
                 └─ IPaymentGatewayClient
                      └─ HttpClient criado por IHttpClientFactory
```

Regra de dependência: o controller conhece o facade. O facade conhece os serviços. Os serviços conhecem as entidades e as interfaces de saída. Nada da camada externa aparece no domínio.

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

O facade não contém regra de negócio. Ele converte o contrato HTTP em comando de aplicação e devolve o DTO de resposta.

## Serviço de aplicação

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

## Entidade

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

Invariantes ficam na entidade, não no controller.

## Cliente externo com HttpClientFactory

Registro:

```csharp
builder.Services.AddHttpClient<IPaymentGatewayClient, PaymentGatewayClient>(client =>
{
    client.BaseAddress = new Uri(configuration["Payments:BaseUrl"]!);
});
```

Cliente:

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

`IHttpClientFactory` gerencia o ciclo de vida dos handlers e evita o esgotamento de sockets. Se o time usar **RestEase**, a interface vira um contrato declarativo e a implementação é gerada. Os testes e a camada de aplicação não mudam.

## Testes

Use o padrão do projeto. O toolkit usa xUnit e Moq em `dotnet-test-patterns.md`.

Teste unitário do facade, com o serviço mockado:

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

Teste unitário do serviço, com repositório e gateway mockados. Verifique a chamada ao gateway e a persistência:

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

Teste de controller, com o facade mockado. Verifique o status HTTP e o contrato de resposta:

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

Teste de integração do cliente externo (opcional) pode usar `HttpMessageHandler` falso, sem chamar o serviço real.
