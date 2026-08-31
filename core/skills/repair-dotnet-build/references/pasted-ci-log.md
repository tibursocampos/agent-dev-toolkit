## Pasted CI log - what to extract

| Signal | Pattern |
|--------|---------|
| Compile error | `error CS`, file path, line number |
| Restore | `restore failed`, `NU1101`, unauthorized feed |
| Test failure | `[FAIL]`, `Failed!`, `Error Message:`, `Expected`, `Actual`, `.cs:line` |
| Docker/other | `exit code`, `exception`, step name from log header |

Ignore stack frames from test frameworks unless they point to product code.

---
