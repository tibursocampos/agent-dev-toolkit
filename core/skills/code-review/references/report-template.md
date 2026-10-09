## Report template

Use when writing the final report for the `code-review` skill. Spoken report prose follows `core/skills/_shared/agents/LANGUAGE.md`. Do not lock the spoken report to a single locale, including pt-BR. Severity and tool-status tokens stay English: `critical`, `important`, `nice-to-have`, `PASS`, `FAIL`, and `SKIPPED`. Finding bands are only `critical`, `important`, and `nice-to-have`. `advisory` is not a finding band. Replace bracketed placeholders. The skeleton below is English; render spoken headings and sentences in the chat language from that matrix.

Keep the positives section. Its spoken title follows `core/skills/_shared/agents/LANGUAGE.md`. Each item names one observed good point and cites `path:line` evidence in the diff. When no such evidence exists, the section states that no positive was observed.

---

```markdown
# Code review - [Feature name]

## Executive summary

**Decision:** Approved | Approved with reservations | Changes required

| Metric | Value |
|---------|-------|
| PRD adherence | [e.g. 4/4 criteria] |
| PLAN status | [e.g. 6/6 steps completed] |
| SDD | [PRD/PLAN found - paths] or **SDD limitation** (full search, no artifacts) |
| Files reviewed | [N] |
| Build / tests | [`PASS` / `FAIL` / `SKIPPED`] |
| Coverage (new code) | [X% - Pass ≥ 80% / Below / Not applicable] |
| critical | [0] |
| important | [N] |
| nice-to-have | [N] |

[One paragraph: scope, main findings, recommendation. When the operator passed a pull-request URL and the review identified that range, cite the URL and that range. When `working_tree` and a path list were both set, state that the report covers the uncommitted diff limited to those paths.]

---

## PLAN verification (SDD)

_Omit this section only when step 0.5 recorded an **SDD limitation**._

**PLAN:** [full path]

- Progress: [X/N] - [consistent | listed inconsistencies]
- Completed steps: [list]
- Pending / drift: [list or None]

---

## PRD adherence (SDD)

_Omit this section only when step 0.5 recorded an **SDD limitation**._

**PRD:** [full path]

### Acceptance criteria

| Criterion | Status | Evidence |
|----------|--------|-----------|
| [CA1] | Met / Partial / Missing | [file, test] |

### Business rules

| Rule | Status | Location |
|-------|--------|-----------|
| [RN01] | Met / Missing | [type.method] |

---

## Files reviewed

- [path] - [brief note]

---

## Positives

Spoken title follows `core/skills/_shared/agents/LANGUAGE.md`. Each item names one observed good point and cites `path:line` evidence in the diff. When no such evidence exists, state that no positive was observed.

- [Observed good point — `path:line`]

---

## critical (blocking)

### [Title]

- **File:** `path:line`
- **Category:** Security | Bug | Breaking change
- **Problem:** [what is wrong]
- **Impact:** [why it blocks merge]
- **Suggested fix:** [concrete steps]

---

## important (non-blocking)

### [Title]

- **File:** `path:line`
- **Problem:** [what to improve]
- **Suggestion:** [how]

---

## nice-to-have

- [Optional improvements]

---

## Tests

- **Unit:** [`PASS` / `FAIL` / `SKIPPED`, scope]
- **Integration:** [`PASS` / `FAIL` / `SKIPPED`, scope]
- **Gaps:** [scenarios not covered]
- **Coverage (new code / changed files):** [X% - Pass ≥ [threshold]% / Below target / Not run]
- **Overall coverage (branch):** [Y% - informational]
- **Target:** 100% (acceptable minimum: [80]% when a target applies)
- **Source:** `/test-coverage` - [paste the report block or N/A]

---

## Security

- [ ] No hardcoded secrets
- [ ] Input validation on external data
- [ ] No sensitive data in logs
- [ ] Parameterized data access (no SQL concatenation)

Problems: [None | listed]

---

## Performance

- [ ] No obvious N+1 in the changed code (ref: `references/n-plus-one.md`)
- [ ] Async for I/O-bound work
- [ ] No unbounded loops or allocations on hot paths

Problems: [None | listed]

---

## Policy / contracts (when the surface applies)

- [ ] Policy / gates: `references/policy.md` (skills, rules, git flow)
- [ ] Contracts / SDD / CHANGE / paths: `references/contracts.md`
- [ ] No `framework-upgrade` folder or skill introduced without an approved feature (WS16b out of scope)

Problems: [N/A | None | listed]

---

## Refactoring opportunities (optional)

| Priority | Area | Benefit |
|------------|------|-----------|
| Medium | [method/class] | [readability / testability] |

---

## Final recommendation

An open `critical` stays blocking until a new review shows the fix. Offer at most three automatic rounds, and do not offer a fourth. Do not downgrade the band spontaneously. The default decision is `Changes required`. If the operator explicitly keeps the `critical` band and continues, record that decision and do not block.

**Decision:** [Approved | Approved with reservations | Changes required]

**Required before merge:**

1. [Action or None]

**Recommended after merge:**

1. [Action or None]

**Author next steps:**

- [ ]
```

---
