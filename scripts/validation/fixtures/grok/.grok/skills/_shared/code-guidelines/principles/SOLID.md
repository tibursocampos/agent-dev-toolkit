# SOLID Principles & Code Quality Guidelines

Fundamental software design principles for maintainable, scalable code.

**Stack:** Cross-stack  
**Goal:** Guide implementers and reviewers toward high-quality design

---

## Overview

This directory documents core engineering principles. Deep dives:

### DRY - Don't Repeat Yourself

**File:** [DRY.md](./DRY.md)

- Extract duplicated logic into reusable functions/classes
- Consolidate repeated validation and mapping
- **Threshold:** 3+ similar occurrences -> suggest refactor

```csharp
// Duplication
public void MethodA() { /* validation */ }
public void MethodB() { /* same validation */ }

// DRY
private void Validate() { /* validation */ }
public void MethodA() { Validate(); }
public void MethodB() { Validate(); }
```

### KISS - Keep It Simple, Stupid

**File:** [KISS.md](./KISS.md)

- Prefer simple solutions over premature abstraction
- One clear responsibility per method
- Limit nesting (roughly 3-4 levels)

```csharp
// Over-engineering
public interface ICustomerBuilderFactory { }
public interface ICustomerBuilder { }

// KISS
public Customer CreateCustomer(string name)
{
    return new Customer { Name = name };
}
```

### YAGNI - You Aren't Gonna Need It

**File:** [YAGNI.md](./YAGNI.md)

- Implement only what the current requirement needs
- Avoid speculative fields and unused types
- Create abstractions when need is proven

```csharp
// YAGNI violation
public class Order
{
    public string FutureField1 { get; set; }  // unused today
}

// YAGNI
public class Order
{
    public int Id { get; set; }
    public decimal Total { get; set; }
}
```

### Encapsulation

**File:** [encapsulation.md](./encapsulation.md)

- Group data that travels together
- **Threshold:** 4+ related parameters -> record/class
- Prefer behavior on the object that owns the data

```csharp
// Scattered parameters
public void Process(string name, string email, string phone, string address);

// Encapsulation
public record Customer(string Name, string Email, string Phone, string Address);
public void Process(Customer customer);
```

### SOLID (SRP, OCP, LSP, ISP, DIP)

Apply alongside the files above. Quick reminders:

| Principle | Rule of thumb |
|-----------|----------------|
| **SRP** | One reason to change per type |
| **OCP** | Extend via new types, not endless `if` chains |
| **LSP** | Subtypes must honor base contracts |
| **ISP** | Small, focused interfaces |
| **DIP** | Depend on abstractions at boundaries |

---

## How to use

### During implementation

1. Skim [principles-cheatsheet.md](./principles-cheatsheet.md).
2. Open specific files when the change touches duplication, complexity, dead code, or parameter lists.
3. Self-review before opening a PR.

### During code review

1. Load cheatsheet + relevant principle file.
2. Classify findings: blocking vs suggestion (see each file).
3. Reference the principle file in review comments when helpful.

### Typical severities

| Principle | Default severity |
|-----------|------------------|
| DRY | Suggestion (3+ occurrences) |
| KISS | Blocking if refactor clearly worsens code; else suggestion |
| YAGNI | Blocking for unused types/methods |
| Encapsulation | Suggestion (4+ related parameters) |

---

## Skill integration

| Skill | Phase | Usage |
|-------|-------|-------|
| developer | Step 0.5 | Read before coding |
| implement | Analysis | When design spans multiple types |
| code-review | Review | Validate diff against principles |

---

## Adding a new principle

1. Add `principles/{name}.md` using the same sections as existing files.
2. Update [principles-cheatsheet.md](./principles-cheatsheet.md).
3. Link from this overview if it is a first-class principle.

---

## References

- *Clean Code* - Robert C. Martin
- *The Pragmatic Programmer* - Hunt & Thomas
- *Refactoring* - Martin Fowler
- *Design Patterns* - Gang of Four
