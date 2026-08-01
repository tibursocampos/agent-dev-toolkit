# Core SDD contracts

Portable SDD references for adapters and validation. Skills may keep install-time copies under `_shared/sdd-artifacts`; **this tree is the canonical core surface** adapters resolve via `Get-SddRoot`.

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
| `MEMORY-BANK.md` | Forma C Step 0 / Step N bank gate |

## Adapter note (`Get-SddRoot`)

Future adapters implement `Get-SddRoot` to return the **published** SDD contracts root for that agent. Source of truth for publish is this folder (`core/sdd/`). Do not hardcode a single IDE path (`{{TOOLKIT_ROOT}}/...`) in product content.
