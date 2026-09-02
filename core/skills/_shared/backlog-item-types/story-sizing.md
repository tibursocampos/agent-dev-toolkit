# Story sizing contract

Normative rules for **how many stories** a feature needs and **how large** each story should be. Used by `orchestrate-analyze` (O1 synthesis) and `refine-story` (scorecard). Not a backlog item type — a cross-cutting contract.

Enforcement smoke: `Assert-StorySizingContract.ps1`.

---

## Minimum story unit

A story (US or TS) must represent **one verifiable user or technical outcome**, ideally deliverable as **one PR** with a clear review boundary.

| Good | Bad |
|------|-----|
| "App B consumes shared NuGet package without breaking CI" | "Update `PackageReference` in App B" |
| "Operators export archived records by date range" | "Add `ExportController.cs`" |
| "Shared library X published to internal feed with semver" | "Create `SharedKernel` folder" |

Steps inside a story may touch multiple files and layers; the **story title and objective** name the outcome, not the file list.

---

## Anti-patterns (do not size stories this way)

| Anti-pattern | Why it fails | Fix |
|--------------|--------------|-----|
| **One file = one story** | Review boundary follows files, not value; PRs are too small to test behavior | Merge into one outcome-oriented story or group by consumer/bounded context |
| **One layer = one story** | Domain-only / API-only stories block integration and hide missing end-to-end verification | Size by vertical slice or consumer-visible outcome |
| **One repo = one story** (when repos are consumers) | Hides dependency order and blast radius | Split by consumer app or deployable unit when rollout order matters |
| **Step title = file or class name only** | Refine output looks like a file checklist, not implementable baby steps | Rename step to the **behavior** (e.g. "Validate empty optional field in create-order command" not "`OrderValidator.cs`") |

---

## Heuristics (when to split vs merge)

Apply in order during O1 synthesis and refine escalation:

**1. Bounded context** — Separate stories when types, contracts, or domain boundaries differ materially (e.g. package extract vs App A consumer vs App B consumer).

**2. Consumer / deployable app** — When multiple apps consume a shared change, one story per consumer (or per rollout wave) if CI, config, or rollback are independent.

**3. Blast radius** — Split when failure in one slice should not block others (feed publish vs app migration; frontend vs backend when teams ship separately).

**4. Dependency order** — Upstream story must merge before downstream (package on feed before App B references it).

**5. Refine step count** — If a single story needs **more than ~5–8 refine steps** before `split-story-checklist`, consider splitting into **two stories** with explicit dependencies rather than one oversized STORY.

When in doubt, prefer **fewer, outcome-sized stories** over many file-scoped ones.

---

## Merge policy (O1, before human gate)

Before presenting the backlog for approval (RN01):

1. Load this contract (`story-sizing.md`).
2. For each proposed US/TS, verify objective = one verifiable outcome (not a file or layer list).
3. **Merge** stories that only differ by file or layer within the same bounded context and consumer.
4. **Split** stories that exceed ~8 steps, span independent consumers, or mix unrelated outcomes.
5. Record **rationale** in `FEATURE.md` story table (why N stories, not N−1 or N+1).
6. Optional validator: run mental check against `split-story-checklist` grouping limits (≤5 implementation groups per story after topology); if a single story would exceed that without test-only groups, split the story.

Do **not** present the backlog until merge/split pass completes.

---

## Reference example: NuGet brownfield extract

**Ask:** Extract shared library X into an internal NuGet; App A and App B must consume it without breaking CI.

| Field | Value |
|-------|--------|
| Nature | `brownfield` |
| Complexity | `complex` |
| Scope | `backend` |

**Wrong sizing (anti-patterns):**

- TS01 `SharedLibrary.cs` — TS02 `SharedLibrary.Tests.cs` — TS03 `AppA.csproj` — TS04 `AppB.csproj` *(one file = one story)*
- TS01 Domain types — TS02 Infrastructure — TS03 API *(one layer = one story)*

**Right sizing (outcome-oriented):**

| Id | Tipo | Título | Rationale (why separate) | Product intent |
|----|------|--------|--------------------------|----------------|
| TS01 | TS | Package extract + internal feed publish | Single outcome: semver package on feed; blocks consumers | n/a |
| TS02 | TS | App A consumes package without CI regression | Independent consumer + rollback boundary | n/a |
| TS03 | TS | App B consumes package without CI regression | Same bounded context as TS02 but separate blast radius | n/a |
| US01 | US | Developer documents publish flow in runbook | Optional user-facing outcome; not merged into TS01 | Who: package maintainer / Job: publish shared lib safely / Outcome: runbook-ready publish |

Full triage flags and spawn map: `orchestrate-analyze/references/triage.md` § Example: NuGet brownfield triage.

---

## Relationship to other skills

| Skill | Role |
|-------|------|
| `refine-story` | Scorecard **Story scope** criterion; challenge file-only step titles |
| `orchestrate-analyze` | Lazy-load at synthesis; merge policy + FEATURE rationale column |
| `split-story-checklist` | Optional merge validator (group count / topology) after refine steps exist |

Handoff when item is too large for single refine:

```
/orchestrate-analyze
```

---

## Related product-quality norms (pointers only)

Do **not** duplicate these norms here — lazy-load the file you need. Folder index: `README.md` in this directory.

| Ref (portable under `core/skills/_shared/backlog-item-types/`) | Use when |
|---------------------------------------------------------------|----------|
| `invest-and-story-quality.md` | INVEST / Valuable checks |
| `splitting.md` | Split vs merge beyond this file’s heuristics |
| `anti-task-shatter.md` | Promotion gate: verb+file / layer-only |
| `gherkin-budget.md` | Minimum happy + rule + failure AC |
| `ost-lite.md` | Outcome → story → task altitude |
| `feature-altitude.md` | FEATURE vs US/TS vs step |
| `product-evidence-lite.md` | Evidence: omit > fabricate |
| `clarify-depth.md` | Depth of open questions / challenge |
