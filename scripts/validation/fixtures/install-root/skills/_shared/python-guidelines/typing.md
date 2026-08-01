# Typing guidelines (Python)

> Load when adding or tightening type hints, configuring mypy/pyright, or reviewing public APIs. Pair with `google-style.md` for naming/docstrings.

---

## MUST

- Annotate **public** function signatures (parameters and return types) on new and touched code.
- Prefer modern built-ins (`list[str]`, `dict[str, int]`, `X | None`) on Python 3.10+ codebases; use `typing.Optional` / `List` only when the project still targets older syntax.
- Use `TypedDict`, `dataclass`, Pydantic models, or attrs consistently with neighbors for structured data — do not invent a parallel shape system.
- Prefer `Protocol` for structural dependencies (DIP) when the project already uses Protocols or when a small interface avoids a heavy ABC.
- Run the project’s type checker (`mypy`, `pyright`, `ty`) with the existing config; fix errors in changed files rather than silencing globally.
- Type async functions as returning `Coroutine`/`Awaitable` via `async def` → inferred `Coroutine`; annotate returned payloads explicitly (`async def f() -> UserDto`).
- Keep annotations and stub comments in **English**.

---

## MUST NOT

- Use bare `Any` to silence checker noise on new public APIs — prefer `object`, generics, or `Unknown`-style narrowing.
- Add `# type: ignore` without a specific error code and a short reason when the project requires coded ignores.
- Mix Pydantic v1 and v2 typing helpers in the same module.
- Annotate with incorrect types “to make CI green” (lying annotations).
- Import heavy runtime-only modules only for typing without `TYPE_CHECKING` guards when that is the project pattern and import cycles appear.
- Weaken `mypy`/`pyright` strictness in config for a single feature without explicit ask.

---

## Prefer when matching repo

| Situation | Prefer |
|-----------|--------|
| FastAPI / Pydantic | Model fields and validators; let FastAPI use annotations for OpenAPI |
| Flask + Marshmallow | Keep Marshmallow schemas; add hints on services/domain |
| Internal helpers | Annotate when non-obvious; match neighbor density |
| Collections | `Sequence` / `Mapping` for inputs; `list` / `dict` for concrete owned data |
| Callables | `Callable[[Arg], Ret]` or `Protocol` with `__call__` |
| Generics | `TypeVar` with bounds; Python 3.12+ `type` params if repo uses them |

- Config: respect `[tool.mypy]`, `[tool.pyright]`, or `pyrightconfig.json` already present.
- Gradual typing: do not demand 100% coverage on legacy modules in one PR — raise the waterline on touched paths.
- `cast()`: rare; prefer narrowing with `isinstance` / TypeGuards (`TypeGuard` / `TypeIs`).
- Forward refs: use `from __future__ import annotations` when the project already does.

### Examples

```python
from typing import Protocol

class UserRepository(Protocol):
    def get_by_id(self, user_id: int) -> User | None: ...

def active_names(users: Sequence[User]) -> list[str]:
    return [u.name for u in users if u.is_active]
```

```python
# Prefer
def find(name: str) -> User | None: ...

# Avoid on 3.10+ codebases that already use modern syntax
from typing import Optional, List
def find(name: str) -> Optional[User]: ...
```

### Public API checklist

- [ ] Every new public function has param + return annotations
- [ ] Containers use precise value types (`list[User]`, not bare `list`)
- [ ] External JSON/dict boundaries use TypedDict / Pydantic / validated models
- [ ] No new bare `Any` on exports without a comment and tracker
- [ ] Type checker clean on touched paths under existing config

### `TYPE_CHECKING` pattern (when repo uses it)

```python
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from myapp.services import OrderService
```

---

## References

- [typing — Support for type hints](https://docs.python.org/3/library/typing.html)
- [mypy — Type system reference](https://mypy.readthedocs.io/en/stable/type_system_reference.html)
- [Pyright — Type concepts](https://microsoft.github.io/pyright/#/type-concepts)
- [PEP 484 — Type Hints](https://peps.python.org/pep-0484/)
