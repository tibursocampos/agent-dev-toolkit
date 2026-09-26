# Core SDD contracts

Portable SDD references. Skills keep a published copy under `_shared/sdd-artifacts`. **This folder is the canonical set.** Publish resolves it with `Get-SddRoot`. These contracts do not name a host.

## Public constants

| Constant | Value | Notes |
|----------|-------|-------|
| `ManifestFileName` | `manifest.json` | Public SDD state file name (RN04). No “v2” branding. |
| `SddContractsRoot` | `core/sdd/` | Repo-relative path to these contracts |
| `ContractFiles` | `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md` | Required contract set |

`schema_version` inside `manifest.json` is a numeric field (currently `2`). It is **not** part of the public file name.

## Contracts

| File | Role |
|------|------|
| `PIPELINE.md` | Spec / plan / develop order, canonical paths, confirmation gates |
| `STORAGE.md` | Storage modes, feature tree, manifest resolution |
| `SESSION.md` | Repo vs develop session files and gates |
| `MEMORY-BANK.md` | Orchestrated Delivery Step 0 / Step N bank gate |

## Publish (`Get-SddRoot`)

`Get-SddRoot` returns the published SDD contracts root for the current install. Source of truth is this folder (`core/sdd/`). Do not hardcode an install path (`{{TOOLKIT_ROOT}}/...`) in product content. The contracts do not list hosts.
