# Mantenedores

Notas para operadores e colaboradores que mantêm o **agent-dev-toolkit** saudável. Clone e fork públicos são bem-vindos para uso e customização local; o fluxo de contribuição via PR da comunidade no repositório upstream não é o canal previsto hoje.

## Política (resumo)

| Regra | Detalhe |
|------|--------|
| Clone / fork | Qualquer pessoa pode clonar ou fazer fork e adaptar localmente |
| PRs no upstream | Não fazem parte do fluxo atual de contribuição da comunidade; priorize customizações no seu fork |
| Issues | Apenas bugs (sem canal de feature/RFC) |
| Segurança | Reporte via `SECURITY.md`, não em Issues públicas |

Leituras aprofundadas no GitHub:

- [CONTRIBUTING.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/CONTRIBUTING.md)
- [docs/REPO_GOVERNANCE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/REPO_GOVERNANCE.md)
- [SECURITY.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/SECURITY.md)
- [docs/ARCHITECTURE.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/ARCHITECTURE.md) — layout completo; visão no site: [Arquitetura](../architecture/)

## Validação (local)

Nenhum destes passos escreve na home live de um agente. Prefira caminhos de fixture em `InstallRoot`; nunca use `-AllowUserHome` para “fazer o CI passar”.

**Suíte core** (contratos, grafo de skills, fixtures — obrigatória antes do merge para mantenedores):

```powershell
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1

# Alias:
pwsh -NoProfile -File .\scripts\validation\validate-all.ps1

# Quiet (CI-style):
pwsh -NoProfile -File .\scripts\validation\validate-core.ps1 -Quiet
```

**Validate por agente** (`validate-core` + smoke do adapter contra fixture):

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent claude
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent copilot -Mode user
```

**Harnesses de smoke de CI** (espelham o comportamento de cópia efêmera do Actions):

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-CursorCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-AntigravityCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ClaudeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CodexCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-CopilotCiSmokeSuite.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-OpenCodeCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-GrokCiSmoke.ps1
pwsh -NoProfile -File .\scripts\validation\Invoke-ZCodeCiSmoke.ps1
```

Matriz completa, regras de segurança e workflows de CI:

- [docs/VALIDATION.md](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/docs/VALIDATION.md)
- [validate-toolkit.yml](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/.github/workflows/validate-toolkit.yml) — check obrigatório **validate**
- [docs.yml](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/.github/workflows/docs.yml) — build MkDocs / deploy Pages

## Fluxo Git dos mantenedores

Colaboradores com write access usam branches normais: `feature/<slug>` → `develop` → `master`/`main`. Prefira `/open-github-pr` após `/commit` / `/push` (feature → `develop`; modo release `develop` → `master`/`main`). PRs de release usam o template em `.github/PULL_REQUEST_TEMPLATE/release.md`. Check de CI obrigatório: **validate**. Ver [Maintainers only (repository owner)](https://github.com/tibursocampos/agent-dev-toolkit/blob/master/CONTRIBUTING.md#maintainers-only-repository-owner) em CONTRIBUTING.md.
