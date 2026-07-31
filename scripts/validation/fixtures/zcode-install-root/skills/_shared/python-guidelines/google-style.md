# Google Python Style & Coding Conventions

Style conventions adapted from Google's Python Style Guide. Light companion to `principles.md` and `typing.md`.

---

## MUST

- Use **4 spaces** per indentation level; never tabs.
- Keep imports on separate lines; group **stdlib → third-party → local**, with a blank line between groups.
- Forbid wildcard imports (`from module import *`).
- Use naming: modules/packages `snake_case`; classes `PascalCase`; functions/vars `snake_case`; constants `UPPER_SNAKE_CASE`; non-public with leading `_`.
- Prefer type annotations on public signatures (see `typing.md`); run the project type checker when configured.
- Use Google-style docstrings (`"""` with Args / Returns / Raises) for public modules, classes, and functions when the project already documents that way — match neighbor density.
- Keep identifiers and docstrings in **English**.

---

## MUST NOT

- Exceed the project's line-length tool config; when none exists, prefer **80** columns for new pure-style edits unless Black/Ruff already set a wider limit — then **match the formatter**.
- Put spaces immediately inside `()`, `[]`, or `{}` beyond project formatter rules.
- Leave trailing whitespace.
- Use `I`-prefixed interface names or Java-style Hungarian notation.
- Silence formatter/linter locally without following repo ignore patterns.

---

## Prefer when matching repo

- **Black / Ruff format**: defer to `[tool.black]` / `[tool.ruff]` over manual 80-col wrapping fights.
- **isort / Ruff isort**: use the project's profile (`google`, `black`) rather than hand-ordering.
- Docstrings: if neighbors omit Args sections on tiny helpers, stay consistent — do not essay every private function.
- Type imports: prefer built-in generics on 3.9+ / 3.10+ as in `typing.md`.
- Exceptions in docstrings: document only exceptions callers are expected to handle.

### Naming quick reference

| Kind | Form |
|------|------|
| Module / package | `module_name.py`, `package_name` |
| Class | `ClassName` |
| Function / method / variable | `function_name`, `variable_name` |
| Constant | `CONSTANT_NAME` |
| Internal | `_private_attribute` |

### Docstring sketch

```python
def calculate_discount(price: float, discount_rate: float) -> float:
    """Calculates the final price after applying a discount rate.

    Args:
        price: The original price of the item.
        discount_rate: The rate of the discount (between 0.0 and 1.0).

    Returns:
        The discounted price.

    Raises:
        ValueError: If the discount rate is outside the valid range.
    """
    if not (0.0 <= discount_rate <= 1.0):
        raise ValueError("Discount rate must be between 0.0 and 1.0")
    return price * (1.0 - discount_rate)
```

---

## References

- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [PEP 8 — Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [Ruff — The Ruff Formatter](https://docs.astral.sh/ruff/formatter/)
