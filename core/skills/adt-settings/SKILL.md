---
name: adt-settings
description: "Show or save the one general model and effort pair for subagents, or return to inheriting the parent. Use when asked to configure subagent model and effort or when invoking /adt-settings."
---

# Skill: adt-settings

Read `_shared/skill-boilerplate.md` before any tool call.

## Scope
- One preference only: `subagent_models.default` in `<effective_SDD_ROOT>/preferences.json`. Resolve `effective_SDD_ROOT` as defined in `_shared/sdd-artifacts/STORAGE-RESOLUTION.md` (section "Effective SDD_ROOT").
- The value is a complete pair `{model, effort}` (both non-empty strings) or the key is absent. Absent means: subagents inherit the parent's model and effort. "inherit" is a menu option, never a stored string.
- Never change the parent's model or effort, roles, favorites, limits, hooks, commands or modes. Never touch another preference key.

## Who may run it
- Only the parent session, only on the user's explicit request to query, save or return to inheritance. A temporary session choice is never saved. Without an explicit request, write nothing (`no-explicit-request`).
- Subagents never ask, never read or write the preference, and are never given its path. If this skill is invoked inside a delegated task, stop and return the impediment through the workflow's own return contract.

## Options source
- Read `_shared/agents/SUBAGENT-OPTIONS.md` (section: Adapter matrix). Use only the row of the effective adapter, surface and version. Offer or accept only pairs listed there. Do not keep or invent a model or effort list.
- Reference missing, unreadable or without a row for this context: `reference-unavailable`. Saving a pair is refused; querying and returning to inheritance still work.
- A saved default is only a pre-selection for the session question asked by the delegating skills. It never answers that question and never changes a session choice already given.

## Operations
1. Query (no write): read the file and the reference; show the current default (or "none"), its origin (this file) and that the effective result without a valid default is inheriting the parent. Default present but not a valid pair, or file unreadable or of incompatible shape: show the field, the reason code, and "effective: inherit the parent". Do not repair, remove or rewrite anything.
2. Save a pair: explicit request, pair valid and listed in the reference row. Compute the new content (Edit rules). Pair equal to the current default: write nothing and confirm "unchanged".
3. Return to inheritance: explicit request. Remove only `subagent_models.default`. Default or file already absent: write nothing, say that subagents already inherit. This does not need the reference.

## Edit rules
1. Path: `<effective_SDD_ROOT>/preferences.json`. Read the whole text T0.
2. File absent: query and "inherit" create nothing. Save creates the file with exactly the structure in `_shared/sdd-artifacts/STORAGE-RESOLUTION.md`, section "Preferences structure" (read it now; do not copy it here), plus `subagent_models.default`. If that block cannot be read, refuse with `template-unreadable` and create no file.
3. File present: parse T0 as JSON. Not parseable: `unreadable`. Root not an object, or `subagent_models` present and not an object: `incompatible-shape`. In both cases refuse every operation and leave the file untouched. Never rebuild defaults.
4. Change only `subagent_models.default`. Keep every other key and value, in the original order; keep an existing `subagent_models` object and its other keys; after a removal keep `subagent_models` as `{}` if it becomes empty. Write UTF-8 without BOM, LF, two-space indent.
5. Immediately before writing, read the file again. If it differs from T0, write nothing: `changed-since-read`.
6. After writing, read it again and parse. The result must equal the expected content (all original keys unchanged; only `subagent_models.default` set or removed). If not: restore T0 once, read again, answer `write-failed` or `reread-mismatch` and say whether T0 was restored. Never report success after a failed check.
7. Success message states what was saved, removed or created and that it was read back. The session choice already given is unchanged.

## Output rules
- Reply in the user's chat language. Name the field and one reason code from: `unreadable`, `incompatible-shape`, `invalid-pair`, `reference-unavailable`, `template-unreadable`, `changed-since-read`, `write-failed`, `reread-mismatch`, `no-explicit-request`.
- Never print an absolute path or the rejected value.
- Any refusal leaves delegation on inheritance and work continues.
