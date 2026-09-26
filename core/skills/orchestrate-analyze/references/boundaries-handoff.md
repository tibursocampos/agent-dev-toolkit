## Boundaries vs refine-story / sdd-spec / O2

| Aspect | `refine-story` (Backlog Refine) | `orchestrate-analyze` (O1) | `sdd-spec` (Classic SDD) | `orchestrate-deliver` (O2) |
|--------|--------------------------------|---------------------------|----------------------------|
| Purpose | One informal item + scorecard + mode envelope/Q&A | Multi-agent triage + US/TS backlog | Full PRD one story | PRD+PLAN per approved story |
| Output | STORY or `docs/backlog/` + envelope / `REFINE/qa-history.md` | FEATURE + CONTINUITY + STORY×N after the open-question gate | `…/PRD/*.md` | `…/PRD/` + `…/PLAN/` |
| Specialists | None | Conditional Task (`needs_*`) | None | sdd contracts per story |
| App code | No | No | No | No |
| When | Informal single item | Complex / multi-story / brownfield | Ready for one PRD and no open question | After O1 **sim**, with a closed FEATURE and story folders already created |

Escalate **to O1** from refine when: multiple stories, unclear `needs_*`, brownfield needs parallel specialists.

Escalate **to sdd-spec** when: single story clear enough for PRD without O2 batching **and** no question is open, including `MINOR` (`open_question`).

### Refine envelopes / READY (O1 light — WS11 / REQ-005–006)

When receiving a refine handoff or routing early to `/refine-story`, consume — do **not** duplicate taxonomy:

| Topic | Pointer |
|-------|---------|
| Mode isolation (`feature` \| `tech` \| `split`) | `skills/refine-story/references/mode-isolation.md` |
| Interaction envelope + Q&A history | `skills/refine-story/references/interaction-envelope.md`, `qa-history.md` |
| READY / NEEDS_CLARIFICATION dual-plane | `skills/_shared/sdd-artifacts/readiness-severity.md` (006 SoT; do not rewrite Assert PS1) |

Handoff strings use **portable** feature/story paths only (`STORAGE.md` § Portable path). READY ≠ SESSION `step_confirmed`. Do **not** create a parallel clarify skill.

Do **not** write PRD/PLAN inside O1. Do **not** claim `sdd-develop` one-step contract changed.

Scorecard: reuse `skills/refine-story/references/scorecard-rubric.md` (universal + type-specific; output shape `scorecard-template.md`). Map totals to STORY 1-5: 80+ -> 5, 60-79 -> 4, 40-59 -> 3, else ≤2.

Story sizing: `skills/_shared/backlog-item-types/story-sizing.md` — load at synthesis; merge/split before human gate; FEATURE table **Rationale** column required.

Product artifact quality gates (REQ-004): FEATURE depth (Problem/Goals/Non-goals), promotion anti-task-shatter, cap ≤4 US/TS — see `references/story-synthesis.md` § Product artifact quality gates. Do not hand off to O2 until those gates pass, the FEATURE has **no** open question (`open_question`, including `MINOR`), story folders already exist, and backlog **sim**.

O2 handoff requires a closed FEATURE and stories already created. A feature that stopped at step 8c is not an O2 handoff.

---

## Canonical handoff strings

```text
/orchestrate-deliver - <portable-feature-path>
```

```text
/orchestrate-analyze - <portable-feature-path>
```

```text
/refine-story
```

(Prefer explicit mode + portable story path when known. When the handoff is orchestrated, pass `mode=feature` or `mode=tech`. Do not leave the mode for `refine-story` to ask.)

```text
/developer
```

```text
/sdd-spec - <portable-story-path>
```

O2 **series vs parallel** is chosen inside `orchestrate-deliver` - document the choice to the user; do not implement O2 in this skill.

After O2 (for awareness only):

```text
/sdd-develop - <portable-plan-path> - Step N
/orchestrate-develop - <portable-feature-path>
```
