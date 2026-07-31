# KISS Violations (Keep It Simple, Stupid)

Detect unnecessary complexity.

**Stack:** Cross-stack  
**Principle:** KISS (Keep It Simple, Stupid)

---

## TL;DR

- **Blocking:** refactor that worsens code (more steps, less readable, same behavior)
- **Blocking:** obvious over-engineering (factory-of-factory, unnecessary builder)
- **Suggestion:** method > 50 lines | > 5 parameters | nesting > 3 levels | cyclomatic complexity > 10
- **Do not flag:** long method with clear sequential steps and no branching maze

---

## Objective

Find code that:

- Does the same thing in a harder way without benefit
- Adds abstractions without need
- Combines too many responsibilities in one method
- Uses heavy patterns for simple problems

---

## Blocking - Critical complexity

### 1. Refactor that worsens code

**Problem:** Same behavior, harder implementation.

```csharp
// Before (simple)
var lastItem = collection.Last();

// After (worse)
var count = collection.Count();
var lastItem = collection.ElementAt(count - 1);
```

**Severity:** Blocking

### 2. Over-engineering

**Problem:** Factory + strategy + builder for a trivial object.

```csharp
public interface ICustomerBuilderFactory
{
    ICustomerBuilder CreateBuilder(CustomerType type);
}

// When sufficient:
public Customer CreateCustomer(string name, string email)
{
    return new Customer { Name = name, Email = email };
}
```

**Severity:** Blocking when clearly excessive

---

## Suggestion - Moderate complexity

### 3. Too many responsibilities in one method

Validation, calculation, persistence, notification, and audit in a single method -> extract focused helpers.

**Severity:** Suggestion

### 4. Deep nesting

```csharp
if (a) {
  if (b) {
    if (c) {
      if (d) { /* ... */ }
    }
  }
}
```

**Solution:** Early returns or extracted predicates.

**Severity:** Suggestion (> 3 levels)

---

## Metrics

| Metric | Threshold | Severity |
|--------|-----------|----------|
| Lines per method | > 50 | Suggestion |
| Parameters | > 5 | Suggestion |
| Indentation depth | > 4 | Suggestion |
| Cyclomatic complexity | > 10 | Suggestion |

---

## References

- *Clean Code* - Robert C. Martin
- KISS - Kelly Johnson
- *Refactoring* - Martin Fowler

**Version:** 1.1 (agent-dev-toolkit)
