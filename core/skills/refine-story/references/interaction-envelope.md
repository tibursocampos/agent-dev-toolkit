# Interaction envelope (per refine mode)

**REQ-005 / CA2.** Every refine session that reaches collect/generate emits a typed **interaction envelope**. Shape is mode-scoped: fields that belong to another mode stay omitted (REQ-004).

## Canonical shape (English keys; portable paths only)

```yaml
schema: refine-story.interaction_envelope/v1
mode: feature   # feature | tech | split — MUST match active playbook
invocation_context: direct   # direct | orchestrated (INVOCATION-CONTEXTS.md)
item_type: User Story        # Bug | User Story | Technical Story
status: NEEDS_CLARIFICATION  # READY | NEEDS_CLARIFICATION (readiness-severity.md)
portable_paths:
  story: features/NNN-slug/USnn/STORY.md   # omit until known
  refine_notes: features/NNN-slug/USnn/REFINE/refine.md
  qa_history: features/NNN-slug/USnn/REFINE/qa-history.md
open_questions:
  - severity: B
    text: "<sharp question>"
  - severity: I
    text: "<sharp question>"
minor_questions:
  - severity: MINOR
    text: "<optional>"
qa_history_ref: features/NNN-slug/USnn/REFINE/qa-history.md
handoff_candidate: sdd-spec   # split-story-checklist | orchestrate-analyze | sdd-spec | none
```

**Portable paths only** (`STORAGE.md` § Portable path / RNF-002 / REQ-006). Forbidden in envelopes and handoffs: OS absolute paths (drive-letter or UNC) and InstallRoot embeds under the tool’s `sdd` session root.

## Mode-scoped field rules

| Field / behavior | `feature` | `tech` | `split` |
|------------------|-----------|--------|---------|
| `mode` token | `feature` | `tech` | `split` |
| `item_type` | User Story \| Bug | Technical Story | Any one resolved type |
| Default `handoff_candidate` when READY | `sdd-spec` (or `split-story-checklist` if steps are the ask) | same | **prefer** `split-story-checklist` |
| Persona notes in envelope | optional short Who/Job | omit | only if User Story |
| Steps-readiness note | optional | optional | **required** short note: deps + parallel-safe |

Do **not** attach foreign mode playbook rules inside the envelope body.

## When to emit

| Moment | Action |
|--------|--------|
| After mode resolved (0.5) | Skeleton envelope (`mode`, `invocation_context`, `status: NEEDS_CLARIFICATION` until scored) |
| After scorecard / clarification pass | Refresh `status`, `open_questions`, `portable_paths` |
| On handoff / STOP | Full envelope + Q&A history pointer (`qa-history.md`) |

## Dual-plane READY (consume 006 — do not rewrite)

Status tokens and B/I/MINOR taxonomy: `_shared/sdd-artifacts/readiness-severity.md` only.

| Envelope `status` | Meaning |
|-------------------|---------|
| **READY** | Zero open **B**/**I**; may hand off to `/sdd-spec` / O2 path |
| **NEEDS_CLARIFICATION** | Open **B**/**I** remain — **STOP** fake-forward ready-for-PRD |

**READY ≠** SESSION `step_confirmed` / PLAN step Complete / folder presence (**RN02**, `RDY-DUAL-PLANE`). Do **not** reopen `Assert-SiblingReadinessGate.ps1` / taxonomy scripts in this enrich step.

## Chat report (session user language; English tokens)

```text
Envelope refine-story
mode: feature
status: READY | NEEDS_CLARIFICATION
paths: <portable only>
open B/I: <count>
qa_history: <portable path or "(chat-only — not persisted)">
next: <handoff or answer B/I>
```

## Related

| Topic | Path |
|-------|------|
| Mode isolation | `references/mode-isolation.md` |
| Q&A history | `references/qa-history.md` |
| Boundary STOP | `references/boundary.md` |
| Persistence | `references/persistence.md` |
