# Python delivery checklist

Index only — open linked docs for detail. Cross-stack defaults: [structure-and-quality.md](../code-guidelines/principles/structure-and-quality.md).

**RN08:** Official language docs (PEP 8) win auxiliary gists/blogs when they conflict. Pointers only — do not paste PEP / gist bodies (`RNF-004`).

---

## Cross-stack

- [ ] Architecture vs style, language, structure, constants, layout — [structure-and-quality.md](../code-guidelines/principles/structure-and-quality.md)
- [ ] Identifiers **English**; comments/docs **mirror** touched area or **ask** on greenfield ([§2](../code-guidelines/principles/structure-and-quality.md))

---

## Official sources (normative)

- [ ] PEP 8 — Style Guide for Python Code: https://peps.python.org/pep-0008/
- [ ] Catalog (normative vs auxiliary): `skills/framework-upgrade/references/sources-catalog.md`

---

## Python core

- [ ] Exceptions / trust boundaries — [principles.md](./principles.md)
- [ ] Style / naming / imports / docstrings — [google-style.md](./google-style.md) (aligned to PEP 8)
- [ ] Typing — [typing.md](./typing.md)
- [ ] Packaging / Ruff / type-checker strictness — [packaging-pyproject.md](./packaging-pyproject.md)
- [ ] Async tasks / bounded I/O — [async-pitfalls.md](./async-pitfalls.md)
- [ ] pytest fixtures / autospec — [pytest.md](./pytest.md)

---

## Framework / architecture (load when applicable)

- [ ] FastAPI — [fastapi.md](./fastapi.md)
- [ ] Flask — [flask.md](./flask.md)
- [ ] Architecture hub (one style) — [architecture.md](./architecture.md)
