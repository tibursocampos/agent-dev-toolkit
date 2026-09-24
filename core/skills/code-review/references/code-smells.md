## Code smell index (pointers only)

Load detail from the linked docs — do not paste bodies into the review report.

| Smell / bar | Look for | Load |
|-------------|----------|------|
| Structure / quality | Architecture vs style, language mirror/ask, constants, blank-spam, one primary type/file | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| Long method | > ~30 lines in changed code | stack checklist |
| Large class | Multiple unrelated responsibilities | stack checklist |
| Duplication | Same logic in 2+ places | stack checklist |
| Feature envy | Method mostly uses another type’s data | principles cheatsheet |
| Primitive obsession | Many primitives where a value object fits | principles / stack patterns |
| N+1 / hot-path | Per-item query/HTTP in loops; unbounded lists | `references/n-plus-one.md` |
| Policy / gates | Weakened guardrails, silent PRD writes | `references/policy.md` |
| Contracts / SoT | Absolute paths, second SoT, CHANGE shape | `references/contracts.md` |
| .NET | Signatures, constants, blank lines, construction | `dotnet-guidelines/csharp-patterns.md` + `dotnet-guidelines/checklist.md` |
| JS/TS | Strict TS, clean-code, Node structure | `javascript-guidelines/checklist.md` |
| Python | Style, typing, FastAPI/Flask | `python-guidelines/checklist.md` |
| Java | Style, Spring defaults, boundaries | `java-guidelines/checklist.md` |
| React / Vue / Angular / RN / Blazor / Electron | Stack delivery checklist | matching `*-guidelines/checklist.md` |
| Frontend markup/CSS | Semantics, a11y, tokens | `html-css-guidelines/checklist.md` |

Quick scan on changed code only; escalate to the stack checklist when the surface matches.

---
