# Step 0.5: Review code guidelines

**Required** before writing production code (~3-5 minutes). Reduces rework in review.

Load **only** what the task needs. Paths assume install via `scripts/sync-agent.ps1` (host adapter sync); shared packs land under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/`.

---

## 1. Principles (always - one file)

Read a single principles file when available:

- `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/code-guidelines/principles/principles-cheatsheet.md`

If missing (before ETAPA 11), skip and rely on project `docs/` and stack guidelines below.

Do **not** glob all of `code-guidelines/`.

### 1b. Architecture style (greenfield / ARCH)

| Situation | Load |
|-----------|------|
| Greenfield or ARCH/CONTINUITY needs style selection | Cheatsheet + `principles/architecture-selection.md` |
| ARCH already **approved** with a named style | Cheatsheet + **exactly one** matching style file (stack overlay and/or `principles/architecture/<style>.md`) |
| Brownfield and ARCH omits style | Discover-first from the repo; do **not** invent a silent default |

**MUST NOT:** glob `architecture/**` or preload every style. One style per task (optional companions only when ARCH selected them — e.g. DDD/EDA overlays).

---

## 2. .NET (when `*.sln` or `*.csproj` in scope)

| Need | Path |
|------|------|
| Layers / rings (ARCH = concentric / CA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/clean-architecture.md` |
| Vertical slice (ARCH = VSA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/vertical-slice.md` |
| Tactical DDD (ARCH = ddd) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/ddd-tactical.md` |
| Event-driven (ARCH = EDA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/event-driven.md` |
| Tests (xUnit, Moq, Shouldly, `Should_<R>_When_<C>`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| **Structure and formatting** (one type per file, signatures/150 chars, constants, method order) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md` - normative §§ File structure, Method signatures, Follow existing patterns, Named constants, Method ordering |
| Pre-PR gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/checklist.md` |

Quick checks (always apply):

- [ ] No hardcoded secrets (keys, passwords, connection strings with real values)
- [ ] External input validated
- [ ] Parameterized queries - no string concatenation for SQL
- [ ] New packages checked for known vulnerabilities when adding dependencies

---

## 3. Web / frontend (when UI or browser code in scope)

| Need | Path |
|------|------|
| Engineering core (not visual design) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE folder layout (ARCH / CONTINUITY) | Prefer `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/frontend-guidelines/frontend-architecture.md` — not a full CA tree per framework |
| Markup / CSS / SCSS | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/` |
| Cross-stack tests | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/frontend-guidelines/frontend-testing.md` |
| React | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/react-guidelines/` |
| Angular | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/angular-guidelines/` |
| Vue | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/vue-guidelines/` |
| Blazor | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/blazor-guidelines/` |
| Electron | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/electron-guidelines/` |
| Vanilla / DOM | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/dom-patterns.md` |

Visual decisions: `docs/DESIGN-BRIEF.md` or `/impeccable` - do not invent palette/typography from generic guidelines.

## 4. Other stacks

Use project `docs/` and the parent skill. Examples:

| Stack | Typical docs |
|-------|----------------|
| Node (non-UI) | `javascript-guidelines/node-backend.md` + **one** `javascript-guidelines/architecture/<style>.md` from ARCH |
| Java | `java-guidelines/` pack rows + **one** `java-guidelines/architecture/<style>.md` from ARCH |
| Python | `python-guidelines/architecture.md` + **one** `principles/architecture/<style>.md` when ARCH names a style |
| Config / tooling | `README`, `eslint` / `prettier`, `pyproject.toml`, `ruff` / `mypy` as needed |

Same rule: **MUST NOT** glob `architecture/**`.

---

## 5. Security (all stacks)

Scan staged changes for secret patterns before commit (see step 3.5). Placeholders (`<TOKEN>`, `YOUR_API_KEY`, `example`) are allowed in docs and samples.

---

## Expected output

```markdown
**Guidelines reviewed**

- Principles: [cheatsheet | skipped - not installed]
- Architecture: [selection | one approved style path | discover-first / omitted] — never architecture/**
- Stack: [.NET | Angular | other] - [files loaded]
- Security: no hardcoded secrets in planned changes
- Next: branching (step 3) or implementation
```

---

## References

- Router: `AGENTS.md` in toolkit or target repo
- Token budget: do not preload `code-guidelines/languages/**`; do **not** glob `architecture/**`
- Selection A: `code-guidelines/principles/architecture-selection.md`
- Styles B index: `code-guidelines/principles/architecture/README.md` (index only — still load one style file)
