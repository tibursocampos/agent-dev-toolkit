---
title: Começar
---

# Começar

Publique o **agent-dev-toolkit** em um ou mais agentes de código e abra o projeto que você quer mudar.

| Caminho | Quando |
|---------|--------|
| **Opção 0 — Bootstrap de release (recomendado)** | Baixe um entrypoint de bootstrap nas GitHub Releases. Ele busca o zip por HTTPS, confere o SHA256, extrai e abre `toolkit.ps1`. Sem clone completo. |
| **Opção 1 (depois do clone)** | Smart Manager interativo: `pwsh -NoProfile -File .\scripts\toolkit.ps1` |
| **Opção 2+** | Sync e verificações não interativos em [CLI](cli.md) |

O repositório é público. Clone e fork à vontade. Contribuições upstream não são aceitas. Veja [Mantenedores](maintainers.md).

## Pré-requisitos

SO suportado: **Windows**, **Linux** (Ubuntu, Debian e derivados) e **macOS**.

| Requisito | Notas |
|-----------|--------|
| **PowerShell** | **Windows:** PowerShell **5.1+** ou **pwsh 7+** (recomendado). **Linux / macOS:** **pwsh 7+** apenas. |
| **Git** | Necessário na opção 1 / 2+ (clone). A opção 0 não exige Git. |
| **Agente alvo** | Pelo menos um de: Cursor, Claude Code, Codex, GitHub Copilot, Antigravity, OpenCode, Grok Build, ZCode ADE, Hermes, OpenHands |
| **Rede (opção 0)** | HTTPS para as GitHub Releases. Usa `curl` (preferido) ou `Invoke-WebRequest`. O bootstrap não usa a CLI `gh`, Node nem um `.exe` compilado. |

## 0. Bootstrap de release

O entrypoint baixa o zip, confere o SHA256 e abre o CLI.

| Sistema | Arquivo | Download |
| --- | --- | --- |
| Windows | `bootstrap.bat` | <a class="file-download" href="https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.bat">bootstrap.bat</a> |
| Windows, Linux e macOS | `bootstrap.ps1` | <a class="file-download" href="https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1">bootstrap.ps1</a> |
| Linux e macOS | `bootstrap.sh` | <a class="file-download" href="https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.sh">bootstrap.sh</a> |

No Windows, execute `bootstrap.bat`. Ele remove a marca de download do navegador em `bootstrap.ps1` e abre o PowerShell com `-ExecutionPolicy Bypass`, preferindo `pwsh` e caindo para o Windows PowerShell. Um clique duplo que falha fica aberto até você pressionar uma tecla. Se `bootstrap.ps1` não estiver ao lado do `.bat`, o `.bat` baixa esse script da mesma URL de Release antes de executá-lo. No Linux e no macOS, coloque `bootstrap.sh` ao lado de `bootstrap.ps1` e marque o arquivo shell como executável antes de rodá-lo.

Checksum inválido sai com código diferente de zero. Não há extração nem handoff.

Publicado por `.github/workflows/publish-release-bootstrap.yml`:

| Artefato | Nome |
|----------|------|
| Zip do toolkit | `agent-dev-toolkit.zip` |
| Sidecar SHA256 | `agent-dev-toolkit.zip.sha256` |
| Entrypoints | `bootstrap.ps1`, `bootstrap.bat`, `bootstrap.sh` |

Sobrescreva owner/repo com `-Owner` / `-Repo` ou `TOOLKIT_RELEASE_OWNER` / `TOOLKIT_RELEASE_REPO`. Sobrescreva nomes de assets com `-ZipAssetName` / `-ChecksumAssetName` ou `TOOLKIT_RELEASE_ZIP_ASSET` / `TOOLKIT_RELEASE_CHECKSUM_ASSET`.

### Flags do bootstrap

| Flag / env | Função |
|------------|--------|
| *(padrão)* | Depois do SHA256 ok, extrai e abre o `toolkit.ps1` interativo |
| `-NoExtract` | Só verifica o checksum |
| `-SkipSync` | Para depois de uma extração bem-sucedida |
| `-DirectSync` | Depois de extrair, chama `sync-agent.ps1` |
| `-SyncWhatIf` | Com `-DirectSync`, encaminha `-WhatIf` para `sync-agent.ps1` |
| `-Agent` / `TOOLKIT_SYNC_AGENT` | Id de agente do registro quando `-DirectSync` (padrão `cursor`) |
| `-InstallRoot` / `-AllowUserHome` / `-Mode` / `-UserScope` | Encaminhados para `sync-agent.ps1` quando `-DirectSync` roda |
| `-ZipAssetName` / `TOOLKIT_RELEASE_ZIP_ASSET` | Sobrescreve o asset do zip (padrão `agent-dev-toolkit.zip`) |
| `-ChecksumAssetName` / `TOOLKIT_RELEASE_CHECKSUM_ASSET` | Sobrescreve o asset do checksum (padrão `agent-dev-toolkit.zip.sha256`) |
| `-ExpectedSha256` | SHA256 hexadecimal (pula o download do checksum) |
| `-LocalZipPath` + `-SkipDownload` | Smoke offline, sem rede |
| `-Extract` | Alias legado sem efeito (a extração fica ligada, salvo `-NoExtract`) |

## 1. Clone (alternativa)

```powershell
git clone https://github.com/tibursocampos/agent-dev-toolkit.git agent-dev-toolkit
cd agent-dev-toolkit
```

## Depois do download

O menu, cada `-Action`, sync, validação e desinstalação estão em [CLI](cli.md).

Abra o repositório da aplicação no agente e siga para [Primeiro uso](first-use.md). O caminho de uma feature é [Entrega orquestrada](orchestrated-delivery.md).

## Solução de problemas

| Sintoma | Causa provável | Correção |
|---------|----------------|----------|
| O sync recusa o InstallRoot | Caminho sob o perfil do usuário sem o opt-in | Acrescente `-AllowUserHome`, ou confirme no assistente |
| Copilot TE02 | `-Mode` ausente ou inválido | Passe `-Mode user` ou `-Mode repo` |
| Skills ausentes na IDE | Só o fixture foi sincronizado, ou o agente precisa reiniciar | Sincronize o **home ao vivo**. Confie nos hooks na UI do agente se ela pedir |
| Uma execução local falha como a CI falharia | O comando esperava escrita no home | Use fixtures ou smokes do Validation lab |

Próximo: [Primeiro uso](first-use.md).
