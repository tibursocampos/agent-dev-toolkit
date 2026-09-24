# Authorship git-notes (opt-in, beside TRACE)

**Audience:** maintainers / operators who want optional commit authorship metadata next to a feature TRACE trail.

**Default: off.** Without an explicit opt-in, no git notes are written (REQ-016 / CT5).

## Relationship to TRACE (REQ-017 / REQ-018 / RN03)

| Layer | Role | SoT? |
|-------|------|------|
| `features/NNN-slug/TRACE.jsonl` | Living-loop event trail (append-only) | **Yes** — sole TRACE SoT |
| `refs/notes/toolkit-authorship` | Optional authorship metadata on commits | **No** — parallel / orthogonal |

- **Never** treat git-notes as a substitute for `TRACE.jsonl` (TE06).
- `scripts/trace/Invoke-TraceHarvest.ps1` and `scripts/validation/validate-trace.ps1` read **TRACE only** — they do not harvest notes.
- Contract: [`TRACE-ARCHIVE-CONTRACT.md`](../../core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md) (git-notes must not become TRACE SoT).
- Honesty matrix: [`trace-emitter-honesty.md`](../../adapters/_shared/trace-emitter-honesty.md).

## Helper

```powershell
# Default off — exits 0; does not write notes
pwsh -NoProfile -File .\scripts\trace\Invoke-AuthorshipGitNotes.ps1 `
  -FeatureRoot features\008-toolkit-evolution-remaining

# Opt-in write (explicit -Enable)
pwsh -NoProfile -File .\scripts\trace\Invoke-AuthorshipGitNotes.ps1 `
  -FeatureRoot features\008-toolkit-evolution-remaining `
  -Enable `
  -Message 'operator authorship sign-off'

# Inspect note for HEAD (read-only)
pwsh -NoProfile -File .\scripts\trace\Invoke-AuthorshipGitNotes.ps1 `
  -FeatureRoot features\008-toolkit-evolution-remaining `
  -Action show
```

Notes use ref `toolkit-authorship` (`git notes --ref=toolkit-authorship`). Failures to write notes must not change TRACE append behavior (emitters stay fail-open; this helper is separate).

## What not to do

- Do not point harvest / archive gates at notes.
- Do not invent a second JSONL trail or `.agent-trace/` for authorship.
- Do not put secrets, tokens, or PII in note messages.
