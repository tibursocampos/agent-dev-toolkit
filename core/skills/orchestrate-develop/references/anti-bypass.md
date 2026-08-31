## Anti-bypass checklist (CA5) - copy into enforcement

Use before every spawn and before marking any step done.

| # | Rule | Violates if |
|---|------|-------------|
| 1 | Parent writes **no** app/test source | Parent `Write`/`Edit` on `*.cs`, `*.tsx`, migrations, etc. |
| 2 | One Task = **one** PLAN step | Child prompt lists Steps N and N+1 |
| 3 | Child follows full `sdd-develop` contract | “Quick implement without gates/tests” |
| 4 | Tests before complete | PLAN marked done with failing/skipped tests |
| 5 | User **sim** before next spawn | Auto-chain N steps after one **sim** |
| 6 | Silence ≠ approval | Proceeding without explicit **sim** |
| 7 | Manual `sdd-develop` always allowed | Skill claims O3 is mandatory |
| 8 | No contract fork | Parallel undocumented “O3 implement” process |
| 9 | No `*-developer` from parent for PLAN steps | Parent implements via stack skill instead of child sdd-develop |
| 10 | CONTINUITY only in parent after child | Parent pastes full diffs as “implementation” |

Any violation -> **STOP**, fix process, do not mark step complete.
