# O1 workflow boundaries and handoff

| Path | Use when | Handoff |
|---|---|---|
| Classic SDD | One sufficiently clear story needs a PRD/PLAN | `/adt-sdd-spec - <portable-story-path>` |
| Backlog Refine | One informal item needs shaping | `/adt-refine-story` |
| O1 | Multi-story, multi-area, or materially uncertain demand | `/adt-orchestrate-analyze - <portable-feature-path>` to resume |
| O2 | FEATURE and stories are sufficiently clear for PRD/PLAN preparation | `/adt-orchestrate-prepare - <portable-feature-path>` |
| Developer/stack skill | Trivial, clear implementation request | `/adt-developer` or the relevant stack skill |

O1 does not require a backlog approval token, closed `MINOR` questions, or
sidecar conversion before handoff. Identify material open decisions and the
work they affect. O2 can prepare independent stories while another story is
blocked; implementation approval applies to the complete explicitly listed
PLAN set and occurs once before code.

Use portable paths from `STORAGE.md`. O1 never writes PRD/PLAN or product code,
and it does not authorize shared implementation cadence or external actions.

## Optional evidence and sidecars

CONTINUITY, CHANGE, TASKS, Memory Bank, ANALYSIS, ARCH, and SEC are optional
context or evidence. Consult or create them only when they provide distinct
value for a concrete question or decision. Existing sidecars are not converted
or deleted by O1.
