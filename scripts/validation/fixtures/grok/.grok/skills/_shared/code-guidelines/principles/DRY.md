# DRY Violations (Don't Repeat Yourself)

Detect duplicated code and repeated patterns.

**Stack:** Cross-stack  
**Principle:** DRY (Don't Repeat Yourself)

---

## TL;DR

- **Threshold:** 3+ identical or very similar occurrences -> suggest extraction
- **Severity:** Suggestion (not blocking alone)
- **Do not flag:** 2 occurrences, generated code, distinct test scenarios, documented intentional duplication
- See below for edge cases.

---

## Objective

Find duplication that should be extracted:

- Identical or near-identical blocks
- Repeated return/validation patterns
- Duplicate mappings
- Copy-pasted validation logic

---

## Suggestion - Repeated patterns

### 1. Duplicated code blocks

**Problem:**

```csharp
public void ProcessOrderA(Order order)
{
    ValidateOrder(order);
    var total = order.Items.Sum(i => i.Price * i.Quantity);
    total = total * 0.9m;
    _repository.Save(order);
}

public void ProcessOrderB(Order order)
{
    ValidateOrder(order);
    var total = order.Items.Sum(i => i.Price * i.Quantity);
    total = total * 0.85m;  // only difference
    _repository.Save(order);
}
```

**Solution:**

```csharp
public void ProcessOrder(Order order, decimal discountRate)
{
    ValidateOrder(order);
    var total = order.Items.Sum(i => i.Price * i.Quantity);
    total = total * (1 - discountRate);
    _repository.Save(order);
}
```

**Severity:** Suggestion

### 2. Repeated return pattern

**Problem:** Many similar `Result.Fail` branches in one method.

**Solution:** Consolidate or use a small helper when ≥ 3 repetitions.

**Severity:** Suggestion (≥ 3 repetitions)

### 3. Duplicate mapping

**Problem:** Same DTO mapping inline in multiple places.

**Solution:** Centralize in one mapper method or mapping library.

**Severity:** Suggestion

### 4. Repeated validation

**Problem:** Identical validation in multiple public methods.

**Solution:**

```csharp
private void ValidateEmail(string email)
{
    if (string.IsNullOrEmpty(email))
        throw new ArgumentException("Email required");
    if (!email.Contains('@'))
        throw new ArgumentException("Invalid email");
}
```

**Severity:** Suggestion

---

## Severity table

| Situation | Severity |
|-----------|----------|
| 2 occurrences | Do not comment |
| 3-4 occurrences | Suggestion |
| 5+ occurrences | Suggestion (emphasize) |
| Blocks > 10 lines duplicated | Suggestion |

---

## Exceptions (do not comment)

- Generated code
- Intentional duplication for clarity (documented)
- Only 2 occurrences (minimum threshold is 3)
- Tests with similar setup but different scenarios

---

## References

- *The Pragmatic Programmer* - Hunt & Thomas
- *Clean Code* - Robert C. Martin
- *Refactoring* - Martin Fowler

**Version:** 1.1 (agent-dev-toolkit)
