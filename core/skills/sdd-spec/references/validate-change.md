## Brownfield CHANGE (`validate-change`)

When FEATURE **Nature** is **brownfield**, also Write `features/NNN-slug/CHANGE.md` (ADDED \| MODIFIED \| REMOVED vs **current** `memory-bank/` docs) and run:

```
.\scripts\validation\validate-change.ps1 -Path <features/NNN-slug/CHANGE.md>
```

**Greenfield** must **not** force an empty CHANGE stub. Contract: `CHANGE-CONTRACT.md`. Smoke: `Assert-ChangeContract.ps1`.
