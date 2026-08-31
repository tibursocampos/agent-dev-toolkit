# Conventions

- Source identifiers, skill bodies, scripts: **English**
- SDD artifacts (FEATURE/STORY/PRD/PLAN/ANALYSIS/ARCH/SEC, product docs): **same as user chat**; paths/ids English
- Chat with operator: **same as user chat**
- Internal spawn / Task child prompts / agent receipts: **always en-US** (`core/skills/_shared/agents/LANGUAGE.md`)
- Feature artifact paths: `features/NNN-slug/{CHANGE.md,EVD/,STATE.md,TRACE.jsonl}`
- Skill folder names: **kebab-case** only (no Antigravity underscore map)
- SDD state file name: `manifest.json` (do not brand as “v2” in docs)
- Smoke tests must use fixture/`InstallRoot` override — never require live user-profile sync to pass CI
- Do not edit sibling repos `cursor-dev-toolkit` / `antigravity-dev-toolkit` from this project’s delivery
- Magic strings in production scripts: named constants (project Constants / private const)
