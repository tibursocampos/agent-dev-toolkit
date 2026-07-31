#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for Copilot Publish-Policy (core policy/router -> Copilot instructions).

.DESCRIPTION
  Mapping (Mode user|repo; relative paths identical under InstallRoot):
  - core/policy/{name}.md -> InstallRoot/instructions/{name}.instructions.md (no Cursor .mdc)
  - core/router/AGENTS.md -> InstallRoot/copilot-instructions.md
  Mode user: InstallRoot models ~/.copilot. Mode repo: InstallRoot models .github.
  Placeholders resolved after copy. Re-publish overwrites managed files; does not delete aliens.
  Smoke is filesystem-only - Copilot IDE extension is out of scope.
  Mode repo must target a fixture InstallRoot - never the toolkit working-tree .github by default.
#>

function Convert-CopilotRouterMdcReferencesToInstructions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $mdcExtension = $script:CopilotPathConstant.CursorRuleExtension
    $instructionsExtension = $script:CopilotPathConstant.InstructionsFileExtension
    if ([string]::IsNullOrEmpty($mdcExtension) -or [string]::IsNullOrEmpty($instructionsExtension)) {
        return $Text
    }

    return $Text.Replace($mdcExtension, $instructionsExtension)
}

function Get-CopilotInstructionsDestinationName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceFileName
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFileName)
    return ($baseName + $script:CopilotPathConstant.InstructionsFileExtension)
}

function Copy-CopilotCorePolicyAsInstructions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePolicyRoot,

        [Parameter(Mandatory = $true)]
        [string] $DestinationInstructionsRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationInstructionsRoot)) {
        New-Item -ItemType Directory -Path $DestinationInstructionsRoot -Force | Out-Null
    }

    $filesCopied = 0
    $sourceExt = $script:CopilotPathConstant.PolicySourceExtension
    $sourceFiles = Get-ChildItem -LiteralPath $SourcePolicyRoot -File -Filter ('*{0}' -f $sourceExt)
    foreach ($file in $sourceFiles) {
        $destinationName = Get-CopilotInstructionsDestinationName -SourceFileName $file.Name
        $destinationPath = Join-Path $DestinationInstructionsRoot $destinationName
        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
        $filesCopied++
    }

    return $filesCopied
}

function Publish-CopilotRouterAsInstructionsFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceRouterFile,

        [Parameter(Mandatory = $true)]
        [string] $DestinationInstructionsFile,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $PlaceholderMap
    )

    $destinationDir = Split-Path -Parent $DestinationInstructionsFile
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    $raw = [System.IO.File]::ReadAllText($SourceRouterFile)
    $updated = Convert-CopilotRouterMdcReferencesToInstructions -Text $raw
    foreach ($key in $PlaceholderMap.Keys) {
        if ($updated.Contains([string]$key)) {
            $updated = $updated.Replace([string]$key, [string]$PlaceholderMap[$key])
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($DestinationInstructionsFile, $updated, $utf8NoBom)
}

function Invoke-CopilotPublishPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,

        [Parameter()]
        [string] $Mode,

        [Parameter()]
        [switch] $AllowUserHome,

        [Parameter()]
        [switch] $WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CopilotPublishMessage.InstallRootRequired
    }

    $normalizedMode = Get-CopilotPublishNormalizedMode -Mode $Mode

    $repoRoot = Get-CopilotPublishAdapterRepoRoot
    $libDir = Join-Path $repoRoot 'scripts\_lib'
    . (Join-Path $libDir 'Resolve-InstallRoot.ps1')

    $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $sourcePolicyRoot = Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.PolicyDirectoryName
    $sourceRouterFile = Join-Path (
        Join-Path (Join-Path $repoRoot $script:CopilotPathConstant.CoreDirectoryName) $script:CopilotPathConstant.RouterDirectoryName
    ) $script:CopilotPathConstant.RouterSourceFileName
    $destinationInstructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    $destinationInstructionsFile = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName

    if (-not (Test-Path -LiteralPath $sourcePolicyRoot)) {
        throw ($script:CopilotPublishMessage.CorePolicyMissing -f $sourcePolicyRoot)
    }
    if (-not (Test-Path -LiteralPath $sourceRouterFile)) {
        throw ($script:CopilotPublishMessage.CoreRouterMissing -f $sourceRouterFile)
    }

    if ($WhatIf.IsPresent) {
        return [PSCustomObject]@{
            Success                    = $true
            Implemented                = $true
            CommandName                = 'Publish-Policy'
            WhatIf                     = $true
            Mode                       = $normalizedMode
            InstallRoot                = $resolvedInstallRoot
            InstructionsRoot           = $destinationInstructionsRoot
            CopilotInstructionsPath    = $destinationInstructionsFile
            SourceRoot                 = $sourcePolicyRoot
            RouterSourcePath           = $sourceRouterFile
            FilesCopied                = 0
            Message                    = ($script:CopilotPublishMessage.PolicyWhatIfOk -f $destinationInstructionsRoot, $normalizedMode)
            ExitCode                   = 0
            SmokeFilesystemOnlyNote    = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
        }
    }

    $resolvedInstallRoot = Initialize-InstallRootForWrite -InstallRoot $resolvedInstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    $destinationInstructionsRoot = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.InstructionsDirectoryName
    $destinationInstructionsFile = Join-Path $resolvedInstallRoot $script:CopilotPathConstant.CopilotInstructionsFileName

    $filesCopied = Copy-CopilotCorePolicyAsInstructions -SourcePolicyRoot $sourcePolicyRoot -DestinationInstructionsRoot $destinationInstructionsRoot
    $placeholderMap = Get-CopilotPlaceholderMap -InstallRoot $resolvedInstallRoot
    Resolve-CopilotPlaceholdersInTree -RootPath $destinationInstructionsRoot -PlaceholderMap $placeholderMap
    Assert-CopilotPlaceholdersResolved -RootPath $destinationInstructionsRoot

    Publish-CopilotRouterAsInstructionsFile -SourceRouterFile $sourceRouterFile -DestinationInstructionsFile $destinationInstructionsFile -PlaceholderMap $placeholderMap
    $filesCopied++

    $placeholders = @(
        $script:CopilotPathConstant.PlaceholderToolkitRoot,
        $script:CopilotPathConstant.PlaceholderSddRoot,
        $script:CopilotPathConstant.PlaceholderGuardrailsPath
    )
    $instructionsText = [System.IO.File]::ReadAllText($destinationInstructionsFile)
    foreach ($placeholder in $placeholders) {
        if ($instructionsText.Contains($placeholder)) {
            throw ($script:CopilotPublishMessage.PlaceholderUnresolved -f $placeholder, $destinationInstructionsFile)
        }
    }

    return [PSCustomObject]@{
        Success                    = $true
        Implemented                = $true
        CommandName                = 'Publish-Policy'
        WhatIf                     = $false
        Mode                       = $normalizedMode
        InstallRoot                = $resolvedInstallRoot
        InstructionsRoot           = $destinationInstructionsRoot
        CopilotInstructionsPath    = $destinationInstructionsFile
        SourceRoot                 = $sourcePolicyRoot
        RouterSourcePath           = $sourceRouterFile
        FilesCopied                = $filesCopied
        Message                    = ($script:CopilotPublishMessage.PolicyPublishedOk -f $filesCopied, $destinationInstructionsRoot, $normalizedMode)
        ExitCode                   = 0
        SmokeFilesystemOnlyNote    = $script:CopilotPathConstant.SmokeFilesystemOnlyNote
    }
}
