#Requires -Version 5.1
# Tests:
#   Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization
#   Should_NotExposeSecretValue_When_HeuristicPatternMatches
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\..\adapters\_shared\GuardCommon.ps1')
$workspace = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-auth-conformance-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
try {
    $outsidePath = Join-Path ([System.IO.Path]::GetTempPath()) 'host-controlled-temp.txt'
    $cases = @(
        (Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = $outsidePath; content = 'safe' }) -WorkspaceRoot $workspace),
        (Get-ToolkitPathSecretsGuardVerdict -ToolName 'NewProviderTool' -ToolInput ([pscustomobject]@{ opaque = $true }) -WorkspaceRoot $workspace),
        (Get-ToolkitPathSecretsGuardVerdict -ToolName 'Shell' -ToolInput ([pscustomobject]@{ command = 'future-shell --unknown-flag' }) -WorkspaceRoot $workspace)
    )
    if (@($cases | Where-Object { $_.Decision -ne 'allow' }).Count -gt 0) {
        throw 'Toolkit shared evaluator vetoed a path or tool classification owned by the host'
    }
    Write-Host 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: PASS'

    $secret = 'ghp_TESTNOTREAL_aaaaabbbbbcccccddddd'
    $secretResult = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = (Join-Path $workspace 'sample.txt'); content = $secret }) -WorkspaceRoot $workspace
    if ($secretResult.Decision -ne 'allow' -or $secretResult.UserMessage -match [regex]::Escape($secret) -or
        $secretResult.AgentMessage -match [regex]::Escape($secret) -or $secretResult.SecretType) {
        throw 'Toolkit shared evaluator must not block or disclose secret-shaped values'
    }
    Write-Host 'Should_NotExposeSecretValue_When_HeuristicPatternMatches: PASS'
}
finally {
    Remove-Item -LiteralPath $workspace -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'Assert-LocalSddWriteConformance: ALL PASS (source-level compatibility evaluator; provider runtime remains host-owned)'
exit 0
