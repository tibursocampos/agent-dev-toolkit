# inventory → specialist synthesis

**REQ-011 / CA4 / CT4.** Contract id: `inventory-specialist-synthesis`. Load **after** Step 5 inventory and **before** (or as the first pass of) Step 6 scaffold/refresh fills. Applies to `/memory-bank-init` create | refresh | refresh-light.

**Language:** English identifiers and reason codes. Operator chat follows session language (`LANGUAGE.md`). Portable paths only (`STORAGE.md` § Portable path).

Companions: `MEMORY-BANK.md`, `SELECTIVE-RETRIEVAL.md` (`SR-NO-FULL-DUMP`), `_shared/agents/SPAWN.md`, `_shared/agents/ROSTER.md`, `references/inventory-fallback.md`, `references/template-map.md`.

---

## Purpose

Turn **read-only inventory evidence** into **actionable bank fills** via roster specialists (or thin in-skill synthesis). Inventory alone is not enough — synthesize into MVP / phase-2 bank targets with evidence-backed prose and gaps.

## Observable flow

```text
Step 5 inventory (sources.json v3)
  → signal map from inventory_summary / stack_hints / curated sources[]
  → specialist synthesis (spawn ≤4 or thin in-skill)
  → merge receipts into GENERATED regions + gaps.md (+ phase-2 when BLOCKING)
  → Step 6 scaffold/refresh completes
  → Step 7 report (include synthesis roles used)
```

| Stage | Input (selective) | Output |
|-------|-------------------|--------|
| Inventory | Script or `inventory-fallback.md` | `.inventory/sources.json` governance fields |
| Signal map | `status`, `status_reason`, `inventory_hash`, `inventory_summary`, `stack_hints`, capped `sources[]` summaries | Role list + target bank files |
| Specialist synthesis | Portable `bank_root` + named bank paths + inventory governance + **short** source summaries | Receipts: facts for architecture / domain / risks / phase-2 |
| Merge | Specialist receipts | GENERATED blocks, `gaps.md` (preserve `BLOCKING:`), phase-2 stubs when relevant |

**Thin trivial:** single obvious stack with no domain/schema/auth signals → synthesize **in-skill** from inventory + README/AGENTS (no Task). Any multi-file uncertainty, persistence, auth/PII, or architecture ambiguity → spawn specialists.

## Signal → specialist map

Use **ROSTER** role ids (`ROSTER.md`) — stable toolkit ids only (do **not** invent Supply/Jarvis names). For this skill, specialists return **bank** receipts (merge into `bank_root`), **not** feature `ANALYSIS/` / `ARCH/` / `SEC/` folders (those remain O1).

| Inventory / Prior signal | Specialist (ROSTER id) | Bank targets (selective) |
|--------------------------|------------------------|--------------------------|
| Multi-module / brownfield blast radius unclear | `repo_analyst` | `project-context.md`, `architecture.md` (layers), `gaps.md` |
| Greenfield / no established style / domain boundaries | `architect` | `architecture.md`, `domain-knowledge.md` |
| Persistence / DDL / migrations / DbContext | `database` | `database-schema.md` (phase 2 **BLOCKING** when DDL cited), `gaps.md` |
| Auth / secrets / PII / supply-chain tokens | `security` | `known-risks.md`, `gaps.md` (env **names** only) |
| Stack / lockfile / tooling only (no domain ambiguity) | *(in-skill — no Task)* | `tech-stack.json`, `conventions.md` GENERATED from `stack_hints` |

Spawn **in parallel** within SPAWN ≤4 cap when independent. Parent stays lean: goals, paths, receipts — **no** app code from specialists. Do **not** spawn `qa_checklist` as a Task.

## Child prompt contract (actionable)

Pass **only**:

1. Portable `bank_root` and **named** target file paths (e.g. `memory-bank/architecture.md`)
2. Inventory governance: `status`, `status_reason`, `inventory_hash`, `inventory_summary`
3. Cap of curated `sources[]` path+summary lines (prefer ≤20; never entire tree)
4. Mode: `create` | `refresh` | `refresh-light` (refresh-light → GENERATED/`tech-stack.json` only)

Receipt (en-US): role, target paths, ≤5 bullets of evidenced facts, open gaps (`BLOCKING:` when Prior already has DDL/OpenAPI/UI map). Parent merges; specialists **must not** Write app/test source.

## Selective retrieval (`SR-NO-FULL-DUMP` / RNF-004)

| Do | Do not |
|----|--------|
| Cite portable paths + short summaries | Dump entire `memory-bank/` into skill or specialist prompts |
| Read named bank files needed for the merge | Paste full `sources.json` bodies into parent/child chat |
| Point to `SELECTIVE-RETRIEVAL.md` | Wholesale Supply / Reversa dump into refs |

Normative: `SELECTIVE-RETRIEVAL.md` rule `SR-NO-FULL-DUMP`. Smoke: `Assert-SelectiveRetrieval.ps1` when in-scope.

## Skip D (REQ-013 / CA4) — explicit

This skill **must not** introduce or invoke:

| Forbidden (Skip D) | Why |
|--------------------|-----|
| **ADO mutate** / Azure Boards WI create-update | OOS WS13; no work-item side effects |
| **Reversa** constitution / skill trees | OOS; not a second SoT |
| **SpecKit constitution** / `.specify/` / uv / specify installers | Credits may mention inspiration; **do not** run Spec Kit or adopt its constitution |

Also forbidden: inventing `framework-upgrade`, Jarvis/`JARVIS_*` names, or new skill folders for synthesis.

## STOP / reason codes

| Code | When |
|------|------|
| `inventory_not_ready` | `status` = `not-ready` — surface `status_reason` before synthesis fills |
| `synthesis_skip_d_violation` | Prompt/diff would add ADO mutate, Reversa, or SpecKit constitution |
| `synthesis_full_dump` | Child/parent prompt would dump integral bank or full PRD |
| `synthesis_app_write` | Specialist attempted app/test source Write |

## Skill wiring

| Consumer | When to load |
|----------|----------------|
| `memory-bank-init` | After Step 5; before/with Step 6 fills |
| Orchestrated Delivery Step 0 | Parent may cite this contract when create/refresh runs under init |
| O1 / O3 | Consume bank selectively after init — do **not** re-run full synthesis unless stale gate says refresh |

## Must not

- Skip synthesis when inventory signals domain/schema/auth ambiguity (thin-trivial only)
- Dump integral `memory-bank/` or paste full PRD into prompts (`SR-NO-FULL-DUMP`)
- ADO mutate, Reversa, SpecKit constitution (Skip D / REQ-013)
- Write application or test source; place bank under `features/NNN-slug/`
- Create a parallel clarify/init skill folder
