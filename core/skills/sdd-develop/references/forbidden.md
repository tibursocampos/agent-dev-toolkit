## Forbidden in this toolkit

| Avoid | Use instead |
|-------|-------------|
| `git clone` into `projects/{repo}` | Use open workspace only |
| `feature/base/{parent}/{child}` | `feature/<slug>` or `feat/<id>` only |
| Portuguese implement skill / `PLANO_*` filenames | `sdd-develop`, `PLAN_*` |
| Absolute “comments always English” | Mirror touched area or **ask** on greenfield (`structure-and-quality.md` §2); identifiers stay English |
| NUnit-only bans in new tests | `dotnet-guidelines`, xUnit/Moq |
| Auto sync-commit with work item IDs | Optional `/commit` |
| Auto PR analyzer + work-item links | User opens PR in GitHub UI / review skill |
| Skip `plan-acquisition` / invent flat PLAN path | `references/plan-acquisition.md` |
| Multi-step develop under `continuous` | Still one step per session (`references/develop-modes.md`) |
| Duration/effort/story-point Complete gates | `delivery-baseline` in `references/plan-contract.md` |
