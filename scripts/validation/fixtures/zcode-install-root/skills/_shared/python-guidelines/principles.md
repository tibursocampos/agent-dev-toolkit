# Python Clean Code & Design Principles

Core clean-code principles for Python. Complements `google-style.md`; does not replace framework docs (`fastapi.md`, `flask.md`).

---

## MUST

- Follow Zen of Python intent: explicit over implicit, simple over complex, readability counts.
- Use intention-revealing names; `snake_case` for functions/vars, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.
- Keep functions focused (one responsibility); extract nested unrelated logic.
- Prefer small argument lists; use dataclasses / typed configs / parameter objects when arity grows.
- Catch **specific** exceptions; use exception chaining (`raise X from err`) to preserve context.
- Manage resources with `with` / `async with` context managers.
- Separate business rules from I/O and framework entrypoints (views/handlers stay thin).

---

## MUST NOT

- Use single-letter names except trivial loop indices in short scopes.
- Mutate global state or caller-owned arguments unless that is the documented contract.
- Catch bare `Exception` (or `BaseException`) except at a process/HTTP boundary that logs and translates errors.
- Write complex multi-filter list comprehensions that obscure control flow — use a plain loop or helper.
- Duplicate magic strings/numbers — use named constants matching project style.
- Introduce new architectural layers without an explicit ask — extend what exists.

---

## Prefer when matching repo

### SOLID (Pythonic)

| Principle | Prefer |
|-----------|--------|
| SRP | One reason to change per module/class |
| OCP | Extend via Protocol/strategy, not edit cores blindly |
| LSP | Subtypes honor base contracts |
| ISP | Small `Protocol`s over fat ABCs |
| DIP | Depend on Protocols/ABCs, inject concretes at composition root |

### Idioms

```python
# Prefer simple comprehensions
squares = [x * x for x in range(10)]

# Prefer specific handling + chaining
try:
    raw = load()
except FileNotFoundError as err:
    raise ConfigError("config missing") from err

# Prefer context managers
with open(path, encoding="utf-8") as handle:
    data = handle.read()
```

- Dataclasses / Pydantic / attrs: match the project’s model style for structured data.
- Pure helpers: keep them side-effect free and easy to unit test (`pytest.md`).
- Logging: use the project logger; do not `print` in library/service code when logging exists.

---

## References

- [PEP 20 — The Zen of Python](https://peps.python.org/pep-0020/)
- [PEP 8 — Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [Python docs — Errors and Exceptions](https://docs.python.org/3/tutorial/errors.html)
