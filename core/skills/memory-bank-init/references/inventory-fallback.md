## Manual inventory fallback (no script)

If `Invoke-MemoryBankInventory.ps1` is unreachable:

1. Glob lockfiles / manifests listed in `MEMORY-BANK.md` stale section. Reject any candidate path containing `..` or resolving outside `$Cwd` (`path_escape` → `not-ready`).
2. Write `sources.json` with per-file `path`, `last_write_utc`, `length`, `hash` (SHA256), and `summary` (first heading or first non-empty line).
3. Add governance fields: `status` (`ready` \| `not-ready`), `status_reason`, `inventory_hash` (SHA256 over sorted `path:hash` lines), `inventory_summary` (`N source(s); stack: …`).
4. Set `not-ready` when: no sources, path escape, or incomplete hash; otherwise `ready`.
5. When an existing `sources.json` is present, re-scan its `sources` paths plus default discovery patterns (do not drop curated paths; do not follow `..`).
6. Write `gaps.md` with MVP checklist + phase-2 hints (openapi / migrations / package.json -> ui); preserve any line containing `BLOCKING:`.
7. Append `refresh-history.jsonl`.
8. Surface `status` / `status_reason` / `inventory_hash` / `inventory_summary` in the skill report (same as script path).

When the script **is** present (create / refresh / refresh-light):

```powershell
.\scripts\inventory\Invoke-MemoryBankInventory.ps1 -RepoPath "<consumer>" -BankPath "<bank_root>" -AllowCreateInventory -Action refresh
```

Use `-Action refresh-light` for O3 Step N runs; default `inventory` for create-only scans. Treat exit `2` as `not-ready` (read reason from `sources.json`); exit `0` as `ready`.

Still **write only** under `<bank_root>/.inventory/` (resolved via `STORAGE.md`).
