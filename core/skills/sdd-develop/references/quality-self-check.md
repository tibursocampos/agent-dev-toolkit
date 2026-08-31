## Quality self-check (before marking Completed)

- [ ] Only this step’s scope implemented
- [ ] Step **Aceite** REQ-NNN / CA items verified and checked in PLAN
- [ ] Tests added/updated per step and REQ/CA mapping
- [ ] Targeted build/test commands run successfully
- [ ] Evidence-or-zero: if level ≥ `cheap`, `features/NNN-slug/EVD/` + `STATE.md` updated and `validate-evidence` exit 0 (`EVD-STATE-CONTRACT.md`)
- [ ] Verifier ran sequentially in this session — **Verifier ≠ O3** (do not spawn Task/O3 parallel children as the evidence gate)
- [ ] Living loop (when closing wave): `TRACE.jsonl` has converge → sync_current → archive; `validate-trace -RequireArchiveComplete` exit 0 (`TRACE-ARCHIVE-CONTRACT.md`)
- [ ] No forbidden patterns from `csharp-patterns.md` (if .NET)
- [ ] Branch valid per `branch-validation.mdc`
- [ ] PLAN progress and next step updated
- [ ] Context checkpoint executed

---
