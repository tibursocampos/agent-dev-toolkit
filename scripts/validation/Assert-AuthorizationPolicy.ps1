# Requires: PowerShell 5.1+
# Tests:
#   Should_Allow_When_EffectAndScopeAreAuthorized
#   Should_Deny_When_EffectOrScopeIsOutsideAuthorization
#   Should_Deny_When_RequestOrAuthorizationIsInvalid
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\..\core\policy\authorization.ps1')

$authorizations = @(
    [PSCustomObject]@{ Effect = 'file.write'; Scope = 'workspace:alpha' },
    [PSCustomObject]@{ Effect = 'git.commit'; Scope = 'repository:beta' }
)

$allowed = Test-ActionAuthorization -Effect 'file.write' -Scope 'workspace:alpha' -Authorizations $authorizations
if (-not $allowed.Allowed -or $allowed.Reason -ne 'authorized') {
    Write-Error 'Should_Allow_When_EffectAndScopeAreAuthorized: expected an exact authorized pair to pass'
    exit 1
}
Write-Host 'Should_Allow_When_EffectAndScopeAreAuthorized: PASS'

$crossPair = Test-ActionAuthorization -Effect 'file.write' -Scope 'repository:beta' -Authorizations $authorizations
$unknownEffect = Test-ActionAuthorization -Effect 'shell.execute' -Scope 'workspace:alpha' -Authorizations $authorizations
if ($crossPair.Allowed -or $unknownEffect.Allowed) {
    Write-Error 'Should_Deny_When_EffectOrScopeIsOutsideAuthorization: expected unmatched and cross-paired requests to be denied'
    exit 1
}
Write-Host 'Should_Deny_When_EffectOrScopeIsOutsideAuthorization: PASS'

$emptyRequest = Test-ActionAuthorization -Effect '' -Scope 'workspace:alpha' -Authorizations $authorizations
$invalidAuthorization = Test-ActionAuthorization -Effect 'file.write' -Scope 'workspace:alpha' -Authorizations @([PSCustomObject]@{ Effect = 'file.write'; Scope = '' })
if ($emptyRequest.Allowed -or $emptyRequest.Reason -ne 'invalid_request' -or
    $invalidAuthorization.Allowed -or $invalidAuthorization.Reason -ne 'invalid_authorization') {
    Write-Error 'Should_Deny_When_RequestOrAuthorizationIsInvalid: expected invalid input to be denied explicitly'
    exit 1
}
Write-Host 'Should_Deny_When_RequestOrAuthorizationIsInvalid: PASS'

. (Join-Path $PSScriptRoot '..\..\adapters\_shared\GuardCommon.ps1')
$workspace = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-auth-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
try {
    $temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) 'toolkit-allowed.txt'
    $temporary = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = $temporaryPath; content = 'safe' }) -WorkspaceRoot $workspace
    $unknown = Get-ToolkitPathSecretsGuardVerdict -ToolName 'NewProviderTool' -ToolInput ([pscustomobject]@{ payload = 'opaque' }) -WorkspaceRoot $workspace
    $secret = Get-ToolkitPathSecretsGuardVerdict -ToolName 'Write' -ToolInput ([pscustomobject]@{ path = (Join-Path $workspace 'sample.txt'); content = 'api_key = ghp_12345678901234567890' }) -WorkspaceRoot $workspace
    if ($temporary.Decision -ne 'allow' -or $unknown.Decision -ne 'allow') {
        Write-Error 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: paths and tools must not be vetoed by Toolkit classification'
        exit 1
    }
    if ($secret.Decision -ne 'allow' -or $secret.UserMessage -match 'ghp_' -or $secret.AgentMessage -match 'ghp_' -or $secret.SecretType) {
        Write-Error 'Should_NotExposeSecretValue_When_HeuristicPatternMatches: no Toolkit denial or captured value may be emitted'
        exit 1
    }
    Write-Host 'Should_Allow_When_HostOwnsPathAndUnknownToolAuthorization: PASS'
    Write-Host 'Should_NotExposeSecretValue_When_HeuristicPatternMatches: PASS'
}
finally {
    Remove-Item -LiteralPath $workspace -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
