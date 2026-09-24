# Documentation plan: agent-dev-toolkit

| Field | Value |
|-------|--------|
| **Repository** | agent-dev-toolkit |
| **Doc language** | English (public `docs/` / EN docs-site); pt-BR for `*.pt.md` mirrors |
| **Stack detected** | PowerShell, Markdown Agent Skills, MkDocs docs-site |
| **Overview** | docs/overview.md |
| **Progress** | 3/4 |
| **Feature closeout** | 006-toolkit-evolution-contracts US01 doc sync (post WS1/WS3/WS7/WS10) |

```
[🟢🟢🟢⚪] 75% (3/4)
```

## Goals

- [x] G1: Canonical **work tracks** documented (Classic SDD / Backlog Refine / Orchestrated Delivery)
- [x] G2: Internal SDD contracts visible to operators: REQ, validate-prd/plan, CHANGE, EVD, STATE, TRACE, selective retrieval — **same skill call flow**; gates/artifacts only
- [x] G3: Legacy track aliases removed from public docs / docs-site / memory-bank (Frente 0; `Assert-NoFormaAlias.ps1`)
- [x] G4: US01 contracts reflected in public docs (InvocationAxes, readiness B/I, `## Related`, DevelopSessionGate, living-artifact / Kind handoffs)
- [ ] G5 (optional follow-up, OOS this US): ADO `ai-prompts` track; re-evaluate SQLite/FTS only if token pain persists (not SoT)

## Target doc tree

```
docs/
├── overview.md
├── README.md
├── SKILLS.md
├── VALIDATION.md
├── domains/core.md
├── guides/
├── documentation-plan/
│   └── plan.md          # this file — versioned (`!/docs/documentation-plan/plan.md`); other scratch under this folder may stay gitignored
docs-site/               # MkDocs EN + .pt mirrors
memory-bank/             # durable workspace map
README.md                # repo landing
```

## Guiding phrase

**Mesmo fluxo SDD/orquestração; gates e artefatos a mais** — not new skills, tracks, or a second toolkit. No `openspec/` / `.specs/` / `.specify/`. SQLite/FTS is **not** a deliverable of feature 005/006 (OOS; possible later P4+).

## Canonical artifact paths (under `features/NNN-slug/`)

| Artifact | Path |
|----------|------|
| CHANGE | `features/NNN-slug/CHANGE.md` |
| Evidence | `features/NNN-slug/EVD/` |
| State | `features/NNN-slug/STATE.md` |
| Trace | `features/NNN-slug/TRACE.jsonl` |

## Implementation steps

### ✅ STEP 1: P-DOC — tracks + contracts (feature 005)

**Status:** Completed | **Completed:** 2026-08-21 | **Deps:** none | **Est.:** 45–60 min | **Kind:** new

**Deliverables:**
- [x] `memory-bank/` — tracks + contracts summary
- [x] `docs/` — guides, SKILLS, domains/core, overview, README index, CREDITS
- [x] `docs-site/` — using-skills + get-started (EN + pt)
- [x] `README.md` — track names
- [x] `docs/documentation-plan/plan.md` — this plan (created at PASSO 7 only)

**Acceptance:**
- [x] CA7 / REQ-008 surfaces updated
- [x] CA8 / REQ-009 phrasing: same skill ids / call flow
- [x] No SQLite/FTS as deliverable; no second toolkit CLI

---

### ✅ STEP 2: Alias sunset (Frente 0)

**Status:** Completed | **Completed:** 2026-08-31 | **Deps:** 1 | **Est.:** 30 min | **Kind:** update

**Deliverables:**
- [x] Remove legacy A/B/C track alias labels from public docs, docs-site, memory-bank, README, core/
- [x] Keep track names only: Classic SDD / Backlog Refine / Orchestrated Delivery
- [x] `scripts/validation/Assert-NoFormaAlias.ps1` registered in `validate-core.ps1`

**Acceptance:**
- [x] `Assert-NoFormaAlias.ps1` passes on versioned public surfaces

---

### ✅ STEP 3: US01 contracts — public doc sync

**Status:** Completed | **Completed:** 2026-09-24 | **Deps:** 2 | **Est.:** 60–90 min | **Kind:** update

**Deliverables:**
- [x] Local ANALYSIS notes for doc drift (gitignored `features/` tree — not linked from published docs)
- [x] `docs/domains/core.md` — Navigation, readiness B/I, session gate, portable/gitignore, Kind, C# 6/160
- [x] `docs/domains/validation-ci.md` + `VALIDATION.md` + `cli-scripts.md` — WS1/3/7/10 asserts + allowlist MUST `-File`
- [x] `docs/domains/git-ops.md` + `SKILLS.md` + guides — living-artifacts + recommended loop + Kind
- [x] `docs/overview.md` / INSTALL / getting-started / ARCHITECTURE / README — skill count 40 + maturity rows
- [x] `docs-site/` maintainers + using-skills (EN + pt) aligned

**Acceptance:**
- [x] No public claim of 5/150 signatures, ambiguous Auto inherit, missing session gate / Related / B/I
- [x] Skill count **40** consistent across README / ARCHITECTURE / docs README / SKILLS / docs-site
- [x] Do not invent Jarvis/ADO readiness runtime

---

### ⏳ STEP 4: Optional follow-ups (OOS / later)

**Status:** Pending | **Completed:** - | **Deps:** 3 | **Est.:** TBD | **Kind:** new

**Deliverables:**
- [ ] Document ADO `ai-prompts` track only if product adopts it (not in US 005/006 scope)
- [ ] If token retrieval pain persists: re-evaluate SQLite/FTS as **cache only** (never SoT) — separate feature

**Acceptance:**
- [ ] Explicit OOS until a new PRD/PLAN exists

---

## Execution order

**Critical path:** 1 → 2 → 3 → (4 optional)

**Next step:** STEP 4 — Optional follow-ups (OOS until new PRD)

## Update protocol

After each completed step, `document-implement` (or the next P-DOC) updates this file: status, progress bar, **Next step** line, and checked deliverables.
