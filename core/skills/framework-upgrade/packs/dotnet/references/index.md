# Dotnet pack — reference index

Routing only. Load **one** section per hop/step — never dump this index plus all sections or the full `_shared/dotnet-guidelines/` tree.

| Section | File | When |
|---------|------|------|
| Plan contract (parametric versions) | `plan-contract.md` | resolve / confirm `currentVersion` → `targetVersion` |
| Compatibility (TFM / SDK) | `compatibility.md` | audit / plan path across majors |
| Validation gates | `validation.md` | `validate` mode or post-hop evidence |
| Knowledge pointers (shared guidelines) | `knowledge-index.md` | audit / validate post-upgrade quality gate (not hop substitute) |

Pack contract (detect, `supported_range`, hops summary): parent `../PACK.md`.

Orchestrator shared refs stay under `framework-upgrade/references/` (modes, evidence, research-protocol, …) — do not duplicate them here.
