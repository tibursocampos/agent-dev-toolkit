## Manual inventory fallback (no script)

If `Invoke-MemoryBankInventory.ps1` is unreachable:

1. Glob lockfiles / manifests listed in `MEMORY-BANK.md` stale section.
2. Write `sources.json` with `path`, `last_write_utc`, `length`, `hash` (SHA256), and `summary` (first heading or first non-empty line) per file.
3. When an existing `sources.json` is present, re-scan its `sources` paths plus default discovery patterns (do not drop curated paths).
4. Write `gaps.md` with MVP checklist + phase-2 hints (openapi / migrations / package.json -> ui); preserve any line containing `BLOCKING:`.
5. Append `refresh-history.jsonl`.

When the script **is** present (create / refresh / refresh-light):

```powershell
.\scripts\inventory\Invoke-MemoryBankInventory.ps1 -RepoPath "<consumer>" -BankPath "<bank_root>" -AllowCreateInventory -Action refresh
```

Use `-Action refresh-light` for O3 Step N runs; default `inventory` for create-only scans.

Still **write only** under `<bank_root>/.inventory/` (resolved via `STORAGE.md`).
