# blip-plugin-developer — Phase 2 documentation

### Phase 2 - Documentation flow

Ask **(pt-BR)**: "Qual fluxo de documentação? (Classic SDD, Orchestrated Delivery, PRD/brief existente, ou escopo informal?)"

| Choice | Next command (new session each step) |
|--------|--------------------------------------|
| **Classic SDD** | `/sdd-spec` -> `/sdd-plan` -> `/sdd-develop` |
| **Orchestrated Delivery** | `/orchestrate-analyze` -> `/orchestrate-deliver` -> develop |
| **Existing PRD/brief** | Skip spec; proceed to `sdd-plan` with provided doc |
| **Informal / small** | Document scope in `README.md`; handoff directly to implementation / `developer` |

**Do not** jump to `sdd-plan` without a PRD/spec when starting SDD from scratch.

Record profile (Lite/Full) and API type (Blip resources vs external REST) in PRD or README.
