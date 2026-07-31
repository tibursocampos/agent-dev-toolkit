# Conventions

- Source identifiers, skill bodies, scripts: **English**
- SDD artifacts (FEATURE/STORY/PRD/PLAN/CONTINUITY): **pt-BR** prose; paths/ids English
- Chat with operator: **pt-BR**
- Skill folder names: **kebab-case** only (no Antigravity underscore map)
- SDD state file name: `manifest.json` (do not brand as “v2” in docs)
- Smoke tests must use fixture/`InstallRoot` override — never require live user-profile sync to pass CI
- Do not edit sibling repos `cursor-dev-toolkit` / `antigravity-dev-toolkit` from this project’s delivery
- Magic strings in production scripts: named constants (project Constants / private const)
