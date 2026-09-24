# Review policy refs (WS16a / REQ-016)

**Family:** `policy`. Load during Process §3–4 when the diff touches skills, rules, agents, Publish adapters, git flow, or toolkit always-on behavior. Prefer project `docs/standards/` / `AGENTS.md` when reviewing a **consumer** repo.

**Language:** English identifiers and checklist labels. Report prose follows session language (`LANGUAGE.md`).

**Contract:** pointers only — **do not** paste full policy bodies into the review report (`SR-NO-FULL-DUMP` / RNF-004).

Companions: `references/contracts.md`, `references/n-plus-one.md`, `references/verification.md`.

---

## Pointer index (cite path; open on demand)

| Topic | Portable path (after sync) | When to load |
|-------|----------------------------|--------------|
| Guardrails (git / write / one-step / tests) | `{{GUARDRAILS_PATH}}` or `core/policy/guardrails.md` | Any review that judges agent/skill diffs or mutating git advice |
| SDD pipeline guards | `core/policy/sdd-pipeline-guards.md` | Diffs under `features/`, SDD skills, PRD/PLAN boundaries |
| Branch naming | `core/policy/branch-validation.md` | Branch/PR naming in scope |
| Commit message shape | `core/policy/conventional-commits.md` | Commit/PR title hygiene in scope |
| Orchestrator / parent role | `core/policy/orchestrator-session.md` | O3 / spawn / parent-vs-child diffs |
| Context pressure | `core/policy/context-management.md` | Skills that change session/checkpoint behavior |
| Model cost (informational) | `core/policy/model-cost-awareness.md` | Always-on cost hygiene; warn-once; never blocks (WS9 / 007 CA8) |
| Caveman | `core/policy/caveman-mode.md` | Caveman / compact prose skill changes |
| AI stealth trailers | `core/policy/ai-stealth.md` | Commit/PR co-author trailer policy |
| Chat language | `core/policy/user-language-pt-br.md` | Language-surface skill changes (install default; honor `LANGUAGE.md` matrix) |
| SDD artifact language | `core/policy/sdd-artifact-language-pt-br.md` | PRD/PLAN language policy diffs (install default; honor `LANGUAGE.md` matrix) |
| Language surfaces SoT | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` | Any chat vs spawn vs SDD-locale surface change |

Repo source of truth for the toolkit tree: `core/policy/`. Installed hosts may mirror as rules (`.mdc`) — same **ids/topics**; do not invent a second policy SoT.

---

## Actionable checklist (policy family)

Run on the **changed** surface only; skip rows that do not apply.

- [ ] Diff does not weaken guardrails: git still blocked by default; write confirm; one PLAN step per develop session; tests before Complete
- [ ] SDD skills still hand off PRD/PLAN writes to `/sdd-spec` / `/sdd-plan` (no silent authoring in ops skills)
- [ ] Branch / conventional-commit guidance still points at `branch-validation` / `conventional-commits` (or project equivalents)
- [ ] Parent/orchestrator diffs still honor `orchestrator-session` (parent does not implement child work)
- [ ] No new always-on policy that bypasses SESSION gates or invents a second SoT
- [ ] `model-cost-awareness` (when present) stays informational / never-block; no product model ID allowlists or billing fields
- [ ] Consumer-repo review: project `docs/standards/` / `AGENTS.md` preferred over dumping toolkit policy into the report
- [ ] Language-surface diffs honor `LANGUAGE.md` matrix over hard-coded locale install defaults

**Severity hint:** weakened gates / silent PRD writes / auto-merge → **critical** or **important**; cosmetic policy prose → **nice-to-have**.

## CT6 marker (policy)

- [ ] This file is reachable from `code-review` Reference routing / Process §3–4
- [ ] Checklist above is actionable without pasting full `core/policy/*` bodies
