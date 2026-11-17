# adt-blip-plugin-developer — Phase 2 documentation

### Phase 2 - Documentation flow

Ask in the **user chat language** which documentation flow applies. Offer the four choices in the table below (Classic SDD, Orchestrated Delivery, existing PRD/brief, informal scope), labelled in that language.

| Choice | Next command (new session each step) |
|--------|--------------------------------------|
| **Classic SDD** | `/adt-sdd-spec` -> `/adt-sdd-plan` -> `/adt-sdd-develop` |
| **Orchestrated Delivery** | `/adt-orchestrate-analyze` -> `/adt-orchestrate-prepare` -> develop |
| **Existing PRD/brief** | Skip spec; proceed to `adt-sdd-plan` with provided doc |
| **Informal / small** | Document scope in `README.md`; handoff directly to implementation / `adt-developer` |

**Do not** jump to `adt-sdd-plan` without a PRD/spec when starting SDD from scratch.

Record profile (Lite/Full) and API type (Blip resources vs external REST) in PRD or README.
