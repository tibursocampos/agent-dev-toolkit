## Explicit exclusions

Do **not** introduce:

- External work-item tracker CLI/API commands (including Azure DevOps `az boards`, REST, or MCP work-item tools)
- Creation or update of Azure DevOps Work Items (WI) or any remote board / tracker card
- External work-item tracker or org-only compliance fields
- Remote PATCH of work items
- PAT scripts, service connections, or organization-specific AI tags for trackers
- Porting remote “clarify → WI” tracker flows — refine stays **file-based** (`STORY.md` / `REFINE/` / `docs/backlog/` shortcut only)

Persistence and handoff remain local markdown. Escalate delivery via `/split-story-checklist`, `/sdd-spec`, or `/orchestrate-analyze` — never by opening a remote WI.
