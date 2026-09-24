# Documentation plan: agent-dev-toolkit

| Field | Value |
|-------|--------|
| **Repository** | agent-dev-toolkit |
| **Doc language** | English (public `docs/` / EN docs-site); pt-BR for `*.pt.md` mirrors |
| **Stack detected** | PowerShell, Markdown Agent Skills, MkDocs docs-site |
| **Overview** | docs/overview.md |
| **Progress** | 4/5 |
| **Feature closeout** | 006 US01 + **008** public doc sync done (STEP 5); STEP 4 remains optional OOS |

```
[🟢🟢🟢🟢⚪] 80% (4/5)
```

## Goals

- [x] G1: Canonical **work tracks** documented (Classic SDD / Backlog Refine / Orchestrated Delivery)
- [x] G2: Internal SDD contracts visible to operators: REQ, validate-prd/plan, CHANGE, EVD, STATE, TRACE, selective retrieval — **same skill call flow**; gates/artifacts only
- [x] G3: Legacy track aliases removed from public docs / docs-site / memory-bank (Frente 0; `Assert-NoFormaAlias.ps1`)
- [x] G4: US01 contracts reflected in public docs (InvocationAxes, readiness B/I, `## Related`, DevelopSessionGate, living-artifact / Kind handoffs)
- [ ] G5 (optional follow-up, OOS this US / not in 008): ADO `ai-prompts` track; re-evaluate SQLite/FTS only if token pain persists (not SoT) — **STEP 4**
- [x] G6: Feature **008** public surfaces synced (bootstrap, `framework-upgrade`, authorship notes opt-in, skill count **41**, open-github-pr squash/rebase) — **STEP 5**

## Target doc tree

```
docs/
├── overview.md
├── README.md
├── SKILLS.md
├── VALIDATION.md
├── INSTALL.md              # § 0 Release bootstrap (partly done — verify in STEP 5)
├── domains/
├── guides/
│   └── 09-authorship-git-notes.md
├── documentation-plan/
│   └── plan.md          # this file — versioned (`!/docs/documentation-plan/plan.md`); other scratch under this folder may stay gitignored
docs-site/               # MkDocs EN + .pt mirrors
memory-bank/             # durable workspace map (refreshed; not rewritten by STEP 5 unless drift)
README.md                # repo landing
```

## Guiding phrase

**Mesmo fluxo SDD/orquestração; gates e artefatos a mais** — not new skills, tracks, or a second toolkit. No `openspec/` / `.specs/` / `.specify/`. SQLite/FTS is **not** a deliverable of feature 005/006/008 (OOS; possible later P4+).

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
- [x] `docs/overview.md` / INSTALL / getting-started / ARCHITECTURE / README — skill count aligned + maturity rows
- [x] `docs-site/` maintainers + using-skills (EN + pt) aligned

**Acceptance:**
- [x] No public claim of 5/150 signatures, ambiguous Auto inherit, missing session gate / Related / B/I
- [x] Skill count consistent across README / ARCHITECTURE / docs README / SKILLS / docs-site (was **40** at close; **41** after 008 — fix remaining drift in STEP 5)
- [x] Do not invent Jarvis/ADO readiness runtime

---

### ⏳ STEP 4: Optional follow-ups (OOS / later — not in 008 scope)

**Status:** Pending | **Completed:** - | **Deps:** 3 | **Est.:** TBD | **Kind:** new

**Scope note:** Remains **optional OOS**. Feature **008** does **not** implement this step. Prefer STEP 5 for 008 closeout.

**Deliverables:**
- [ ] Document ADO `ai-prompts` track only if product adopts it (not in US 005/006/008 scope)
- [ ] If token retrieval pain persists: re-evaluate SQLite/FTS as **cache only** (never SoT) — separate feature

**Acceptance:**
- [ ] Explicit OOS until a new PRD/PLAN exists

---

### ✅ STEP 5: Feature 008 — public docs + docs-site + README sync

**Status:** Completed | **Completed:** 2026-09-24 | **Deps:** 3 | **Est.:** 60–90 min | **Kind:** update

**Context:** After `008-toolkit-evolution-remaining` PLAN 12/12 and `open-github-pr` merge-method change (feature → develop = **squash**; release develop → main/master = **rebase**). Memory-bank already refreshed (41 skills; bootstrap; framework-upgrade; authorship notes). Overview lightly updated at plan time — implement step finishes remaining public surfaces.

**Deliverables:**
- [x] `docs/INSTALL.md` — verify § 0 Release bootstrap consistency with `scripts/bootstrap/*` (partly done; fix any drift)
- [x] `docs/SKILLS.md` + `docs/domains/core.md` Ops row — `framework-upgrade` present; skill count **41**; no stale **40**
- [x] `docs/domains/git-ops.md` + related guides — document mandatory merge methods (feature **`--squash`**, release **`--rebase`**) + auto-merge ask; align with `core/skills/open-github-pr/`
- [x] `docs/guides/` — getting-started / using-skills / guide 09 authorship notes cross-links consistent
- [x] `docs/domains/` — adapters/core TRACE honesty + authorship opt-in pointers; cli-scripts if bootstrap/notes scripts listed
- [x] `docs-site/` EN + `.pt.md` — skill count **41**, `framework-upgrade`, bootstrap/install pointers, PR merge policy if operator-facing pages mention `open-github-pr`
- [x] Root `README.md` — fix **Skills preview (40) → (41)**; mention bootstrap / `framework-upgrade` where preview lists ops
- [x] Sweep remaining **40→41** drift across `docs/`, `docs-site/`, root README (ARCHITECTURE / docs README already 41 — re-verify)
- [x] Do **not** implement STEP 4 OOS items in this step

**Tasks:**
1. Grep public surfaces for `\b40\b`, missing `framework-upgrade`, missing squash/rebase, bootstrap/authorship gaps
2. Evidence-read `scripts/bootstrap/*`, `core/skills/framework-upgrade/`, `scripts/trace/Invoke-AuthorshipGitNotes.ps1`, `open-github-pr` references — no invented claims
3. Write/update markdown in **English** (pt mirrors for docs-site); keep paths English
4. Update this plan: mark STEP 5 Completed; progress **4/5** (STEP 4 still OOS Pending) or **5/5** only if STEP 4 explicitly cancelled

**Acceptance:**
- [x] Public claim of skill count **41** consistent on README / docs / docs-site (EN+pt)
- [x] Operators can find Option 0 bootstrap, `framework-upgrade`, authorship notes opt-in, and PR squash/rebase policy from public docs without reading skill bodies
- [x] No claim that git-notes are TRACE SoT; no major-pinned upgrade skill id
- [x] STEP 4 left untouched (still OOS Pending)

---

## Execution order

**Critical path:** 1 → 2 → 3 → **5** (008 closeout). STEP 4 remains optional OOS (skip for 008).

**Next step:** STEP 4 — Optional follow-ups (OOS / later — not in 008 scope); or stop if no ADO/SQLite work planned

## Update protocol

After each completed step, `document-implement` (or the next P-DOC) updates this file: status, progress bar, **Next step** line, and checked deliverables.
