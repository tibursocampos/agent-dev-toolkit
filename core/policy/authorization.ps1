# The shared adapter guard owns the executable effect/scope contract so every
# published hook and the policy tests exercise the same implementation.
$guardCommon = Join-Path $PSScriptRoot '..\..\adapters\_shared\GuardCommon.ps1'
. (Resolve-Path -LiteralPath $guardCommon).Path
