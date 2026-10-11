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
exit 0
