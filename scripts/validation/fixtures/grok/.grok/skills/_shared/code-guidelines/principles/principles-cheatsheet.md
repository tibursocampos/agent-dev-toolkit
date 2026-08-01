# Principles Cheatsheet - Quick Decision Rules

Condensed reference for fundamental principles.  
**For code examples and edge cases:** open the linked files in this folder.

---

## Decision table

| Principle | Trigger | Threshold | Severity | Exceptions |
|-----------|---------|-----------|----------|------------|
| **DRY** | Repeated code block | 3+ identical or very similar occurrences | Suggestion | Generated code, distinct test scenarios, documented intentional duplication |
| **KISS** | Long method | > 50 lines | Suggestion | Handler with clear sequential steps |
| **KISS** | Excessive abstraction | Factory-of-factory, unnecessary builder | Blocking if code is worse | - |
| **KISS** | Many parameters | > 5 parameters in one method | Suggestion | Unrelated parameters |
| **YAGNI** | Dead code | Type/method/variable never referenced | Blocking | - |
| **YAGNI** | Speculative feature | Field/method without current requirement | Blocking | - |
| **Encapsulation** | Related parameters | 4+ parameters (e.g. address fields) | Suggestion | Unrelated types |
| **Encapsulation** | Over-broad variable scope | Loop variable used only inside loop | Suggestion | - |

---

## General rules

- **Isolated KISS** is usually suggestion only - unless the change actively worsens readability.
- **YAGNI dead code** is blocking: remove it, do not comment it out.
- **Do not flag generated code:** migrations, scaffolded DTOs, etc.
- **DRY minimum:** 2 occurrences -> no comment; threshold starts at 3.

---

## Architecture (A/B)

| Concern | Where |
|---------|--------|
| **When / which style** | [architecture-selection.md](./architecture-selection.md) — brownfield mirror; greenfield propose + confirm; handoff to one B style + C overlay |
| **What (one style only)** | [architecture/](./architecture/) — load **one** primary file; never glob `architecture/**` |

---

## Full references

| File | Content |
|------|---------|
| [DRY.md](./DRY.md) | Duplication: blocks, mappings, validation |
| [KISS.md](./KISS.md) | Complexity: abstractions, long methods, over-engineering |
| [YAGNI.md](./YAGNI.md) | Dead code: types, variables, unused parameters |
| [encapsulation.md](./encapsulation.md) | Grouping: parameters, scope, object behavior |
| [SOLID.md](./SOLID.md) | Overview: SRP, OCP, LSP, ISP, DIP + links |
| [architecture-selection.md](./architecture-selection.md) | Layer A: style decision table + confirm gate |
| [architecture/README.md](./architecture/README.md) | Layer B index + one-style token rule |

---

**Version:** 1.1 (agent-dev-toolkit)  
**Used by:** `developer-common/step-0.5`, `developer`, `code-review`
