# YAGNI Violations (You Aren't Gonna Need It)

Detect unused or speculative code.

**Stack:** Cross-stack  
**Principle:** YAGNI (You Aren't Gonna Need It)

---

## TL;DR

- **Blocking:** class, method, variable, or parameter declared but never referenced
- **Blocking:** field added for “future integration” without a current requirement
- **Do not flag:** generated code, loop variables, interface-required parameters
- See below for borderline cases.

---

## Objective

Find code written for hypothetical future use or left unused:

- Types never instantiated or referenced
- Variables never read
- Parameters never used
- Private methods never called

---

## Blocking - Critical dead code

### 1. Unused class / record / interface

**Problem:** New type in diff with no references elsewhere.

**Severity:** Blocking

### 2. Uncalled private method

**Problem:** Private method added but never invoked.

**Severity:** Blocking

---

## Suggestion - Minor dead code

### 3. Variable never read

**Problem:** Assigned value never used.

**Severity:** Suggestion

### 4. Unused parameter

**Problem:** Parameter not used in method body.

**Exceptions (do not comment):**

- Discarded parameters (`_` prefix)
- Interface contract parameters
- Standard event handler signatures

**Severity:** Suggestion

---

## Diff hints

```regex
^\+.*class\s+\w+
^\+.*record\s+\w+
^\+.*interface\s+\w+
private\s+\w+\s+\w+\s*\(
```

---

## Severity table

| Type | Severity |
|------|----------|
| Unused class/record | Blocking |
| Uncalled private method | Blocking |
| Unused variable | Suggestion |
| Unused parameter | Suggestion |

---

## References

- Martin Fowler - YAGNI
- *Clean Code* - Robert C. Martin

**Version:** 1.1 (agent-dev-toolkit)
