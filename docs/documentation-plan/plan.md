# Documentation plan — agent-dev-toolkit

**Doc language:** English  
**Created:** 2026-07-30  
**Progress:** 6/6 ██████████

**Next step:** (none — public doc set complete)

---

## Goal

Self-explanatory public GitHub documentation: clone → install → sync → test → use skills. No internal delivery-story or sibling-repo language in product docs.

## Steps

### Step 1 — Landing and index

- **Status:** Completed
- **Completed:** 2026-07-30
- **Deliverables:**
  - [x] `README.md` — public landing
  - [x] `docs/README.md` — TOC
  - [x] `docs/overview.md` — RAG overview
  - [x] `CONTRIBUTING.md` — clone/fork policy

### Step 2 — Install, validation, skills

- **Status:** Completed
- **Completed:** 2026-07-30
- **Deliverables:**
  - [x] `docs/INSTALL.md`
  - [x] `docs/VALIDATION.md`
  - [x] `docs/SKILLS.md`

### Step 3 — Guides

- **Status:** Completed
- **Completed:** 2026-07-30
- **Deliverables:**
  - [x] `docs/guides/README.md` — decision tree
  - [x] `docs/guides/01-getting-started.md`
  - [x] `docs/guides/02-using-skills.md`

### Step 4 — Domains

- **Status:** Completed
- **Completed:** 2026-07-30
- **Deliverables:**
  - [x] `docs/domains/core.md`
  - [x] `docs/domains/adapters.md`
  - [x] `docs/domains/cli-scripts.md`
  - [x] `docs/domains/validation-ci.md`

### Step 5 — Architecture and adapters polish

- **Status:** Completed
- **Completed:** 2026-07-30
- **Deliverables:**
  - [x] `docs/ARCHITECTURE.md` rewritten
  - [x] `docs/ADAPTERS.md` cleaned (neutral smoke examples only)
  - [x] `adapters/claude/README.md` cleaned
  - [x] `adapters/grok/README.md` cleaned

### Step 6 — Forbidden-term sweep

- **Status:** Completed
- **Completed:** 2026-07-30
- **Deliverables:**
  - [x] Grep `docs/` + `README.md` (+ CONTRIBUTING, adapter READMEs) for delivery-story ids / sibling-repo names / feature-folder paths
  - [x] Hits fixed
