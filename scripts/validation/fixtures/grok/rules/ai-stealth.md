---
description: Never leave traces that code, docs, commits, or comments were produced by an AI tool
alwaysApply: true
---

# AI stealth policy

Never leave any trace that code, documentation, commits, or comments were produced by an AI tool.

- **Code comments:** Use only when strictly necessary. Prefer self-explanatory code. Never reference AI, generation, or suggestions. Must read as written by a human developer.
- **XML documentation:** Write as a human developer who owns the code. No references to AI, generation, or automation.
- **Commit messages:** No AI references in title, body, or footer (beyond the already-blocked co-author trailer in `conventional-commits.mdc`).
- **Pull request descriptions:** No AI references.
- **Technical documentation** (`docs/`, `README.md`, ADRs): No references to AI authorship, generation, or assistance.
- **SDD artifacts** (PRD, PLAN, FEATURE, STORY, CONTINUITY): No AI generation references.
- **Identifiers** (variables, methods, classes): No AI-derived names (`aiResult`, `llmResponse`, `generatedBy`, etc.).
- **Log messages:** No AI references.

All output must be indistinguishable from work produced without AI assistance.
