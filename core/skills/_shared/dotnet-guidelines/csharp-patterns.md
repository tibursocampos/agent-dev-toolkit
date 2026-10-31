# C# Best Practices

> **Highest priority among toolkit style notes.** When this document conflicts with generic best practices, **follow this document**. An explicit operator instruction for the current task outranks this style bar. An order to keep the project pattern means: do not restyle existing members. Record a toolkit divergence in the PLAN and ask project vs toolkit before any restyle. Silence is not approval.
>
> For .NET test naming, structure, fixtures, and assertions, load [`dotnet-test-patterns.md`](./dotnet-test-patterns.md) only when the task includes tests.

---

## C# best practices

### File structure (required - blocking in review)

**Default: one top-level type per `.cs` file** (PRD CA1, RN01). Applies to every new or moved type: `class`, `record`, `sealed class`, `static class`, `struct`, `enum`, and equivalent top-level declarations.

| Rule | Detail |
|------|--------|
| **One file, one top-level type** | Each type lives in its own file (default) |
| **File name** | Match the primary type name (e.g. `OrderService.cs` -> `OrderService`) |
| **Forbidden** | Two or more top-level types in the same file **unless** project escape applies |
| **Project escape** | If the feature folder already colocates related types in one file, match that local colocation — do not invent a new escape |
| **Review** | **Blocking** - reject until types are split (or escape is documented by existing pattern) |

**Allowed exception:** `private` nested types inside the owning top-level type when they are implementation details of that type only (not shared across files). Do not use nested types to avoid creating a dedicated file for a reusable type.

```csharp
// Wrong - two top-level types in OrderHandlers.cs (when project uses one type/file)
public sealed class RegisterOrderHandler { /* ... */ }
public sealed class CancelOrderHandler { /* ... */ }

// Correct - one type per file
// RegisterOrderHandler.cs
public sealed class RegisterOrderHandler { /* ... */ }

// CancelOrderHandler.cs
public sealed class CancelOrderHandler { /* ... */ }

// Correct - private nested type as implementation detail
public sealed class OrderPricingService
{
    private sealed class LineItemAccumulator
    {
        public decimal Total { get; private set; }
    }
}
```

### Source language (comments / docs) (required - blocking in review)

| Situation | Rule |
|-----------|------|
| Touched area already pt-BR | Keep comments/XML docs in **pt-BR** |
| Touched area already EN | Keep comments/XML docs in **EN** |
| Greenfield / no clear mirror | **Ask** the user before writing narrative comments/docs |
| User override | User choice wins for that task |
| Identifiers | Always **English** (types, members, params, files) |

Cross-stack profile: `code-guidelines/principles/structure-and-quality.md` §2.

### Method signatures and invocations (required - blocking in review)

**Same formatting rules for method declarations and method invocations** (PRD CA2, CA3, RF02, RF03, RN02). Applies inside any method body when calling another method, constructor, or delegate.

| Condition | Format |
|-----------|--------|
| **Inline (single line)** | Up to **6** parameters **and** the full declaration or invocation line is **≤ 160 characters** |
| **Multiline (required)** | **More than 6** parameters **or** the full line **exceeds 160 characters** -> **one parameter per line** |
| **Review** | **Blocking** - request reformat before merge |

**Character count:** Count the **entire physical line** of the signature or invocation (from the start of the return type / access modifier through the closing `)` and `;` or `{`). Include generic type arguments, parameter types, names, default values, and `CancellationToken cancellationToken = default`.

**Do not** break signatures across multiple lines for style only when the inline rule still applies.

**Override:** only when the consumer `AGENTS.md` (or a versioned guideline in that repo) redefines the thresholds explicitly.

**Alignment with `KISS.md`:** Cross-stack KISS lists **> 5 parameters** as a *suggestion*. For **C# in this toolkit**, the 6-parameter / 160-character / >6-parameter rules here are **normative** and override generic KISS guidance on formatting.

**Formatter:** Layout (braces, indent, general wrapping) is owned by **CSharpier** - see `csharp-formatting.md`. This section is the human/agent MUST for parameter count and the 160-character signature/invocation threshold. **CSharpier must not “win” over this MUST** — if the formatter wraps a line that still satisfies ≤6 parameters and ≤160 characters, re-inline before merge.

```csharp
// Correct - inline (≤ 6 parameters, line ≤ 160)
public async Task<ImageStorageUploadResult> UploadGeneratedImageAsync(ImageStorageUploadRequest request, CancellationToken cancellationToken = default)

// Correct - inline invocation
var order = await _orderRepository.GetByIdAsync(id, cancellationToken);

// Correct - inline (6 parameters, line ≤ 160)
public void ApplyWindow(int startInclusive, int endExclusive, bool inclusiveBounds, string label, int priority, bool dryRun)

// Required - multiline (more than 6 parameters)
public async Task<OrderSummary> BuildOrderSummaryAsync(
    int orderId,
    string customerCode,
    DateTime fromDate,
    DateTime toDate,
    bool includeCancelled,
    string warehouseCode,
    CancellationToken cancellationToken = default)

// Required - multiline invocation (same rule)
await _notificationService.SendOrderStatusChangedAsync(
    order.Id,
    order.CustomerId,
    previousStatus,
    order.Status,
    correlationId,
    warehouseCode,
    cancellationToken);

// Required - multiline (line > 160 even with ≤ 6 parameters)
public Task<IReadOnlyList<OrderLineProjection>> GetOrderLinesWithExtendedFiltersAsync(
    int orderId,
    IReadOnlyCollection<string> statusCodes,
    CancellationToken cancellationToken = default)

// Wrong - unnecessary break when inline rule applies
public async Task<Order?> GetByIdAsync(
    int id,
    CancellationToken cancellationToken = default)

// Wrong - more than 6 parameters must multiline even when the line is ≤ 160
await _integrationClient.PostOrderExportAsync(orderId, customerId, warehouseId, routeId, shipmentId, carrierId, cancellationToken);
```

### Architecture vs style (required - blocking in review)

Before adding types, handlers, validators, or helpers, **discover how the repository already solves the same problem** (PRD CA4, RF04, RN03). Use **Glob** and **Read** on similar files (same layer, feature folder, naming suffix).

| Concern | Rule |
|---------|------|
| **Architecture (mirror)** | Match folder layout, namespaces, DI registration, and class/handler flows — discover first; no parallel path |
| **Established project style** | Match the touched type and its neighbors. Adding a member does not authorize rewriting the rest of the type |
| **Reuse consolidated patterns** | If the project uses FluentValidation, CQRS handlers, repository interfaces, etc., extend that pattern |
| **Forbidden** | Parallel flows when a consolidated approach already exists (e.g. inline `if` validation when commands use `AbstractValidator`) |
| **Class flow** | Reuse existing `private` methods in the same class before duplicating logic in a new helper or type |
| **Toolkit style** | New code only, and only when the area has no local pattern or the operator explicitly chose the toolkit for this change |
| **Review** | **Blocking** - reject a second architectural path, a restyle of existing members without an explicit yes, or new code that follows neither the project pattern nor an approved toolkit choice. Leaving the project's existing literals is not a failure |

**Cross-reference:** Layer rules, mandatory Command/Handler/Validator flow, and FluentValidation-only validation are in `clean-architecture.md` (§ Mandatory implementation flow, § Validation). Cross-stack: `structure-and-quality.md` §1.

```csharp
// Wrong - manual validation in handler when project uses FluentValidation
// (intentional anti-pattern: magic string illustrates forbidden inline validation, not named-constants compliance)
public async Task<Result> Handle(RegisterOrderCommand command, CancellationToken cancellationToken)
{
    if (string.IsNullOrWhiteSpace(command.OrderNumber))
        return Result.Error("Order number is required");
    // ...
}

// Correct - validator owns rules; handler orchestrates
public class RegisterOrderCommandValidator : AbstractValidator<RegisterOrderCommand>
{
    public RegisterOrderCommandValidator()
    {
        RuleFor(c => c.OrderNumber).NotEmpty();
    }
}

// Wrong - new static helper duplicating logic already on the class
private decimal CalculateLineTotal(OrderLine line) => line.Quantity * line.UnitPrice;
// ... elsewhere in same class, same calculation copied again

// Correct - one private method, reused by public entry points
private decimal CalculateLineTotal(OrderLine line) => line.Quantity * line.UnitPrice;

public decimal GetOrderSubtotal(IReadOnlyList<OrderLine> lines) =>
    lines.Sum(CalculateLineTotal);
```

Do not add architectural layers, projects, or folders without explicit user approval - extend what already exists.

### Named constants (no magic literals)

For **new** code, when the operator chose the toolkit or the area has no local pattern, every **string and number** in production code must be a **named constant** with a clear English identifier (PRD CA6, RF06-RF08, RN05-RN07). That includes error messages, log messages and templates, FluentValidation rules, configuration keys, HTTP status codes, query keys, templates, and exception text.

Existing literals stay until the operator approves extracting them. Touching a type to add a member is not that approval. A new constant in the type does not require extracting the other literals already there.

| Rule | Detail |
|------|--------|
| **No magic literals** | On new code under an approved toolkit choice, or where no local pattern exists: no raw `"..."` or numeric literals with semantic meaning |
| **Existing members** | Leave the project's literals in place. Do not extract them as a side effect of editing the file |
| **Consistency in a type** | Match the style that type already uses. Do not mix a new constant into a literal-style type, and do not sweep the type to constants, unless the operator chose the toolkit |
| **Naming** | **PascalCase** for all `const` identifiers (production and tests). **Forbidden:** `UPPER_SNAKE_CASE` |
| **Reuse first** | Grep/search project `Constants`, message types, and domain files before adding a new constant |
| **Location (local)** | `private const` in the owning class when the value is used in **one** type only (internal service message, local prop/route name, one-off template) - **do not** create a dedicated constants file for non-reusable values |
| **Location (shared)** | Public/shared type (e.g. `Constants` **partial** under Models/Domain) only when the value is **reused or clearly intended for reuse** across classes |
| **Shared file size** | Watch growth of shared constants types; prefer **`partial class`** by responsibility and section grouping via **`#region`** or comment headers - avoid a single monolithic constants dump |
| **No duplication** | Do not copy the same literal into multiple classes or constant files - one canonical definition |
| **Review** | **Blocking** for new literals when the toolkit style was chosen or no local pattern exists. Do not demand extraction of pre-existing project literals unless the operator approved that restyle. Flag unnecessary shared-file churn for one-off values |

**Allowed exception (CA6.1, CT7):** In an arithmetic expression, a **numeric multiplier factor** may stay inline when it is the only literal in that expression (e.g. unit conversion `bytes * 1024`). Other operands with business meaning (limits, thresholds, status codes) still require named constants.

**Alignment with other toolkit docs:** `code-review` (maintainability / magic values) and `scaffold-message-handler/reference.md` (configuration queue names) defer to this section as the **canonical** C# rule - do not contradict it in reviews or scaffolds.

```csharp
// Wrong - magic strings and numbers in production
_logger.LogWarning("Order {Id} not found", orderId);
return Result.NotFound("Order not found");
RuleFor(x => x.Quantity).LessThan(0).WithMessage("Quantity must be non-negative");
var section = configuration.GetSection("OrderProcessing");
return StatusCode(404);

// Correct - local one-off: private const on the owning class (not a shared Constants file)
private const string OrderNotFoundLogTemplate = "Order {OrderId} not found";
private const string OrderNotFoundMessage = "Order not found";
private const int MinimumQuantity = 0;
private const string OrderProcessingSectionKey = "OrderProcessing";
private const int NotFoundStatusCode = StatusCodes.Status404NotFound;

_logger.LogWarning(OrderNotFoundLogTemplate, orderId);
return Result.NotFound(OrderNotFoundMessage);
RuleFor(x => x.Quantity).GreaterThanOrEqualTo(MinimumQuantity);
var section = configuration.GetSection(OrderProcessingSectionKey);
return StatusCode(NotFoundStatusCode);

// Correct - shared only when reused across types (prefer partial by responsibility)
public static partial class OrderConstants
{
    public const string OrderNotFoundMessage = "Order not found";
}

// Allowed - multiplier only (CA6.1)
var sizeInKilobytes = sizeInBytes * 1024;

// Wrong - semantic limit should be a constant, not inline 100
if (order.Lines.Count > 100)

// Correct
private const int MaxOrderLines = 100;
if (order.Lines.Count > MaxOrderLines)

// Wrong - mix inline log string with const in the same type
private const string OrderNotFoundMessage = "Order not found";
_logger.LogWarning("Order {Id} not found", orderId); // extract this too

// Wrong - UPPER_SNAKE_CASE
public const string DEFAULT_ORDER_NUMBER = "ORD-001";

// Correct
public const string DefaultOrderNumber = "ORD-001";

// Wrong - one-off service message forced into a shared Constants file with no reuse
// Correct - keep private const on that service class until a second consumer appears
```

### Blank lines and layout (required - blocking in review)

| Forbidden | Allowed |
|-----------|---------|
| Blank line between every statement | Blank lines **only** between logical member groups (fields / ctors / methods) |
| Unnecessary double-blank lines | Single blank between groups when needed |

Do not leave blank-spam in touched methods. Cross-stack: `structure-and-quality.md` §5.

### Readable construction (required when multi-arg harms readability)

| Prefer | Avoid |
|--------|-------|
| Named local before a multi-arg `new`/object initializer when inline harms readability | Mandatory builders for one-off construction |
| Builders only when reuse justifies (KISS) | Over-abstracted construction for a single call site |

```csharp
// Prefer when multi-arg new is hard to read
var request = new ImageStorageUploadRequest
{
    FileName = fileName,
    ContentType = contentType,
    Payload = payload
};
await _uploader.UploadAsync(request, cancellationToken);

// Wrong - invent a builder for a single call site with no reuse
```

Cross-stack: `structure-and-quality.md` §7.

### Method ordering within classes (required - blocking in review)

Within each class, organize **methods** (PRD CA5, RF05, RN04) in this **exact sequence** - agents, implementation, and code review must obey it:

1. All **public** methods, ordered **alphabetically by method name** (case-insensitive).
2. Then all **private** methods, ordered **alphabetically by method name** (case-insensitive).

| Rule | Detail |
|------|--------|
| **Visibility blocks** | All **public** methods before all **private** methods - never interleave |
| **Alphabetical order** | Within the public block and within the private block, order methods **alphabetically by method name** |
| **New or moved methods** | Insert at the correct position in the block - do not append out of order |
| **Review / implementation** | **Blocking** - request reorder before merge; do not ship new methods at the bottom of the wrong block |

**Sort key:** Use the method name only (ignore parameters). Applies to instance and static methods in each visibility block.

**Discover first:** If the class or feature folder already uses a documented ordering (e.g. constructors grouped at the top of the public block), match that **existing project pattern** after Glob/Read - do not fight a consolidated local convention unless the PR standardizes it. Otherwise apply the public-then-private alphabetical sequence above.

```csharp
// Wrong - private before public; methods out of alphabetical order
public sealed class OrderService
{
    private void ValidateOrder(Order order) { }

    public async Task<Order?> GetByIdAsync(int id, CancellationToken cancellationToken = default) { }

    public async Task RegisterAsync(RegisterOrderCommand command, CancellationToken cancellationToken = default) { }

    private decimal CalculateTotal(Order order) { }
}

// Correct - public block (alphabetical), then private block (alphabetical)
public sealed class OrderService
{
    public async Task<Order?> GetByIdAsync(int id, CancellationToken cancellationToken = default) { }

    public async Task RegisterAsync(RegisterOrderCommand command, CancellationToken cancellationToken = default) { }

    private decimal CalculateTotal(Order order) { }

    private void ValidateOrder(Order order) { }
}
```

**Normative sections in this file (pre-PR and code review):** File structure · Source language · Method signatures and invocations · Architecture vs style · Named constants · Blank lines · Readable construction · Method ordering (this section).

### Runtime and modern C# (companion file)

Async/await, modern C# features, nullable reference types, records, dependency injection, IOptions, and resource management live in [`csharp-patterns-runtime.md`](./csharp-patterns-runtime.md). Load it when the step touches those topics.

## .NET tests (just-in-time reference)

When creating, changing, or reviewing tests, load [`dotnet-test-patterns.md`](./dotnet-test-patterns.md). This file keeps production C# conventions; test framework, naming, structure, fixtures, assertions, and anti-patterns live in the focused test guide.
