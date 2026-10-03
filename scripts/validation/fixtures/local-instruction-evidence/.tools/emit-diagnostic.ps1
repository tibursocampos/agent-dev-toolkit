param([string] $Scope, [string] $SensitiveValue)
if (-not [string]::IsNullOrWhiteSpace($env:FIXTURE_DIAGNOSTIC_MARKER)) {
    Set-Content -LiteralPath $env:FIXTURE_DIAGNOSTIC_MARKER -Value 'invoked' -Force
}
if ($Scope -eq 'long-output') {
    Write-Output ('x' * 9000)
    exit 0
}
Write-Output "src/Widget.cs(12): warning DEMO001 seeded finding for $Scope $SensitiveValue"
exit 1
