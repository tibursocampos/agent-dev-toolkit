# Encapsulation Patterns

Identify opportunities to group related data and behavior.

**Stack:** Cross-stack  
**Principle:** Encapsulation and cohesion

---

## TL;DR

- **Threshold:** 4+ semantically related parameters -> suggest record/class
- **Severity:** Suggestion
- **Do not flag:** unrelated parameter types, DI constructors with many services (normal in layered apps)
- See below for grouping examples.

---

## Objective

Find cases where:

- Related data should live in one object
- Intermediate variables could use narrower scope
- Calculations belong on the domain object

---

## Suggestion - Encapsulation opportunities

### 1. Many related parameters

**Problem:**

```csharp
public void ProcessOrder(
    string customerName,
    string customerEmail,
    string customerPhone,
    string shippingStreet,
    string shippingCity,
    string shippingZip)
```

**Solution:**

```csharp
public record CustomerInfo(string Name, string Email, string Phone);
public record ShippingAddress(string Street, string City, string Zip);

public void ProcessOrder(CustomerInfo customer, ShippingAddress shipping)
```

**When to comment:** ≥ 4 related parameters  
**Severity:** Suggestion

### 2. Data that always travels together

**Problem:** Same parameter pairs repeated with duplicate range checks.

**Solution:** Introduce a small type (e.g. `DateRange`) with validation in the constructor.

**Severity:** Suggestion

### 3. Calculations outside the owning object

**Problem:** Totals computed from `order.Items` in external procedural code.

**Solution:** Expose `Subtotal`, `Discount`, `Total` on `Order`.

**Severity:** Suggestion

---

## Metrics

| Situation | Severity |
|-----------|----------|
| 4-5 related parameters | Suggestion |
| 6+ related parameters | Suggestion (emphasize) |
| Same tuple in 3+ methods | Suggestion |

---

## References

- *Clean Code* - Robert C. Martin
- *Refactoring* - Fowler (Introduce Parameter Object)
- *Domain-Driven Design* - Eric Evans

**Version:** 1.1 (cursor-dev-toolkit)
