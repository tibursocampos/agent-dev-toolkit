## Explicit exclusions

Do **not** introduce:

- External work-item tracker CLI/API commands (including tracker vendor CLIs, REST, or MCP work-item tools)
- Creation or update of tracker work items (WI) or any remote board / tracker card
- External work-item tracker or org-only compliance fields
- Remote PATCH of work items
- PAT scripts, service connections, or organization-specific AI tags for trackers
- Porting remote “clarify → WI” tracker flows — refine stays **file-based** (`STORY.md` / `REFINE/` / `docs/backlog/` shortcut only)
- A second requirement-challenge skill folder, a `feature-refinement` folder, or a clone of another challenge skill — challenge work is **`requirement-review`** (feature and tech modes); extend it instead
- Monolithic `feature-refinement.md` as a parallel product skill (OOS / WS7 decision)
- OS absolute paths or InstallRoot embeds in envelopes, Q&A history, or handoffs (REQ-006 / RNF-002)

Persistence and handoff remain local markdown. Escalate delivery via `/split-story-checklist`, `/sdd-spec`, or `/orchestrate-analyze` — never by opening a remote WI.
