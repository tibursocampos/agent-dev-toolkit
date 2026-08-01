# pytest defaults (Python)

> Default test runner for `/python-developer`. Match the project's existing fixtures and layout; prefer **pytest** on greenfield.

---

## MUST

- Use **pytest** for new greenfield Python tests unless the repo already standardizes on unittest-only suites.
- Put shared fixtures in `conftest.py` or a dedicated test-support / `TestInfrastructure`-style package — do not copy-paste arrange blocks.
- Structure each test with clear **Arrange / Act / Assert** (use `//`-style section comments only if the repo uses comments; otherwise keep the three phases obvious).
- Name tests to describe behavior: `test_<result>_when_<condition>` or `Should_<Result>_When_<Condition>` matching repo style.
- Prefer **integration tests** for real request/DB flows when the project already supports them; unit-test pure logic at boundaries.
- One behavior per test; avoid loops or branching that hide which assertion failed.
- Keep test identifiers and comments in **English**.
- Run targeted pytest for changed modules before handoff.

| Prefer | Avoid |
|--------|-------|
| Shared fixtures / fakes builders | Copy-paste arrange in every test |
| Arrange / Act / Assert | Giant monolithic unrelated suites |
| Integration for real HTTP/DB paths | Mocking everything when a focused integration path exists |
| Descriptive names | Vague names (`test1`, `test_works`) |

---

## MUST NOT

- Introduce unittest-only suites for new greenfield work when pytest is available.
- Hide domain arrange builders as private helpers inside every test class — centralize fakes/fixtures.
- Assert only that “lines ran” without checking observable behavior.
- Depend on test order, shared mutable module state, or wall-clock `time.sleep` without project justification.
- Commit secrets or real credentials into fixtures; use env overrides / factories.
- Skip failing tests without a tracked reason (`pytest.mark.skip` abuse).

---

## Prefer when matching repo

| Stack | Typical client |
|-------|----------------|
| FastAPI | `TestClient` / `httpx` ASGI transport |
| Flask | Flask test client |
| Pure logic | Direct calls; no web client |

- Config: reuse `pytest.ini`, `[tool.pytest.ini_options]`, or existing `conftest.py` markers.
- Async: use the project’s `pytest-asyncio` (or equivalent) mode (`auto` / `strict`) — do not invent a second async plugin.
- Coverage / markers: enable `pytest-cov`, `-m` only when already configured.
- Parametrize with `@pytest.mark.parametrize` for combinatorial inputs instead of duplicated tests.
- Factories: prefer factory-boy / polyfactory / custom `*Fake` modules when the repo already has them.

### Project signals

- `pytest` in `pyproject.toml` / `requirements*.txt` / `Pipfile`
- Config: `pytest.ini`, `[tool.pytest.ini_options]`, or `conftest.py`
- Naming: `test_*.py` / `*_test.py` and `test_*` / `Test*` classes

---

## Commands

```bash
pytest
pytest path/to/test_module.py -k Should_Or_test_name
```

Add coverage / markers only when the project already configures them.

---

## Delivery checklist (tests)

- [ ] New or changed behavior has failing-then-passing tests (or updated assertions)
- [ ] Fixtures reused — no duplicated arrange logic
- [ ] Async tests use the project's pytest-asyncio (or equivalent) pattern when needed
- [ ] Targeted pytest green for changed code before handoff

---

## References

- [pytest — Get Started](https://docs.pytest.org/en/stable/getting-started.html)
- [pytest — Fixtures](https://docs.pytest.org/en/stable/explanation/fixtures.html)
- [pytest — How to parametrize](https://docs.pytest.org/en/stable/how-to/parametrize.html)
- [pytest-asyncio](https://pytest-asyncio.readthedocs.io/en/latest/)
