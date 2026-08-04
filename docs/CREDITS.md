# Credits and acknowledgments

**agent-dev-toolkit** is original software (MIT). Some behaviors and workflows are **inspired by** third-party projects. We are **not** the same products, do not vendor those repositories wholesale, and do not claim affiliation unless stated by those projects.

## Caveman

Response-compression behavior is **inspired by** [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman).

This toolkit ships a **portable preferences/contract integration** (`core/skills/_shared/caveman/`, policy `caveman-mode`, chat commands `caveman on|off|…`), not a full port of that repository. Optional continuity compaction (`COMPACT.md`) is **not** a port of upstream `caveman-compress`.

User guide: [guides/07-caveman-mode.md](guides/07-caveman-mode.md).

## Impeccable

UI/UX command flow and design guidance draw from **[pbakaus/impeccable](https://github.com/pbakaus/impeccable)** / the Impeccable CLI (`npx impeccable`).

The toolkit skill `impeccable` is a **partial, adapter-synced harness** (subset of references, `DESIGN-BRIEF.md` handoff, toolkit gates). Full upstream install/hooks are optional and require **explicit user consent**. Behavior is not identical to running Impeccable standalone.

## Memory-bank and Spec Kit

The Forma C `memory-bank/` layout and gate policies are a **toolkit-specific durable workspace map** (PowerShell inventory, no Spec Kit toolchain).

Ideas for durable workspace / structured agent memory are **inspired in part by practices around** [github/spec-kit](https://github.com/github/spec-kit). We **do not** apply Spec Kit, `uv`, or `specify` directly — those paths were removed from this toolkit’s MVP in favor of Formas A/B/C. Contracts and scripts under `MEMORY-BANK.md` / `memory-bank-init` are original to agent-dev-toolkit.

## License

Toolkit license: [LICENSE](../LICENSE) (MIT © Raphael Campos). Respect the licenses of any third-party tools you install separately (e.g. Impeccable CLI, Spec Kit).
