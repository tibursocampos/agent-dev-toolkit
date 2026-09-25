---
title: Credits
---

# Credits

**agent-dev-toolkit** is original software. The sections below name the outside work that shaped a behavior, and the path where that behavior lives in this repository. The toolkit keeps its own code. It states affiliation only when those projects state it.

## Response compression

Shortening chat prose follows [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman).

What this repository ships is a preferences integration: `core/skills/_shared/caveman/`, policy `caveman-mode`, and chat commands `caveman on|off|…`. Optional continuity compaction is `COMPACT.md`. Upstream `caveman-compress` stays in that project. This is a partial take of the idea, not a copy of the repository.

Compression is one session preference and defaults to off. Commands, and the text that stays in full prose: [Using skills](using-skills.md#session-behavior).

## Impeccable

UI command flow and design guidance draw from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) and the Impeccable CLI (`npx impeccable`).

The toolkit skill `impeccable` is a partial harness synced by the adapters: a subset of references, a `DESIGN-BRIEF.md` handoff, and this toolkit’s gates. A full upstream install, including hooks, stays optional and waits for an explicit yes. Running this skill and running Impeccable on its own are different sessions.

## Anthropic frontend-design

A signature motif, a compact token plan before code, and UX writing intent draw in part from [anthropics/skills `frontend-design`](https://github.com/anthropics/skills/tree/main/skills/frontend-design).

Product UI in this toolkit goes `/impeccable` → `docs/DESIGN-BRIEF.md` → a stack `*-developer`. Upstream `frontend-design` is an optional reference beside that handoff. It is not a Core skill, and that repository is not copied into `core/`.

## Memory bank and Spec Kit

`memory-bank/` in Orchestrated Delivery, and the gate policies around it, are a workspace map written for this toolkit: a PowerShell inventory, with no Spec Kit toolchain.

A durable workspace draws in part on practices around [github/spec-kit](https://github.com/github/spec-kit). This toolkit does not run Spec Kit, `uv`, or `specify`. Those paths left the MVP. The workspace map is Orchestrated Delivery and `memory-bank-init`. Classic SDD contracts run inside that path. Internal contracts (REQ, validate, CHANGE, EVD, STATE, TRACE) stay inside the skill call that already exists.

## Product backlog quality

Norms under `core/skills/_shared/backlog-item-types/` paraphrase public product-management ideas: INVEST, a vertical split, a Gherkin budget, and outcome altitude. The toolkit does not copy third-party corpora into Core, and it does not ship Anthropic project-management slash skills as Core.

| Theme in the toolkit norms | Source |
|----------------------------|--------|
| INVEST story quality | [xp123 — INVEST in Good Stories](https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/) |
| Vertical / thin-slice splitting | [Mountain Goat — story splitting](https://www.mountaingoatsoftware.com/agile/user-stories/story-splitting) |
| Gherkin / observable Then | [Cucumber — Gherkin reference](https://cucumber.io/docs/gherkin/reference/) |
| Outcome vs story vs task altitude | [Jeff Patton — User Story Mapping](https://www.jpattonassociates.com/user-story-mapping/) |

Evidence fields follow omit over fabricate (`product-evidence-lite.md`). A scorecard does not require invented Evidence. Chat compression leaves product drafts (FEATURE, STORY, PRD) in full prose. See `core/skills/_shared/caveman/CAVEMAN.md`.

## License

MIT © Raphael Campos (`LICENSE` in the repository). Tools you install separately keep their own licenses, including the Impeccable CLI and Spec Kit.
