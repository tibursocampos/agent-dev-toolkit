# Packaging with pyproject.toml (Python)

> Load when adding dependencies, packaging a library/app, or aligning tool config. Prefer **PEP 621** `pyproject.toml` as the single source of truth when the repo already uses it.

---

## MUST

- Declare project metadata and dependencies in **`pyproject.toml`** (`[project]`) when the repo uses PEP 621 — do not invent a parallel `setup.py`-only story for new work.
- Pin or bound dependency versions consistently with the project’s existing style (exact pins in lockfiles; compatible ranges in libraries).
- Keep runtime deps in `[project].dependencies` and optional extras in `[project.optional-dependencies]`; put dev/test tools in the group the project already uses (`dependency-groups`, `optional-dependencies.dev`, Poetry/PDM groups, etc.).
- Configure pytest, ruff/black/isort, mypy/pyright under `[tool.*]` in the same `pyproject.toml` when those tools are adopted.
- Prefer a lockfile already in the repo (`uv.lock`, `poetry.lock`, `pdm.lock`, `requirements.txt` generated from pyproject) — update it when changing deps.
- Keep package import names stable; match `[project].name` / package directory conventions already present.
- Document the install/run commands the project already uses (`uv sync`, `pip install -e .`, `poetry install`).

---

## MUST NOT

- Add a second packaging tool (Poetry + Hatch + setuptools + PDM) without an explicit ask — match the existing toolchain.
- Commit compiled artifacts, virtualenvs (`.venv/`), or local `.egg-info` that the project gitignores.
- Put secrets, private index credentials, or machine-local paths into committed `pyproject.toml`.
- Duplicate the same dependency in requirements files and pyproject with conflicting versions.
- Use wildcard / unbounded deps (`package`) in apps that already pin for reproducible builds.
- Change build-backend (`setuptools`, `hatchling`, `poetry-core`, `flit`) casually mid-feature.

---

## Prefer when matching repo

| Toolchain signal | Prefer |
|------------------|--------|
| `uv.lock` / `uv` scripts | `uv add` / `uv sync`; keep `[project]` + lock |
| `poetry.lock` | Poetry commands; do not hand-edit lock |
| `pdm.lock` | PDM groups as already defined |
| `requirements*.txt` only | Update those files in the project’s documented way; migrate to pyproject only if asked |
| src layout `src/pkg/` | Keep src layout; configure package-dir accordingly |
| flat `pkg/` next to pyproject | Keep flat layout |

- Entry points: use `[project.scripts]` for CLIs when the project already exposes consolescripts.
- Python version: set `requires-python` to match CI and README; do not raise/lower silently.
- Ruff/Black: one formatter/linter config under `[tool.ruff]` / `[tool.black]` — avoid fighting dual formatters.
- Editable installs: `pip install -e ".[dev]"` or `uv sync --all-extras` per project docs.

### Minimal shape (illustrative)

```toml
[project]
name = "example-app"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
  "fastapi>=0.115",
]

[project.optional-dependencies]
dev = ["pytest>=8", "ruff>=0.8"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```

Match field names and groups to the real file — do not paste this blindly.

### Delivery checklist (deps / packaging)

- [ ] Dependency added in the canonical file (pyproject and/or lock) — not only a local venv
- [ ] `requires-python` still matches CI
- [ ] Dev tools stay in the dev/optional group the repo uses
- [ ] README / Makefile / justfile install commands still work
- [ ] No secrets or private index passwords committed

### Build backends (match repo)

| Backend signal | Keep |
|----------------|------|
| `[build-system] build-backend = "setuptools.build_meta"` | setuptools config / packages.find |
| `hatchling` | `[tool.hatch]` package targets |
| `poetry.core.masonry.api` | Poetry sections — do not dual-write PEP 621 unless Poetry version supports it cleanly |

---

## References

- [PyPA — Writing your pyproject.toml](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
- [PEP 621 — Project metadata](https://peps.python.org/pep-0621/)
- [pip — pyproject.toml](https://pip.pypa.io/en/stable/reference/build-system/pyproject/)
- [uv — Projects](https://docs.astral.sh/uv/concepts/projects/)
