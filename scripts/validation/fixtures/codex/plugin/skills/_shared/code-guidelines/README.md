# Shared Code Guidelines

Cross-skill code standards for implementation and review.

**Version:** 1.0 (agent-dev-toolkit)  
**Purpose:** Single source of truth for patterns referenced by skills

---

## Goal

Centralize guidelines so:

- **Developers** consult them **before** implementing (proactive)
- **code-review** validates **after** changes (reactive)
- **One update** benefits all skills that reference the same file

## Token discipline (mandatory)

| Rule | Detail |
|------|--------|
| **Load on demand** | Read only the file needed for the current task |
| **Never preload** | Do not glob `languages/**` or read the entire tree |
| **Architecture styles** | Load **one** file under `principles/architecture/` — **never** glob `architecture/**` |
| **Selection first** | Greenfield/style choice → `principles/architecture-selection.md` before any style file |
| **MVP scope** | `principles/` (+ architecture pack); language packs deferred |

Paths after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/code-guidelines/`

`.NET` stack details live in `dotnet-guidelines/` - not under `languages/dotnet/` in MVP.

---

## Structure (MVP)

```
_shared/code-guidelines/
├── README.md                 # This file
└── principles/               # Cross-stack fundamentals
    ├── SOLID.md              # Overview + links
    ├── DRY.md
    ├── KISS.md
    ├── YAGNI.md
    ├── encapsulation.md
    ├── principles-cheatsheet.md
    ├── architecture-selection.md   # Layer A — WHEN
    └── architecture/               # Layer B — WHAT (one style at a time)
        ├── README.md               # Token rule + index
        ├── concentric-dependency.md
        ├── vertical-slice.md
        ├── ddd-tactical.md
        └── event-driven.md
```

### Architecture lazy-load

| Step | File | Rule |
|------|------|------|
| A | `principles/architecture-selection.md` | Decide / confirm style (or mirror brownfield ARCH) |
| B | `principles/architecture/<one-style>.md` | Exactly one primary style; optional DDD/EDA only if selected |
| C | `*-guidelines/...` | Thin stack overlay (not under this folder) |

### Deferred (v1.1+)

| Path | Notes |
|------|-------|
| `languages/dotnet/*.md` | ~29k tokens; use `dotnet-guidelines/` in MVP |
| `security/**` | Optional later |
| `cross-stack/**` | Corporate pipeline patterns excluded |
| `languages/angular/**`, `languages/cypress/**` | Out of MVP |

---

## Who uses these files

| Skill | When | Guidelines |
|-------|------|------------|
| **developer** | Step 0.5 | `principles/*` + `dotnet-guidelines/*` |
| **implement** | Before .NET code | `dotnet-guidelines` (lazy); principles if design-heavy |
| **code-review** | Review pass | `principles/*` + stack guidelines as needed |

---

## How to load (developers)

### Always (principles)

Read only what the task needs - typical minimum:

```
principles/principles-cheatsheet.md   # quick rules
principles/DRY.md                     # if duplication risk
principles/KISS.md                    # if complexity risk
principles/YAGNI.md                   # if new types/methods added
principles/encapsulation.md           # if many parameters
```

**Cheatsheet first** (~1 min); open full files when a violation type is likely.

### Architecture work

```
principles/architecture-selection.md           # WHEN (greenfield / brownfield gate)
principles/architecture/README.md              # index + one-style rule (optional)
principles/architecture/<one-primary>.md       # WHAT — never glob architecture/**
```

### .NET work

Use `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/dotnet-guidelines/` - not `code-guidelines/languages/dotnet/` until v1.1.

---

## Adding a new guideline

1. Pick category: `principles/` for cross-stack rules.
2. Follow the pattern in existing principle files (Objective, examples, severity, references).
3. Update `principles-cheatsheet.md` if the rule is decision-table worthy.
4. Reference from `AGENTS.md` lazy-load table only if a skill should load it by default.

---

## References

- *Clean Code* - Robert C. Martin
- *The Pragmatic Programmer* - Hunt & Thomas
- *Refactoring* - Martin Fowler

**Maintained in:** agent-dev-toolkit repo
