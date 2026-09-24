## Boundary: refine vs O1 vs sdd-spec

| Aspect | `refine-story` (Backlog Refine) | `orchestrate-analyze` (O1) | `sdd-spec` (Classic SDD) |
|--------|----------------------------------|----------------------------|----------------------|
| Purpose | Fast intake - one backlog item + scorecard | Multi-agent triage + US/TS backlog for a feature | Full PRD for one story/feature |
| Output | Structured markdown + scorecard | `FEATURE.md`, `CONTINUITY.md`, `STORY.md` × N | PRD under `features/.../PRD/` |
| Persistence | Prefer `features/.../STORY.md`; shortcut `docs/backlog/` | Feature tree only | Canonical PRD path |
| Specialists | None | Conditional Task (`needs_*`) | None (consumes Prior context) |
| When to use | Informal idea, bug, single TS/US | Complex / multi-story / brownfield package | Ready to write PRD for one path |
| Tracker | Never (no external tracker/`az`) | Never | Never |

Escalate to **O1** when: multiple stories, unclear flags (`needs_*`), brownfield impact needs parallel specialists.

Escalate to **sdd-spec** when: single story is clear enough for a PRD (or after refine approval) **and** clarification status is **READY** (no open **B**/**I** — `readiness-severity.md` / REQ-005). PRD contract (REQ-IDs, verifiable CA, OOS, optional hybrid EARS) lives in `templates/sdd/PRD.md` — refine does **not** invent a parallel PRD body.

### Clarification STOP (REQ-004 / REQ-005 / TE01)

Open questions use severity **B** \| **I** \| **MINOR** (`clarify-depth.md` + `readiness-severity.md`).

| Status | Refine behavior |
|--------|-----------------|
| **READY** | May hand off to `/sdd-spec` / O2; **MINOR** may remain listed |
| **NEEDS_CLARIFICATION** | **STOP** fake-forward “approved for PRD”; do **not** tell operator the item is ready for `sdd-spec` / O2 Write; emit typed handoff (portable paths + B/I list) |

**RN02:** sibling folder presence ≠ READY. **Dual plane:** READY ≠ SESSION `step_confirmed` / implementation Complete.

**Selective retrieval:** `SELECTIVE-RETRIEVAL.md` rule `SR-NO-FULL-DUMP` — **must not** dump entire `memory-bank/` or paste full PRD into refine output/handoffs. Smoke: `Assert-SelectiveRetrieval.ps1`.

Do **not** expand refine into a full PRD inline.

Handoff wording:

```
Item grande / multi-história: /orchestrate-analyze
Item único READY para PRD: /sdd-spec
NEEDS_CLARIFICATION (B/I abertos): responder perguntas — não /sdd-spec ainda
Checklist local: /split-story-checklist
```

Before suggesting `sdd-spec`, optionally Glob `features/**/PRD/` (workspace + global feature root) per `STORAGE.md`. Do **not** glob root/flat `PRD/` for execution.

`sdd-spec` owns storage choice, manifest, `.gitignore`, and confirm-before-write. Refine does **not** write PRD/PLAN. Promote `docs/backlog/` via `sdd-spec` or O1 - never treat backlog files as PRD.

---
