# Structure and Quality (cross-stack)

Compact normative profile for touched code. Stack overlays add language-specific numbers — do not invent thresholds here.

**Severity:** Blocking when new code ignores the chosen bar, or when existing members are restyled without an explicit yes. Pre-existing project style left in place is allowed.

---

## 1. Architecture vs style

An explicit operator instruction for the current task outranks this style bar. An order to keep the project pattern is closed: match that pattern. Adding or changing one member does not authorize rewriting the rest of the type (attributes, signatures, comments, or existing literals).

| Concern | Rule |
|---------|------|
| **Architecture** | Mirror existing folders, DI registration, and flows |
| **Established project style** | Match the style already used by the touched type and its neighbors in the same layer |
| **Toolkit style** | Default only for new code where that area has no local pattern, or after the operator explicitly chooses the toolkit for this change |
| **Divergence** | When the project style differs from the toolkit bar, record the difference in the PLAN. When there is no PLAN, ask before the edit. Ask whether to follow the project or the toolkit. Silence is not approval. Do not rewrite the class while waiting |

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
| New code | No raw strings/numbers with meaning when the operator chose the toolkit, or when the area has no local pattern |
| Existing members | Leave existing literals in place until the operator approves extracting them |
| Same type | A new constant does not require extracting every existing literal in that type |
| Local | `const` (or language equivalent) on the owning type when a new constant is approved and used in one place |
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
| Restyling existing members without an explicit yes | **Blocking** |
| New code that follows neither the established project style nor an approved toolkit choice | **Blocking** |
| Pre-existing project style left in place | Allowed — including while the project-vs-toolkit question is still open |
| Documented project escape applies | Allowed — do not invent escapes |

---

Stack deltas: load the matching `*-guidelines` overlay after this file — do not duplicate language-specific rules here. Framework-upgrade normative vs auxiliary URLs: `skills/framework-upgrade/references/sources-catalog.md` (RN08: official wins auxiliary).

**Version:** 1.1 (agent-dev-toolkit)  
**Used by:** `developer-common/step-0.5`, `developer`, `code-review`, `framework-upgrade` (quality gate pointers)
