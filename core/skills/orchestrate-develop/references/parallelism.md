## Safe parallelism rules

Parallel O3 is **supported**. Root cause of gate races is fixed by PLAN-scoped (or PLAN+step) develop sessions in `SESSION.md` - not by disabling parallel, not by worktrees.

| Allowed | Not allowed |
|---------|-------------|
| Two ready steps on **different** PLANs with disjoint file scopes + distinct `plan-{hash}.json` + user **sim** | Two children sharing one flat `{repo-hash}.json` for `step_confirmed` / `tests_run` |
| Same PLAN steps marked parallel-safe + disjoint files + `plan-{hash}-step-{N}.json` each | Guessing independence without asking |
| Serial default when unsure; **cap 4** concurrent children (wave if more) | Worktrees / multi-checkout for multi-US (out of MVP) |
| After any `plan-{hash}-step-*.json` exists for a PLAN, keep using PLAN+step for that PLAN | Mixing `plan-{hash}.json` and `plan-{hash}-step-N.json` on the same PLAN |
| Implementation parallelism for disjoint ready steps (with **sim**) | Using O3 / Task parallelism **as the evidence verifier** (**Verifier ≠ O3**) |

Evidence-or-zero (`EVD/` + `STATE.md`, levels `off`\|`cheap`\|`standard`\|`strict`) runs **inside** each `sdd-develop` child via `validate-evidence` — sequential script gate. See `EVD-STATE-CONTRACT.md`.

Living loop TRACE (`converge` → `sync_current` → `archive` at `features/NNN-slug/TRACE.jsonl`) runs at wave close via `validate-trace -RequireArchiveComplete` — also sequential; **not** an O3 parallel verifier. See `TRACE-ARCHIVE-CONTRACT.md`.

Ask before parallel:

```text
Steps {A} e {B} parecem independentes. Executar em paralelo?
(sim / série / cancelar)
```

Each child prompt must include `planPath`, `step`, Prior-context paths (`ARCH|SEC|ANALYSIS` when present), and instruction to use the matching scoped SESSION file.

---

## Process — Safe parallelism (optional)

Default: **serial** - one step in flight (lower context risk).

Parallel Task children **when all** of:

| Condition | Required |
|-----------|----------|
| Distinct PLAN files **or** PLAN explicitly marks steps as independent / parallel-safe | Yes |
| No shared files in step scopes (parent Grep/diff intent) | Yes |
| Deps of each parallel step already complete | Yes |
| User explicitly chose parallel after being asked | Yes |
| **Distinct develop session files** (PLAN-scoped, or PLAN+step when same PLAN) | Yes |

Ask (pt-BR) before any parallel spawn — copy in § Safe parallelism rules.

| Parallel case | Session file per child (`SESSION.md`) |
|---------------|----------------------------------------|
| Different PLANs | `sessions/{repoHash}/plan-{planHash}.json` each |
| Same PLAN, parallel-safe steps | `sessions/{repoHash}/plan-{planHash}-step-{N}.json` each |

Child prompt **must** include: `planPath`, `step`, `memoryBankPath` (read-only), Prior-context paths including `ARCH|SEC|ANALYSIS` when present, and “load develop SESSION scoped per SESSION.md (PLAN or PLAN+step)”.

If unsure about file independence -> **série**. Concurrent parallel Task cap **≤4** per `SPAWN.md` (wave ≤4 or stay serial; do not invent a new cap). No git worktrees multi-US in MVP (RNF04). Parallelism is supported via scoped sessions - do **not** disable parallel as the only safe path. If `subagents=none` or Task unavailable → **fallback** serial handoff to manual `sdd-develop` (never hard-fail).

**Same-PLAN scope rule:** if any `plan-{planHash}-step-*.json` exists for the PLAN, every spawn for that PLAN (including later serial ones) **must** use PLAN+step session files - do not mix with `plan-{planHash}.json`.

See also § Safe parallelism rules.
