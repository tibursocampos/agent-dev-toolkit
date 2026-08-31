# Intent classification (O1 entry)

Normative **first-pass** routing before full triage (`triage.md`) and before Step 0 Memory Bank Gate when the chosen path is not Orchestrated Delivery O1. Extends O1 — not a separate workflow.

Enforcement smoke: `Assert-IntentClassification.ps1`.

---

## Classify input (pick one primary)

| Intent | Signals | Examples |
|--------|---------|----------|
| **Existing Feature** | Portable path under `features/NNN-slug/`; resume CONTINUITY; "continuar feature X" | `/orchestrate-analyze - features/012-auth/`; FEATURE.md already on disk |
| **New Feature** | Named capability, bounded scope, greenfield or additive brownfield | "Add export CSV to admin panel"; "New NuGet package for shared DTOs" |
| **Product Initiative** | Multi-feature theme, roadmap language, org-wide outcome | "Self-service onboarding for all products"; "Platform observability Q3" |
| **Problem / Need** | Pain, defect, regression, ops friction; often one symptom | "Login fails on Safari"; "CI publish step is flaky" |
| **Idea** | Exploratory, hypothesis, no acceptance yet | "What if we used event sourcing for orders?"; "Maybe MCP for GitHub" |

If ambiguous, ask ≤3 high-cost questions (pt-BR). Do **not** invent scope or architecture in the parent orchestrator.

---

## Map intent → track (RF01 extension)

| Intent | Default path | Full O1 (`orchestrate-analyze` continues) |
|--------|--------------|-------------------------------------------|
| **Existing Feature** | Resume O1 on cited path; or Classic SDD (`/sdd-spec`) when one story is PRD-ready | Multi-story expansion, unclear `needs_*`, brownfield blast radius, or missing specialist folders |
| **New Feature** | **Classic SDD** when `medium` + single clear story; **Backlog Refine** (`/refine-story`) when informal one item | `complex`, multi-US/TS, several `needs_*`, or brownfield with parallel specialists |
| **Product Initiative** | **Full O1** (always start here unless operator explicitly chooses refine-first) | Default — decompose to FEATURE + US/TS before O2 |
| **Problem / Need** | **Backlog Refine** when one bug/story + scorecard is enough; **Classic SDD** when fix scope is clear and single-story | Multi-area impact, unclear root cause, or security/supply-chain signals |
| **Idea** | **Backlog Refine** (shape one story or spike note); ask before any write | Only after refine + operator confirms multi-story / brownfield / `needs_*` — then re-enter O1 |

### Early handoff (stop O1 parent flow)

When the mapped path is **not** full O1, present choice (pt-BR) and hand off — do **not** allocate NNN-slug or run Step 0 Memory Bank Gate unless the operator insists on O1 anyway:

| Path | Handoff |
|------|---------|
| Classic SDD | `/sdd-spec` (after STORY exists under `features/…` when using preferred storage) |
| Backlog Refine | `/refine-story` |
| Trivial fix | `/developer` or stack `*-developer` (see `triage.md` § Trivial shortcut) |
| Resume existing O1 | `/orchestrate-analyze - <portable-feature-path>` |

Record the classified intent + chosen path in chat; if continuing O1, carry intent into FEATURE.md triage section and CONTINUITY decisions.

---

## When to spawn specialists **before** backlog synthesis

Load `ROSTER.md` + `spawn-map.md` when any row applies. Spawn **before** step 8 synthesize (after scaffold when folders exist) so ANALYSIS / ARCH / SEC notes inform STORY merge — not after human gate.

| Trigger | Spawn (parallel within SPAWN ≤4 cap) | Why before synthesis |
|---------|-------------------------------------|----------------------|
| **Existing Feature** + brownfield + new stories touch unknown modules | `repo_analyst` | Map blast radius before story split |
| **New Feature** + `needs_domain` or greenfield without established style | `architect` → ARCH confirm gate (`arch-confirm.md`) | Style + boundaries before US/TS sizing |
| **Product Initiative** + multiple bounded contexts or APIs | `architect`; add `repo_analyst` if brownfield | Decompose initiative without inventing architecture in parent |
| **Problem / Need** + auth / secrets / PII / feed-token / supply-chain | `security` | Do not defer `needs_security` to synthesis |
| **Problem / Need** + persistence / migration / schema | `database` | DDL and migration boundaries before TS split |
| **Idea** → promoted to O1 after refine | Same as **New Feature** once intent reclassified | Specialists run only after scope is no longer "idea-only" |

Optional (CONTINUITY note only, no Task): `needs_frontend`, `needs_devops`. Do **not** spawn stack `*-developer` agents in O1.

---

## Process — Intent classification (load at O1 Step 1 triage entry)

1. Reuse Prior context (goal, cited paths, pasted notes).
2. Pick **one** primary intent from the table above.
3. Apply **Map intent → track**; if early handoff, confirm with operator and **STOP** O1 (no Step 0 unless full O1 continues).
4. If full O1 continues: proceed to Step 0 Memory Bank Gate, then `triage.md` (complexity / nature / scope / `needs_*`).
5. At spawn step, apply **before backlog synthesis** table; then synthesize per `story-synthesis.md`.

Cross-refs: `triage.md` (complexity table), `boundaries-handoff.md` (track boundaries), `PIPELINE.md` (work tracks).
