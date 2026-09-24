## Explicit exclusions (derived from checklist planning patterns)

Do **not** auto-generate:

- "Update AI tags" / SDD / DevAI tag tasks
- "Attach Datadog logs" as a fixed task
- manual sign-off checklist / DESKCHECK tag tasks
- "Review own PR" with Sonar/Snyk boilerplate as mandatory rows
- Child tasks on remote boards via external tracker REST/CLI
- **One US/TS per file/class/script** (anti-task-shatter RN01) — keep as SMART task rows under the parent story
- New `features/.../USnn/` or `TSnn/` folders invented from checklist split
- **type_classification exact-set** forked into checklist / FEATURE / CONTINUITY / PLAN / PRD (REQ-012 — **STORY only**)

### Skip D (REQ-013 / CA4)

| Forbidden | Why |
|-----------|-----|
| **ADO mutate** / Azure Boards WI create-update | OOS WS13; classification and checklist are local markdown only |
| **Reversa** constitution / skill trees | OOS; not a second SoT |
| **SpecKit constitution** / `.specify/` / uv / specify | Do not adopt; skill id `/split-story-checklist` stays stable (RN03) |

If the user wants a custom workflow section, add it under **Before PR** with their wording only.

---
