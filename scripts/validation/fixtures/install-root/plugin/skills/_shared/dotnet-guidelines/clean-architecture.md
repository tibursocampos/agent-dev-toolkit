# Clean Architecture - .NET

> **Highest priority.** When this document conflicts with generic best practices, **always follow this document**.

---

## Layer structure

```
src/
├── Domain/                    # Entities, value objects, interfaces
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Interfaces/
│   └── Exceptions/
├── Application/               # Use cases, commands, validators, responses
│   ├── Commands/
│   ├── Validators/
│   ├── DTOs/
│   ├── Interfaces/
│   └── Mappings/
├── Infrastructure/            # Implementations, repositories, external services
│   ├── Repositories/
│   ├── ExternalServices/
│   ├── Persistence/
│   └── Configurations/
└── API/                       # Controllers, middleware
    ├── Controllers/
    ├── Middlewares/
    ├── Filters/
    └── Extensions/

tests/
├── Unit/
│   ├── Domain/
│   ├── Application/
│   └── Fixtures/
└── Integration/
    ├── API/
    ├── Infrastructure/
    └── Fixtures/
```

---

## Mandatory implementation flow

For each new feature:

1. Check whether a similar implementation already exists.
2. Follow this structure exactly:
   - **Command**
   - **CommandHandler**
   - **Validator** (FluentValidation)
   - **Response**
3. Do not invent variations of this structure.
4. Do not change code outside the requested scope.

Layer flow:

```
Controller -> Application -> Domain -> Infrastructure
```

- Controllers **must not** contain business rules.
- Controllers **must not** access the database directly.
- Business rules belong in **Domain**.
- Persistence belongs in **Infrastructure**.
- **Application** orchestrates use cases.

---

## Implementation order

1. **Domain**: entities and interfaces first
2. **Application**: commands, validators, responses
3. **Infrastructure**: repositories and implementations
4. **API**: controllers and configuration
5. **Tests**: unit and integration

---

## Dependency rules

- **Domain** has no external dependencies.
- **Application** depends only on **Domain**.
- **Infrastructure** implements **Domain** interfaces.
- **API** references only **Application**.

---

## Validation (FluentValidation)

- All validation uses **FluentValidation**.
- Forbidden in: controllers, command handlers, entities.
- Each command has its own validator.
- Do not use DataAnnotations.
- Do not use inline validation.

Expected naming:

- `RegisterOrderCommand`
- `RegisterOrderCommandValidator`

**Follow existing project patterns (blocking in review):** Before implementing validation, handlers, repositories, or controller actions, use Glob/Read on similar types in the same layer and feature area. Do not introduce manual validation in handlers, ad-hoc DTO checks in controllers, or duplicate private logic when the repository already has a consolidated pattern. Full rules, examples, and review criteria: `csharp-patterns.md` - § **Follow existing project patterns** (PRD CA4, RN03).

---

## Naming

- Methods and properties in **English**.
- Class names must be clear and specific.
- Avoid generic names: `Helper`, `Utils`, `Manager`, `GenericService`.

---

## Guard clauses (required)

Always apply **replace nested conditionals with guard clauses**.

- Avoid deeply nested `if` blocks.
- Validate invalid conditions at the start of the method.
- Return immediately when an invalid condition is detected.

**Wrong:**

```csharp
if (order != null)
{
    if (order.IsActive)
    {
        if (order.Lines.Any())
        {
            ...
        }
    }
}
```

**Correct:**

```csharp
if (order == null)
    return Result.Error("Order not found");

if (!order.IsActive)
    return Result.Error("Order is inactive");

if (!order.Lines.Any())
    return Result.Error("Order has no lines");

...
```

---

## SOLID principles

### Single responsibility

- Each class has one responsibility.
- A class must not validate, persist, and execute business rules at the same time.

### Dependency inversion

- Depend on interfaces when domain rules require abstraction.
- Do not instantiate dependencies manually.
- Use dependency injection.

### Clean code

- Keep methods small and focused.
- Avoid duplication.
- Code should be self-explanatory - do not comment around poorly written code.

---

## Prohibitions

- Unnecessary abstractions.
- Generic classes without a clear purpose.
- Changing the existing architectural structure without explicit approval.
- Business logic in controllers.
- Validation outside FluentValidation.
