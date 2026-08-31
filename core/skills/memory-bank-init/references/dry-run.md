## Dry-run mental tests (CA5)

| Situation | Expected |
|-----------|----------|
| No `memory-bank/` + policy auto | create after confirm at resolved `bank_root` |
| Healthy bank, fresh inventory | skip write; status `fresh` |
| Lockfile newer than `sources.json` | stale -> refresh after confirm |
| Global storage | `bank_root` = `<classic.path>/memory-bank/`; no `.gitignore` edit |
| O3 code changed | Step N -> `refresh-light` after confirm |
| Prior/cited has DDL/OpenAPI/UI map | Write matching phase 2 file (BLOCKING) or `- [ ] BLOCKING:` until written |
| Inventory script | does not touch files outside `<bank_root>/.inventory/` (and skill may create sibling bank markdown) |
