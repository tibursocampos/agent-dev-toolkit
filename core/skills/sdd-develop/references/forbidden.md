## Forbidden in this toolkit

| Avoid | Use instead |
|-------|-------------|
| `git clone` into `projects/{repo}` | Use open workspace only |
| `feature/base/{parent}/{child}` | `feature/<slug>` or `feat/<id>-<slug>` only |
| Portuguese implement skill / `PLANO_*` filenames | `sdd-develop`, `PLAN_*` |
| Absolute “comments always English” | Mirror touched area or **ask** on greenfield (`structure-and-quality.md` §2); identifiers stay English |
| Override an established project test stack with toolkit defaults | Discover and follow the repository baseline first; use applicable `dotnet-guidelines` defaults only when none is verifiable |
| Auto sync-commit with work item IDs | Optional `/commit` |
| Auto PR analyzer + work-item links | User opens PR in GitHub UI / review skill |
| Skip `plan-acquisition` / invent flat PLAN path | `references/plan-acquisition.md` |
| Multi-step develop under `continuous` | Still one step per session (`references/develop-modes.md`) |
| Duration/effort/story-point Complete gates | `delivery-baseline` in `references/plan-contract.md` |

## Must not (develop scope)

- Break C# method signatures/invocations for style when ≤6 parameters and the full line is ≤160 characters (`csharp-patterns.md`) — multiline only when **more than 6** parameters **or** line **> 160**; do not let CSharpier leave a style-only wrap that still fits the inline MUST
- Portuguese application code; **multiple PLAN steps per develop session scope** (contract unchanged — including when develop mode is `continuous`)
- Skip `plan-acquisition` or mark Complete without **delivery-baseline** (`references/plan-contract.md`); add duration/effort estimates to checkpoints (REQ-010)
- Do not ignore `IC-DIRECT-ORCHESTRATED` — resolve and apply `direct` vs `orchestrated` (`INVOCATION-CONTEXTS.md`)
- Do not ignore `CP-AGREED-VS-INVENTED` — do not encode mid-step invented gaps as agreed requirements (`CONTRACT-PROVENANCE.md`)
- Create PRD/PLAN; skip PLAN save; skip the companion PRD status close when **Implementation status** becomes `COMPLETED`; modify `.gitignore`
- Implement in Plan/Ask without Agent
- Bypass one-step via orchestrator parent implementing code
- Use the flat `{repo-hash}.json` for `step_confirmed` / `tests_run` when a PLAN path is known - always use the PLAN-scoped file (or PLAN+step); create scoped with gates false if missing
- Inline-mutate develop session JSON (`ConvertFrom-Json` / `ConvertTo-Json` / `Set-Content` gate blobs) instead of `scripts/session/Invoke-DevelopSessionGate.ps1` via `-File` (REQ-012)
- Skip `scripts/ledger/Invoke-PlanLedgerClaim.ps1` when claim is required and absent because session helper already exited 0 (CT6)
- Write SDD artifacts containing OS absolute paths matching `^[A-Za-z]:/` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) — use portable paths per `STORAGE.md` § Portable path
- Mark a step Completed at evidence level ≥ `cheap` when `validate-evidence` fails or EVD/STATE are missing
- Use O3 / Task parallelism as the evidence verifier (Verifier ≠ O3)
- Declare archive done when `validate-trace -RequireArchiveComplete` fails or living-loop events are missing
- Use OpenSpec / `.specs/` / SQLite as TRACE or living-spec SoT
- Strip / rename `## Related` on PLAN (or PRD if touched), break PRD↔PLAN mutual cite when both exist, or stub absent siblings only for links (`STORAGE.md` § Navigation block / 006 REQ-009)
