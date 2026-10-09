## Multi-angle mode

Optional enrichment of the same report template. **No silent default:** if the invoke omits both single and multi, the skill **must ask** in the chat language from `core/skills/_shared/agents/LANGUAGE.md` before step 0.5 - see `SKILL.md` § Trigger and § 0.25. O3 may suggest review; never auto-blocks the pipeline.

### Invoke examples

```text
/code-review
/code-review - single
/code-review - multi-angle
/code-review - ângulos: qualidade, aceite, segurança
```

Bare `/code-review` -> ask mode (1 single / 2 multi-ângulo). Subset allowed, e.g. `ângulos: qualidade, segurança`. Synonyms: `multi-ângulo`, `multi-angle`, `single`, `single-angle`, `simples`.

### Checklist per angle

**Quality (qualidade)**

- [ ] Correctness / edge cases / error handling in the diff
- [ ] Architecture and layer boundaries
- [ ] Meaningful tests for changed behavior
- [ ] Performance smells (N+1, unbounded work, missing async) — `references/n-plus-one.md`
- [ ] Policy / gate regressions when skills/rules change — `references/policy.md`
- [ ] Maintainability (naming, method size, duplication, magic values)

**Acceptance (aceite)**

- [ ] PRD acceptance criteria mapped to evidence in the diff
- [ ] PLAN completed steps match deliverables; no silent drift
- [ ] Contracts / CHANGE / portable paths when those files change — `references/contracts.md`
- [ ] Business rules from PRD present where in scope
- [ ] Gaps flagged as important or critical per severity (not a separate gate)

**Security (segurança)** — run this checklist only when the mode is multi-angle and the security angle was requested. A single review does not run it. Fill the report security section with finding bands `critical`, `important`, and `nice-to-have`. Do not write `SEC/`. Do not emit blocks `B`, `I`, or `MINOR`. This checklist does not waive the closeout pass in `core/skills/_shared/agents/prompts/security.md`, and that pass does not waive this checklist.

- [ ] AuthZ / AuthN assumptions for new endpoints or jobs
- [ ] Input validation / injection (SQL, command, template)
- [ ] Secrets and PII handling (no hardcoded secrets; no sensitive logs)
- [ ] Dangerous defaults - hint source: `_shared/agents/prompts/security.md`
- [ ] Evidence-based findings only; state what to verify if data is missing

### Merging Task outputs into the report

1. Load `SPAWN.md`; consult capability `subagents`. When `native`: spawn one Task per requested angle (parallel, ≤3); when `none` or Task unavailable → **fallback** sequential **in-parent** angles (never hard-fail). Parent keeps the default flow for build/test/coverage.
2. Deduplicate overlapping findings; keep the strongest severity and clearest `path:line`.
3. Map into the existing template sections. Finding bands are only `critical`, `important`, and `nice-to-have`. `advisory` is not a finding band. Do not use a Portuguese label as a band name.
   - Blocking bugs / security / broken PRD scope -> `critical`
   - Non-blocking quality, PLAN/PRD drift, gaps -> `important`
   - Optional polish -> `nice-to-have`
4. Fold security-angle notes into the security section; acceptance into PRD adherence and PLAN verification; quality into the analysis sections. Positives follow the same rule as step 7 and `references/report-template.md`: a title in the language from `core/skills/_shared/agents/LANGUAGE.md`, `path:line` evidence in the diff, or the statement that no positive was observed.
5. Apply the **same** decision matrix and coverage gates - multi-angle does not change Approved / Approved with reservations / Changes required semantics.
