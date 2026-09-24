## Plan template (`docs/documentation-plan/plan.md`)

Copy and adapt in the **target repository**. Section titles may be pt-BR or English to match `doc_language`.

```markdown
# Documentation plan: [Repository name]

| Field | Value |
|-------|--------|
| **Repository** | [git remote or folder name] |
| **Doc language** | pt-BR \| English |
| **Stack detected** | [.NET, Angular, … from step 0] |
| **Overview** | docs/overview.md |
| **Progress** | 0/N |

```
[⚪⚪⚪⚪⚪] 0% (0/N)
```

## Goals

- [ ] G1: RAG-ready markdown per domain
- [ ] G2: Integrations and boundaries documented
- [ ] G3: Architecture patterns evidenced from code

## Target doc tree (consumer repo)

```
docs/
├── overview.md
├── documentation-plan/
│   └── plan.md
└── domains/
    └── <domain-slug>.md
```

---

## Implementation steps

### ⏳ STEP 1: [New domain doc title]

**Status:** Pending | **Completed:** - | **Deps:** none | **Kind:** new | **Est.:** 30-45 min

**Deliverables:**
- [ ] `docs/domains/<slug>.md` - purpose, main types, flows, extension points

**Tasks:**
1. Glob/Grep bounded context folders
2. Read entry points (API, consumers, UI modules)
3. Write markdown in **doc language**; English identifiers for paths/types

**Acceptance:**
- [ ] New developer can locate main code paths from the doc alone

---

### ⏳ STEP 2: [Update existing docs after change]

**Status:** Pending | **Completed:** - | **Deps:** none | **Kind:** update | **Est.:** 20-40 min

**Deliverables:**
- [ ] Refresh listed existing paths only (example: `docs/overview.md`, `docs/domains/<slug>.md`)

**Tasks:**
1. Diff feature/CONTRACT changes vs current docs
2. Update only stale sections; keep RAG structure
3. Do not split into one step per file unless each file is net-new

**Acceptance:**
- [ ] Touched docs match current code evidence; no orphan baby-steps for trivial edits

---

### ⏳ STEP 3: [Integrations — new file only if missing]

**Status:** Pending | **Completed:** - | **Deps:** 1 | **Kind:** new | **Est.:** 30 min

**Deliverables:**
- [ ] Section in `docs/domains/<slug>.md` or `docs/integrations.md`

**Tasks:**
1. Grep HTTP clients, message consumers, SDK config
2. Document external systems, contracts, failure modes (no secret values)

---

### ⏳ STEP 4: [Architecture patterns — new file only if missing]

**Status:** Pending | **Completed:** - | **Deps:** 1 | **Kind:** new | **Est.:** 25 min

**Deliverables:**
- [ ] `docs/architecture/patterns.md` or section in overview

**Tasks:**
1. Evidence layers (Clean Architecture, CQRS, etc.) from structure - do not assert patterns not present
2. Link to representative files (paths only)

---

## Execution order

**Critical path:** 1 -> 2 -> 3 -> …

**Next step:** STEP 1 - [title]

## Update protocol (document-implement skill)

After each completed step, `document-implement` updates this file: status, progress bar, **Next step** line, and checked deliverables.
```

Add steps until **new** domain/integration files from exploration are covered, plus **at most one** coalesced **update** step when refreshing existing docs. Prefer **few larger steps** (one step ≈ one new file, or one update bucket) — **not** 5–12 tiny baby steps for medium repos.

---
