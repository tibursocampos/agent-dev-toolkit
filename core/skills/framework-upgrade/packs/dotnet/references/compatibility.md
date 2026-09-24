# Dotnet pack — compatibility (TFM / SDK)

## Scope

Parametric checks for moving `currentVersion` → `targetVersion` within pack `supported_range`. Not a dump of Microsoft release notes.

## Inventory before a hop

| Check | Source signals |
|-------|----------------|
| TFM majors | `*.csproj` `<TargetFramework>` / `<TargetFrameworks>`; `Directory.Build.props` |
| SDK pin | `global.json` `sdk.version` / rollForward |
| Central packages | `Directory.Packages.props` / `packages.lock.json` when present |
| Multi-target | List each `netX.Y`; plan per TFM or confirm shared hop |

## Rules

1. Map TFM `net{N}.0` → major `N` unless the project documents a nonstandard alias.
2. Raise SDK major in lockstep with TFM when `global.json` pins an older SDK that cannot build the target TFM.
3. Treat package bumps that are **required** for the target TFM as part of the hop plan; prefer official Microsoft guidance for breaking package renames — do not invent undocumentable majors’ deltas.
4. Out-of-range majors → research protocol; stop inventing local compatibility matrices.

## Local vs official

| Source | Role |
|--------|------|
| This pack + `knowledge-index.md` | Practice / architecture / C# gates after TFM move |
| Learn / .NET release notes (official) | Normative breaking changes per major hop |

Pointers only until a later PLAN step deep-curates official cites.
