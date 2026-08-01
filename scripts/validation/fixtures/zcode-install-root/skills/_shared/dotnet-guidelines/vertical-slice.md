# Vertical Slice Architecture — .NET (overlay C)

Stack HOW for VSA on .NET. Load **only** when ARCH declares vertical-slice / VSA (or hybrid with feature folders).

> **Principles (WHAT):** `../code-guidelines/principles/architecture/vertical-slice.md` — do not duplicate that essay here.  
> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md`  
> **Concentric dependency (if hybrid):** `../code-guidelines/principles/architecture/concentric-dependency.md` + `clean-architecture.md`

---

## MUST

- Organize by feature/use case, not by technical layer alone: colocate the types that change together for one use case.
- Per use case ship **Command / Handler / Validator / Response** (mirror exact naming already in the repo).
- Match the repository’s feature root (`Features/`, `Modules/`, `Application/Features/`, etc.) — do not invent a second tree beside an existing one.
- Keep HTTP endpoints thin: map request → command, invoke handler, map response; no business rules in controllers/Minimal APIs.
- One public top-level type per file (`csharp-patterns.md`).
- Before adding a slice, Glob/Read a neighbor feature and copy its shape (folders, DI registration, test layout).

### Default slice shape (greenfield VSA)

```
Features/
└── {Feature}/
    └── {UseCase}/
        ├── {UseCase}Command.cs
        ├── {UseCase}Handler.cs
        ├── {UseCase}Validator.cs
        └── {UseCase}Response.cs
```

Optional siblings when the repo already uses them: endpoint/controller file, mapping profile, feature-local tests.

---

## MUST NOT

- Default to VSA silently when ARCH omits style or brownfield is classic concentric — discover-first / confirm-first.
- Split one use case across unrelated `Commands/`, `Handlers/`, `Validators/` global folders when the repo already uses per-feature folders (or the reverse without approval).
- Require **MediatR**. Prefer when matching repo / approved license; otherwise use **Mediator**, **Wolverine**, or an **internal** dispatcher — see `recommended-libraries.md`.
- Introduce a paid MediatR/AutoMapper pin without explicit approval.
- Put persistence or domain rules in the endpoint class.
- Glob-load every architecture overlay; load this file only for the ARCH style.

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| Existing `Features/{Feature}/{UseCase}/` | Extend that tree |
| Hybrid: projects Domain/Application + feature folders inside Application | Keep concentric projects; slice inside Application/API |
| MediatR already referenced + license OK | Keep MediatR pipeline behaviors as neighbors do |
| Wolverine / Mediator / internal bus already wired | Keep that dispatcher |
| FluentValidation already used | One validator per command beside the handler |
| Minimal APIs vs controllers | Match the host style in the same feature area |

### Dispatcher note

Command/Handler/Validator/Response is the **structural** contract. The dispatcher library is **orthogonal**:

1. Detect what the solution already registers.
2. If none and greenfield: ask before adding a commercial package; prefer OSS-licensed Mediator, Wolverine, or internal pipeline when policy requires it.
3. Details and license caveats: `recommended-libraries.md`.

### Tests

- Prefer tests next to the slice or under `tests/.../Features/{Feature}/{UseCase}/` as the repo already does.
- Integration tests exercise the real host + handler path for meaningful flows; unit tests assert behavior, not line coverage.

---

## Related guidelines

- Concentric / CA HOW: `clean-architecture.md`
- DDD inside slices: `ddd-tactical.md`
- Messaging: `event-driven.md`
- Libraries / MediatR license: `recommended-libraries.md`

---

## References

- [Vertical Slice Architecture (Jimmy Bogard)](https://www.jimmybogard.com/vertical-slice-architecture/)
- [Microsoft — Modular monolith / feature organization](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [FluentValidation](https://docs.fluentvalidation.net/)
