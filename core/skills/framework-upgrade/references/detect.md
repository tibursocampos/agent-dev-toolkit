# Detect — framework_id resolution

Resolve which pack to load **before** version policy or progressive pack refs. Signals live in each `packs/<id>/PACK.md` (Detect signals table). This file is the **actionable orchestrator flow**.

Companion: `version-policy.md` (range), `packs/REGISTRY.md` (known ids).

---

## Flow (Must)

```
1. List on-disk packs from packs/REGISTRY.md (Must: angular, dotnet; Could slots ignored until PACK.md exists).
2. For each pack with PACK.md: score Detect signals against the workspace (Strong > Medium > Weak).
3. Count candidates with ≥1 Strong hit, or ≥2 Medium if no Strong.
4. Branch on candidate count:
```

| Candidates | Action |
|------------|--------|
| **Exactly 1** | Set `framework_id` to that pack id. Optionally confirm in chat when Medium-only (no Strong). |
| **0** | **Ask once** — list known registry ids + “other / cancel”. Do **not** assume a default. **STOP** until operator answers. |
| **>1** | **Ask once** — show ranked candidates + signal evidence (paths/hits). Operator picks one `framework_id`. Do **not** pick silently. |

After resolve: load `packs/<id>/PACK.md` → continue with `version-policy.md`.

---

## Blocking questions (minimal)

Ask **at most one** TE03 question per session for framework resolve. Question component form: single select, ids fixed in English. Render each `question:` and label in the user chat language. Answer mapping: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`.

1. **0 candidates:**

```text
header: framework-upgrade framework_id
question: Which framework_id?
single select:
- angular: Angular pack (PACK.md on disk)
- dotnet: .NET pack (PACK.md on disk)
- cancel: stop; no pack is loaded
```

   A free-text name with no `PACK.md` is recorded as a gap; do not invent a pack id. Registry ids without `PACK.md` (`python`, `node`, `react`) are not options yet.

2. **>1 candidates:** one option per candidate with at least one Strong hit (or two Medium hits, when there is no Strong), plus `cancel`. Each description carries the strong/medium hits and a sample path:

```text
header: framework-upgrade framework_id
question: which framework_id? (candidates shown with evidence)
single select:
- <candidate pack id>: <strong/medium hits; sample path>
- cancel: stop; no pack is loaded
```

Do **not** re-ask if operator already provided `framework_id` in the invoke. Do **not** chain mode + version + framework into one mega-prompt when TE03 alone blocks.

---

## Scoring notes

- Prefer **Strong** signals from the pack’s Detect table (e.g. `angular.json` + `@angular/core`; `*.sln` + `*.csproj` TFM).
- Weak-only hits (e.g. lone `nuget.config`) → treat as **non-candidate** unless operator confirms.
- Monorepos with both Angular and .NET → expect **>1**; ask. Do not merge packs.
- User-provided `framework_id` that has no `PACK.md` → `audit`/`plan` may record “pack not on disk”; `migrate` **STOP** (`version-policy.md`).

---

## Checklist (observable)

- [ ] No silent default when 0 or >1 candidates
- [ ] Ask is actionable (ids listed; evidence shown when ambiguous)
- [ ] After answer, single `framework_id` before loading pack cascade
- [ ] Silence ≠ pick — same honesty as migrate gate (do not invent framework)

---

## Progressive load

| Need | Load |
|------|------|
| This flow | `references/detect.md` |
| Pack signals / range | `packs/<id>/PACK.md` only |
| Version pair after id known | `references/version-policy.md` |
| Out of range | `references/research-protocol.md` |
