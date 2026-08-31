## Filename and numbering

| Part | Rule |
|------|------|
| Folder | From manifest: `features/NNN-slug/USnn/PRD/` (Classic SDD default `US01`) or global under `<classic.path>/features/...` |
| Sequence | Next `NNN` (3 digits) after listing PRDs under `features/**/PRD/` only (workspace + global feature root for `<repo-id>`) |
| Slug | Short ASCII summary (kebab-case or snake_case; Portuguese words allowed) |
| Example (repo) | `features/002-exportacao-perfil/US01/PRD/002_exportacao_perfil_usuario.md` |
| Example (global) | `sdd/acme-payments-api/features/002-exportacao-perfil/US01/PRD/002_exportacao_perfil_usuario.md` (portable path relative to InstallRoot) |
