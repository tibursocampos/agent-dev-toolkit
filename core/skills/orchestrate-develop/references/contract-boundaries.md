## Contract reuse (RN05)

| Concern | Source of truth |
|---------|-----------------|
| One step per session | `sdd-develop/SKILL.md` |
| PLAN update protocol | `sdd-develop/reference.md` |
| SESSION gates | `SESSION.md` (repo + PLAN-scoped develop) + guardrails |
| Branch rules | `branch-validation.mdc` via sdd-develop |
| Native Task vs **fallback** | `SPAWN.md` (capability `subagents`; never hard-fail) |

O3 **orchestrates invocation**; it does **not** replace those documents. When `subagents=none` or Task unavailable → **fallback** handoff to manual `/sdd-develop` (parent never writes app code).

---

## Boundaries

| Aspect | O2 | O3 | Manual `sdd-develop` |
|--------|----|----|----------------------|
| Writes | PRD/PLAN | CONTINUITY + spawns implementers | Code + PLAN progress |
| App code | No | Children only | Yes (the skill itself) |
| Steps per session | N/A | **One** per child | **One** |
| Required? | After O1 for Orchestrated Delivery | **Optional** | Always valid |

---

## Canonical invoke strings

```text
/orchestrate-develop - <portable-feature-path>
```

```text
/orchestrate-develop - <portable-plan-path>
```

```text
/sdd-develop - <portable-plan-path> - Step N
```

```text
/code-review
/code-review - single
/code-review - multi-angle
```

```text
/orchestrate-deliver - <portable-feature-path>
```
