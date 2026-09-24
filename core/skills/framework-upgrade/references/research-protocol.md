# Research protocol — framework-upgrade

Used when `targetVersion` (or a required hop major) is **outside** pack `supported_range`, or local refs lack the required major (**REQ-012 / TE04**).

**Sources:** load `sources-catalog.md` **first** (PASSO 8 catalog — official/normative rows before auxiliary blogs/gists). Do not invent alternate SoT. Do **not invent local version deltas** outside `supported_range`.

Companion: `version-policy.md` (in/out of range), `detect.md` (framework_id before range checks).

---

## Research plan (Must order)

| Step | Name | Action |
|------|------|--------|
| 1 | **Inventory** | List majors covered by local pack refs / `supported_range` vs gaps for the requested hop path. |
| 2 | **Official first** | Consult normative URLs from `sources-catalog.md` (Learn / angular.dev / PEP 8 / official blogs) **before** any auxiliary Medium/gist/DEV row. Prefer Update Guide / release notes / compatibility matrix for `targetVersion`. |
| 3 | **Curate** | Promote only stable patterns into `packs/<id>/references/` (parametric deltas — not an eternal single-major snapshot). Pointers only — no wholesale article/gist/PEP paste (`RNF-004`). |
| 4 | **Revalidate** | On each major hop, prefer official source over offline snapshot / auxiliary when they conflict (**RN08**). |
| 5 | **Extend** | Update `supported_range` + deltas via **pack** change; **never** create `framework-upgrade-vN` or major-pinned skill ids; **never invent local deltas** in-session to unblock migrate. |

---

## RN08 — Official wins (checklist)

When official docs conflict with blogs, gists, Medium, or **offline pack/guideline snapshots** on breaking changes or practice gates, **official wins**.

Before claiming research done or extending a pack, verify against:

| Stack | Official checks (Must when applicable) |
|-------|----------------------------------------|
| **.NET** | Microsoft Learn (ASP.NET / TFM / upgrade docs); [.NET release notes](https://learn.microsoft.com/en-us/dotnet/core/whats-new/); official .NET blog when cited in `sources-catalog.md` |
| **Angular** | [angular.dev](https://angular.dev/) Style Guide / best practices; [Angular Update Guide](https://angular.dev/update-guide) / release notes for the hop pair |
| **Python** (guidelines / Could pack) | [PEP 8](https://peps.python.org/pep-0008/) and language/docs.python.org as normative |
| **Any** | Offline snapshot in pack or `_shared/*-guidelines` **loses** to the live official page on conflict — record the official URL in the research note |

Auxiliary catalog rows = curated leads only — never sole evidence for migrate or pack extension.

---

## TE04 — Out of range (STOP)

| Situation | Treatment |
|-----------|-----------|
| `targetVersion` or hop major ∉ pack in-range band | Enter this protocol; do **not** invent hop deltas locally |
| Operator demands **migrate** without official **and** local curated evidence | **TE04 STOP** — stay in `audit`/`plan`; propose pack extension PR path |
| Research blocked (no network / no official URL) | **STOP** mutate; document gap; do not fabricate deltas from memory |

**Forbidden:** inventing local version deltas outside `supported_range`; treating silence as approval to migrate (TE05 still applies after research).

---

## STOP conditions (also)

- Research would require ADO mutate, `JARVIS_*`, or Athena-branded corpora → refuse (Skip D); use public official docs only.
- Pack id unresolved → finish `detect.md` (TE03) before research.

---

## Output

Short research note in chat (and decision register when planning):

- Sources cited: **prefer** `sources-catalog.md` normative URLs + release notes / Update Guide
- Gaps vs `supported_range`
- Recommended pack extension (files to touch) — **no** wholesale article dump
- Explicit: migrate remains gated by operator **sim** (TE05); research ≠ migrate approval
