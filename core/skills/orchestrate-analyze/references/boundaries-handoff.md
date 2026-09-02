## Boundaries vs refine-story / sdd-spec / O2

| Aspect | `refine-story` (Backlog Refine) | `orchestrate-analyze` (O1) | `sdd-spec` (Classic SDD) | `orchestrate-deliver` (O2) |
|--------|--------------------------------|---------------------------|----------------------------|
| Purpose | One informal item + scorecard | Multi-agent triage + US/TS backlog | Full PRD one story | PRD+PLAN per approved story |
| Output | STORY or `docs/backlog/` | FEATURE + CONTINUITY + STORY×N | `…/PRD/*.md` | `…/PRD/` + `…/PLAN/` |
| Specialists | None | Conditional Task (`needs_*`) | None | sdd contracts per story |
| App code | No | No | No | No |
| When | Informal single item | Complex / multi-story / brownfield | Ready for one PRD | After O1 **sim** |

Escalate **to O1** from refine when: multiple stories, unclear `needs_*`, brownfield needs parallel specialists.

Escalate **to sdd-spec** when: single story clear enough for PRD without O2 batching.

Do **not** write PRD/PLAN inside O1. Do **not** claim `sdd-develop` one-step contract changed.

Scorecard: reuse `skills/refine-story/references/scorecard-rubric.md` (universal + type-specific; output shape `scorecard-template.md`). Map totals to STORY 1-5: 80+ -> 5, 60-79 -> 4, 40-59 -> 3, else ≤2.

Story sizing: `skills/_shared/backlog-item-types/story-sizing.md` — load at synthesis; merge/split before human gate; FEATURE table **Rationale** column required.

Product artifact quality gates (REQ-004): FEATURE depth (Problem/Goals/Non-goals), promotion anti-task-shatter, cap ≤4 US/TS — see `references/story-synthesis.md` § Product artifact quality gates. Do not hand off to O2 until gates pass and backlog **sim**.

---

## Canonical handoff strings

```text
/orchestrate-deliver - <portable-feature-path>
```

```text
/orchestrate-analyze - <portable-feature-path>
```

```text
/developer
```

```text
/sdd-spec
```

O2 **series vs parallel** is chosen inside `orchestrate-deliver` - document the choice to the user; do not implement O2 in this skill.

After O2 (for awareness only):

```text
/sdd-develop - <portable-plan-path> - Step N
/orchestrate-develop - <portable-feature-path>
```
