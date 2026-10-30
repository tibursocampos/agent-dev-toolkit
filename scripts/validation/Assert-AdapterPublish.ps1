#Requires -Version 5.1
<#
.SYNOPSIS
  Registry-driven adapter checks. Default: static checks for all adapters plus one real publish,
  layout, keyed-uninstall and (codex hook mode) path/secrets guard run for codex and claude.

.PARAMETER Adapter
  Deeper local run for one registry adapter id (one publish).

.PARAMETER All
  Deeper local run publishing every adapter (slow; not part of validate-core).

.PARAMETER KeepWork
  Keep <repo>/.adt-work/<guid>/ for debugging.
#>
[CmdletBinding()]
param([string] $Adapter = '', [switch] $All, [switch] $KeepWork)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../_lib/AdapterChecks.ps1')
$code = @(Invoke-AdapterChecks -Adapter $Adapter -All:$All -KeepWork:$KeepWork)[-1]
if ($code -eq 0) { Write-Host 'Assert-AdapterPublish: PASS' }
exit $code
