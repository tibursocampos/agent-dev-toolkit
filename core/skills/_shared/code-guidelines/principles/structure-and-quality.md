# Structure and Quality (cross-stack)

Compact normative profile for touched code. Stack overlays add language-specific numbers — do not invent thresholds here.

**Severity:** Blocking when touched code violates defaults (except a documented project escape).

---

## 1. Architecture vs style

| Concern | Rule |
|---------|------|
| **Architecture** | Mirror existing folders, DI registration, and flows |
| **Style** | Apply toolkit defaults on **touched** code — do **not** copy style violations from neighbors |

---

## 2. Source language (comments / docs)

| Situation | Rule |
|-----------|------|
| Touched area already pt-BR | Keep comments/docs in **pt-BR** |
| Touched area already EN | Keep comments/docs in **EN** |
| Greenfield / no clear mirror | **Ask** the user before writing narrative comments/docs |
| User override | User choice wins for that task |
| Identifiers | Always **English** (types, members, params, files) |

---

## 3. File / module structure

| Default | Escape |
|---------|--------|
| One primary public type/module per file | Project already colocates related types in that feature — match local colocation |

---

## 4. Named constants

| Rule | Detail |
|------|--------|
| No magic | No raw strings/numbers with meaning in production paths |
| Local | `const` (or language equivalent) on the owning type when used in one place |
| Shared | Dedicated constants file when reused |
| Large projects | Prefer centralized `*Constants` / `*Messages` / `*LogTemplates` |

---

## 5. Layout (anti-IA)

| Forbidden | Allowed |
|-----------|---------|
| Blank line between every statement | Blank lines **only** between logical member groups |
| Unnecessary double-blank lines | Single blank between groups when needed |

---

## 6. Signatures / calls

Do **not** wrap parameters for style when the language threshold still allows inline. Numeric thresholds live in stack docs (`*-guidelines`).

---

## 7. Readable construction

| Prefer | Avoid |
|--------|-------|
| Named local before a multi-arg `new`/literal when inline harms readability | Mandatory builders for one-off construction |
| Builders only when reuse justifies (KISS) | Over-abstracted construction for a single call site |

---

## 8. Encapsulation

Use language-appropriate privacy for mutable/internal state (e.g. private fields, package/internal visibility). Group related data per [encapsulation.md](./encapsulation.md).

---

## 9. Review severity

| Case | Severity |
|------|----------|
| Touched code violates defaults above | **Blocking** |
| Documented project escape applies | Allowed — do not invent escapes |

---

Stack deltas: load the matching `*-guidelines` overlay after this file — do not duplicate language-specific rules here.

**Version:** 1.0 (agent-dev-toolkit)  
**Used by:** `developer-common/step-0.5`, `developer`, `code-review`
