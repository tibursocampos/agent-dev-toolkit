## Generated region markers

```markdown
<!-- BEGIN GENERATED: inventory-summary -->
…machine content…
<!-- END GENERATED: inventory-summary -->
```

On **refresh** or **refresh-light**:

1. Re-run inventory -> update `.inventory/` under resolved `bank_root`.
2. Replace only content **inside** matching BEGIN/END pairs.
3. Leave human prose outside markers intact.
4. Append one JSON line to `refresh-history.jsonl` (`at`, `action` = `refresh` \| `refresh-light` \| `inventory`, `repo`, `hints`).

**refresh-light** (O3 Step N / manual): same as refresh for inventory + GENERATED + `tech-stack.json`; do not rewrite unmarked human prose sections; prefer `action: refresh-light` in history.

If markers missing in an old file: add markers around the inventory summary block once; do not wipe the whole file.
