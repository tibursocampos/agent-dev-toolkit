# PLAN selection (O3 parent and child)

Resolve the user's feature or PLAN path using `STORAGE.md`. Use only canonical PLAN files under the resolved feature's `features/` tree (repository or configured global root). Normalize and validate supplied paths; reject traversal and paths that escape the authorized feature root.

## Parent

1. A feature path selects its canonical story PLAN files. A specific PLAN path selects only that PLAN. Use `adt-read-sdd-artifact` in Classic layout to confirm each selected portable PLAN path.
2. If no PLAN exists, stop and hand off to `adt-orchestrate-prepare` or direct `adt-sdd-plan`; O3 does not create or repair PRD/PLAN documents.
3. Read the selected PLAN and derive order, dependencies, acceptance, validation, and progress from it. Existing FEATURE/STORY/PRD or sidecars may be read when useful, but do not require a fixed sibling set or structural preflight.
4. Pass the selected portable PLAN path, the resolved `source_context` when available, and one step identifier to the child.

## Child

The `adt-sdd-develop` child independently confirms that its PLAN path and assigned step are canonical and in scope before editing. The parent-provided path does not authorize edits outside the approved step.

Missing or inconsistent scope is a focused blocker. Do not create a session, claim, or sidecar to authorize continuation.
