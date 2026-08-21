# Credits and acknowledgments

**agent-dev-toolkit** is original software (MIT). Some behaviors and workflows are **inspired by** third-party projects. We are **not** the same products, do not vendor those repositories wholesale, and do not claim affiliation unless stated by those projects.

## Caveman

Response-compression behavior is **inspired by** [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman).

This toolkit ships a **portable preferences/contract integration** (`core/skills/_shared/caveman/`, policy `caveman-mode`, chat commands `caveman on|off|…`), not a full port of that repository. Optional continuity compaction (`COMPACT.md`) is **not** a port of upstream `caveman-compress`.

User guide: [guides/07-caveman-mode.md](guides/07-caveman-mode.md).

## Impeccable

UI/UX command flow and design guidance draw from **[pbakaus/impeccable](https://github.com/pbakaus/impeccable)** / the Impeccable CLI (`npx impeccable`).

The toolkit skill `impeccable` is a **partial, adapter-synced harness** (subset of references, `DESIGN-BRIEF.md` handoff, toolkit gates). Full upstream install/hooks are optional and require **explicit user consent**. Behavior is not identical to running Impeccable standalone.

## Anthropic frontend-design (optional external)

Distinctive-UI heuristics (signature motif, compact token plan before code, UX writing intent) are **inspired in part by** [anthropics/skills `frontend-design`](https://github.com/anthropics/skills/tree/main/skills/frontend-design).

**Canonical stack for product UI in this toolkit:** `/impeccable` → `docs/DESIGN-BRIEF.md` → stack `*-developer`. We do **not** ship Anthropic `frontend-design` as a sibling Core skill.

Use the upstream skill only as an **optional external** reference for one-shot Claude.ai / artifact sessions outside the product handoff path. Do not vendor that repository into Core.

## Memory-bank and Spec Kit

The Orchestrated Delivery *(formerly Forma C)* `memory-bank/` layout and gate policies are a **toolkit-specific durable workspace map** (PowerShell inventory, no Spec Kit toolchain).

Ideas for durable workspace / structured agent memory are **inspired in part by practices around** [github/spec-kit](https://github.com/github/spec-kit). We **do not** apply Spec Kit, `uv`, or `specify` directly — those paths were removed from this toolkit’s MVP in favor of Classic SDD / Backlog Refine / Orchestrated Delivery. Contracts and scripts under `MEMORY-BANK.md` / `memory-bank-init` are original to agent-dev-toolkit. Internal SDD contracts (REQ, validate, CHANGE, EVD, STATE, TRACE) stay inside the existing skill call flow — not a second OpenSpec/Spec Kit product.

## License

Toolkit license: [LICENSE](../LICENSE) (MIT © Raphael Campos). Respect the licenses of any third-party tools you install separately (e.g. Impeccable CLI, Spec Kit).
