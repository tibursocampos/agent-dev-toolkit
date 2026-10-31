# Skip policy (Skip D) — framework-upgrade

Explicit denial list for this skill and its future packs.

## Skip D (do not implement / do not import)

| Item | Rule |
|------|------|
| **Tracker mutate** | No create/update/transition of tracker work items from this skill |
| **Org-only prefixed tokens** | No org-branded contracts, env vars, skill ids, or prompt packs |
| **External brand** | No external product branding in skill/pack text or paths |
| **Duration estimates** | No duration / effort / story-point / “ETA” checkpoints in reports or registers |
| **Model pins** | No hard-coded premium model requirements for routine hops |
| **Major-pinned skill ids** | No `dotnet10-upgrade`, `angular-v*-upgrade`, `framework-upgrade-vN` |

## Portability note

Layout-style structure may be curated (modes, progressive load, decision register). External brand names and proprietary playbooks are **out of scope** — strip on port.

## Zero-duration checkpoints

Valid checkpoints: mode, pack id, version pair, decision id, evidence command/exit, operator **sim** yes/no.  
Invalid checkpoints: hours, story points, T-shirt effort, “~30 min left”.

## Grep-oriented markers (for DoD)

Agents and CI may grep this tree for forbidden tokens: org-only prefixes, external brand names, tracker-mutate playbooks, and major-pinned skill `name:` values. This file is the normative Skip D pointer for PASSO 5+.
