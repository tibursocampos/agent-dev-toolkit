# GuaranteeRegister

| Field | Value |
|-------|--------|
| **Register id** | `GuaranteeRegister` |
| **Status** | `proposed` |
| **AC** | CA2 |
| **REQ** | REQ-029 |
| **CT** | CT2 |
| **When** | 2026-10-08 |

Registro da história, antes de qualquer teste sair do caminho padrão. Este passo não altera produção, workflow, hook, emissor de TRACE, README, `ToolkitConstants` nem `validate-core`. A suíte larga não foi executada.

Leitura de CT2: para cada teste que este registro autoriza a sair do caminho padrão, a garantia antiga e a checagem que permanece estão nomeadas, ou o risco está declarado inaplicável. Saída sem linha correspondente não fecha REQ-029 (TE01).

## Testes que saem do caminho padrão

| TestId | FormerGuarantee | RemainingCheck | ExitStatus |
|--------|-----------------|----------------|------------|
| `default-wide-suite` | O caminho padrão obriga `scripts/validation/validate-core.ps1`: contratos, grafo, fixtures e smoke harness no repositório, sem sincronizar o perfil do usuário. Hoje isso aparece no menu `ToolkitMenuValidateLine` e `ToolkitMenuValidateCoreLine`, no item de menu Validate core only do README, e nos jobs `validate` e `validate-ubuntu` do workflow de teste. | Para o risco nomeado desta história, a checagem que permanece é o assert já existente desse risco: `scripts/validation/Assert-CiWorkflow.ps1` (contrato estático; não reinicia a suíte), `scripts/validation/Assert-GuardShellCanonicalPaths.ps1` e `scripts/validation/Assert-TraceEmitterFailOpen.ps1`. A suíte larga continua no repositório e só volta ao caminho com risco nomeado e citação explícita deste registro. O risco de executar cada contrato interno em todo caminho padrão não se aplica à mudança cujo risco já tem assert nomeado. | `named_before_exit` |
| `keyed-uninstall-matrix` | O job `validate-windows-keyed-uninstall` publica por adapter e então prova o uninstall com chave: remove artefato do toolkit e preserva arquivo alheio e `sdd/sessions`, em fixture do repositório, sem home real. Scripts da matriz: `Assert-ClaudeKeyedUninstall.ps1`, `Assert-CopilotKeyedUninstall.ps1`, `Assert-CodexKeyedUninstall.ps1`, `Assert-OpenCodeKeyedUninstall.ps1`, `Assert-AntigravityKeyedUninstall.ps1`, `Assert-GrokKeyedUninstall.ps1`, `Assert-CursorKeyedUninstall.ps1`, `Assert-ZcodeKeyedUninstall.ps1`, `Assert-HermesKeyedUninstall.ps1`, `Assert-OpenHandsKeyedUninstall.ps1`. | A mesma garantia de ownership e uninstall fica na fixture pequena `scripts/validation/Assert-PublishOwnershipContracts.ps1` (republicação de catálogo, uninstall de roteador misto, classificação por hash, cobertura de adapter; escrita só sob `scripts/validation/fixtures`). A fuga de caminho no uninstall fica em `scripts/validation/Assert-UninstallPathSafety.ps1`. A matriz de publish completo por adapter é a duplicata que sai do caminho padrão. Os scripts por adapter permanecem no repositório neste passo; o que sai é o job de matriz no workflow. | `named_before_exit` |

## Risco que não se aplica

| TestId | Disposition | Motivo |
|--------|-------------|--------|
| `adapter-smoke-matrix` | `risk_does_not_apply` | Os jobs `validate-windows-adapter-smoke` e `validate-ubuntu-adapter-smoke` permanecem. Retirá-los não é desta história. |
| `allow-user-home-forward` | `risk_does_not_apply` | `scripts/validation/Assert-SyncAllowUserHomeForward.ps1` no job `validate` não é a suíte larga e não sai do caminho padrão neste registro. |
| `docs-strict` | `risk_does_not_apply` | O job `docs-strict` não é a suíte larga. |
| `docs-and-release-workflows` | `risk_does_not_apply` | `.github/workflows/docs.yml`, `.github/workflows/publish-release-bootstrap.yml` e `.github/workflows/enforce-release-source.yml` não invocam a suíte larga e permanecem sem alteração. |
| `req-011-req-026` | `risk_does_not_apply` | REQ-011 e REQ-026 ficam fora desta história. Este registro não reabre esses requisitos nem autoriza a validação deles. |

## Caso negativo

Um teste que deixe o caminho padrão sem `TestId` nesta tabela não fecha REQ-029. A checagem mais barata citada acima é a que permanece; não há produto novo de runtime.
