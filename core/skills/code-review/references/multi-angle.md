## Multi-angle mode

Optional enrichment of the same report template. **No silent default:** if the invoke omits both single and multi, the skill **must ask** (pt-BR) before step 0.5 - see `SKILL.md` § Trigger and § 0.25. O3 may suggest review; never auto-blocks the pipeline.

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
- [ ] Performance smells (N+1, unbounded work, missing async)
- [ ] Maintainability (naming, method size, duplication, magic values)

**Acceptance (aceite)**

- [ ] PRD acceptance criteria mapped to evidence in the diff
- [ ] PLAN completed steps match deliverables; no silent drift
- [ ] Business rules from PRD present where in scope
- [ ] Gaps flagged as important or critical per severity (not a separate gate)

**Security (segurança)**

- [ ] AuthZ / AuthN assumptions for new endpoints or jobs
- [ ] Input validation / injection (SQL, command, template)
- [ ] Secrets and PII handling (no hardcoded secrets; no sensitive logs)
- [ ] Dangerous defaults - hint source: `_shared/agents/prompts/security.md`
- [ ] Evidence-based findings only; state what to verify if data is missing

### Merging Task outputs into the report

1. Load `SPAWN.md`; consult capability `subagents`. When `native`: spawn one Task per requested angle (parallel, ≤3); when `none` or Task unavailable → **fallback** sequential **in-parent** angles (never hard-fail). Parent keeps the default flow for build/test/coverage.
2. Deduplicate overlapping findings; keep the strongest severity and clearest `path:line`.
3. Map into the existing template sections:
   - Blocking bugs / security / broken PRD scope -> **Problemas críticos**
   - Non-blocking quality, PLAN/PRD drift, gaps -> **Problemas importantes**
   - Optional polish -> **Nice-to-have**
4. Fold security-angle notes into § Segurança; acceptance into § Aderência ao PRD / Verificação do PLAN; quality into analysis sections and positives.
5. Apply the **same** decision matrix and coverage gates - multi-angle does not change Approved / Approved with reservations / Changes required semantics.
