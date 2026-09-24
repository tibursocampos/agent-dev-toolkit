# Mode isolation (feature | tech | split)

**REQ-004 / CA2 / CT2.** Load **exactly one** mode playbook after Step 0.5. Never preload the other two. Do **not** invent a fourth product mode or a parallel `clarify` / `feature-refinement` skill (REQ-007).

## Isolation matrix (observável)

| Concern | `feature` | `tech` | `split` |
|---------|-----------|--------|---------|
| Playbook file | `references/feature.md` **only** | `references/tech.md` **only** | `references/split.md` **only** |
| Default item types | User Story \| Bug | Technical Story | Any one type (ask once) |
| Type template load | **one** of `user-story.md` \| `bug.md` | `technical-story.md` **only** | **one** matching type |
| Persona / JTBD | Allowed for User Story | **Forbidden** unless operator switches mode to `feature` | Only if User Story + Who/Job helps |
| Primary outcome | Product-facing refine + scorecard | Technical problem→solution refine | Steps ready for `/split-story-checklist` |
| Chat prompt prefix | `[Refine · feature]` | `[Refine · tech]` | `[Refine · split]` |
| May load other mode playbooks? | **No** | **No** | **No** — do not run full feature/tech playbooks |

## Hard stops (leak prevention)

1. Mode unset / invalid → **STOP**; ask Trigger prompt; load **zero** playbooks.
2. Operator asks for rules from another mode mid-session → either **switch mode explicitly** (re-resolve 0.5, unload prior playbook rules) or answer with a one-line pointer and stay in current mode — never merge playbooks.
3. `split` reshapes steps only; it does **not** silently become a product or tech full refine.
4. Envelope `mode` field **must** match the active playbook (see `interaction-envelope.md`).

## CT2 checklist (manual — ≥2 modes)

Pick any two of `{feature, tech, split}` and verify:

- [ ] Each invocation loads **only** its playbook path
- [ ] Prompt prefix / envelope `mode` differ between the two
- [ ] Type-template set does not overlap incorrectly (e.g. tech never loads `user-story.md`)
- [ ] No `core/skills/clarify/` or `feature-refinement.md` created

## Pointers

| Topic | Path |
|-------|------|
| Per-mode steps | `references/feature.md` \| `tech.md` \| `split.md` |
| Interaction envelope | `references/interaction-envelope.md` |
| READY dual-plane | `readiness-severity.md` (consume; do not rewrite taxonomy) |
| Exclusions | `references/exclusions.md` |
