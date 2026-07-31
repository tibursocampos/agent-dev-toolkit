#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor filesystem smoke helpers + Invoke-CursorSmokeValidate (TE01/TE04).
#>

function New-CursorSmokeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Success,

        [Parameter()]
        [string] $Message = '',

        [Parameter()]
        [string] $ErrorCode = '',

        [Parameter()]
        [string] $ResolvedInstallRoot = $null,

        [Parameter()]
        [hashtable] $Checks = $null,

        [Parameter()]
        [string[]] $MissingRelativePaths = @(),

        [Parameter()]
        [int] $ExitCode = 0
    )

    if ($null -eq $Checks) {
        $Checks = @{}
    }

    return [PSCustomObject]@{
        Success              = $Success
        Implemented          = $true
        CommandName          = 'Invoke-SmokeValidate'
        AgentId              = $script:CursorAdapterAgentId
        FilesystemOnly       = $true
        RequiresRuntime      = $false
        RequiresHooksTrustUi = $false
        ErrorCode            = $ErrorCode
        ResolvedInstallRoot  = $ResolvedInstallRoot
        Checks               = [PSCustomObject]$Checks
        MissingRelativePaths = @($MissingRelativePaths)
        Te04Note             = $script:CursorAdapterMessage.SmokeFilesystemOnlyNote
        Message              = $Message
        ExitCode             = $ExitCode
    }
}

function Test-CursorSmokeSkillManifestPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SkillsRoot
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
        return $false
    }

    $manifestName = $script:CursorAdapterConstant.SkillMarkdownFileName
    $skillDirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory -Force -ErrorAction SilentlyContinue
    foreach ($dir in $skillDirs) {
        $manifestPath = Join-Path $dir.FullName $manifestName
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            return $true
        }
    }

    return $false
}

function Test-CursorSmokeRulesMdcPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RulesRoot
    )

    if (-not (Test-Path -LiteralPath $RulesRoot -PathType Container)) {
        return $false
    }

    $destExt = $script:CursorAdapterConstant.PolicyDestExtension
    $ruleFiles = Get-ChildItem -LiteralPath $RulesRoot -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -eq $destExt }

    return (@($ruleFiles).Count -gt 0)
}

function Test-CursorSmokeHookScriptsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksRoot,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    $hooksDir = $script:CursorAdapterConstant.HooksDirectoryName
    if (-not (Test-Path -LiteralPath $HooksRoot -PathType Container)) {
        foreach ($name in $script:CursorAdapterConstant.ManagedHookScriptNames) {
            $MissingRelative.Add(($hooksDir + '/' + $name))
        }
        return $false
    }

    $allPresent = $true
    foreach ($name in $script:CursorAdapterConstant.ManagedHookScriptNames) {
        $path = Join-Path $HooksRoot $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $MissingRelative.Add(($hooksDir + '/' + $name))
            $allPresent = $false
        }
    }

    return $allPresent
}

function Test-CursorSmokeHooksJsonPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $HooksJsonPath,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    $hooksJsonRel = $script:CursorAdapterConstant.HooksJsonFileName
    if (-not (Test-Path -LiteralPath $HooksJsonPath -PathType Leaf)) {
        $MissingRelative.Add($hooksJsonRel)
        return $false
    }

    try {
        $payload = [System.IO.File]::ReadAllText($HooksJsonPath) | ConvertFrom-Json
    }
    catch {
        $MissingRelative.Add(($hooksJsonRel + ' (invalid JSON)'))
        return $false
    }

    if ($null -eq $payload) {
        $MissingRelative.Add(($hooksJsonRel + ' (null JSON)'))
        return $false
    }

    $hooksProp = $script:CursorAdapterConstant.HooksDirectoryName
    if ($null -eq $payload.$hooksProp) {
        $MissingRelative.Add(($hooksJsonRel + '/hooks'))
        return $false
    }

    return $true
}

function Test-CursorSmokeAgentsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgentsPath
    )

    if (-not (Test-Path -LiteralPath $AgentsPath -PathType Leaf)) {
        return $false
    }

    $text = [System.IO.File]::ReadAllText($AgentsPath)
    return -not [string]::IsNullOrWhiteSpace($text)
}

function Test-CursorSmokeSddLayoutPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SddRoot,

        [Parameter()]
        [System.Collections.Generic.List[string]] $MissingRelative
    )

    $sddDir = $script:CursorAdapterConstant.SddDirectoryName
    $sessionsRel = $sddDir + '/' + $script:CursorAdapterConstant.SessionsDirectoryName
    $manifestRel = $sddDir + '/' + $script:CursorAdapterConstant.ManifestFileName
    $complete = $true

    if (-not (Test-Path -LiteralPath $SddRoot -PathType Container)) {
        $MissingRelative.Add($sessionsRel)
        $MissingRelative.Add($manifestRel)
        return $false
    }

    $sessionsPath = Join-Path $SddRoot $script:CursorAdapterConstant.SessionsDirectoryName
    if (-not (Test-Path -LiteralPath $sessionsPath -PathType Container)) {
        $MissingRelative.Add($sessionsRel)
        $complete = $false
    }

    $manifestPath = Join-Path $SddRoot $script:CursorAdapterConstant.ManifestFileName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        $MissingRelative.Add($manifestRel)
        $complete = $false
    }

    return $complete
}

function Invoke-CursorSmokeValidate {
    <#
    .SYNOPSIS
      Run filesystem-only Cursor smoke against a fixture InstallRoot (TE01/TE04).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallRoot,
        [Parameter()]
        [switch] $AllowUserHome
    )

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        throw $script:CursorAdapterMessage.InstallRootRequired
    }

    $resolvedInstallRoot = $null
    try {
        $repoRoot = Get-CursorAdapterRepoRoot
        $resolvedInstallRoot = Resolve-InstallRoot -InstallRoot $InstallRoot -AllowUserHome:$AllowUserHome -RepoRoot $repoRoot
    }
    catch {
        $detail = $_.Exception.Message
        return New-CursorSmokeResult `
            -Success $false `
            -ErrorCode $script:CursorAdapterConstant.SmokeTe01Code `
            -Message ($script:CursorAdapterMessage.SmokeTe01InvalidRoot -f $detail) `
            -ExitCode 1
    }

    $skillsPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SkillsDirectoryName
    $rulesPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.RulesDirectoryName
    $hooksPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksDirectoryName
    $hooksJsonPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.HooksJsonFileName
    $agentsPath = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.AgentsMarkdownFileName
    $sddRoot = Join-Path $resolvedInstallRoot $script:CursorAdapterConstant.SddDirectoryName

    $missing = [System.Collections.Generic.List[string]]::new()
    $checks = [ordered]@{
        SkillsPresent      = $false
        RulesMdcPresent    = $false
        HookScriptsPresent = $false
        HooksJsonPresent   = $false
        AgentsPresent      = $false
        SddLayoutPresent   = $false
        FilesystemOnly     = $true
        RequiresHooksTrustUi = $false
    }

    $skillsOk = Test-CursorSmokeSkillManifestPresent -SkillsRoot $skillsPath
    $checks.SkillsPresent = $skillsOk
    if (-not $skillsOk) {
        $missing.Add(($script:CursorAdapterConstant.SkillsDirectoryName + '/*/' + $script:CursorAdapterConstant.SkillMarkdownFileName))
    }

    $rulesOk = Test-CursorSmokeRulesMdcPresent -RulesRoot $rulesPath
    $checks.RulesMdcPresent = $rulesOk
    if (-not $rulesOk) {
        $missing.Add(($script:CursorAdapterConstant.RulesDirectoryName + '/*' + $script:CursorAdapterConstant.PolicyDestExtension))
    }

    $hooksOk = Test-CursorSmokeHookScriptsPresent -HooksRoot $hooksPath -MissingRelative $missing
    $checks.HookScriptsPresent = $hooksOk

    $hooksJsonOk = Test-CursorSmokeHooksJsonPresent -HooksJsonPath $hooksJsonPath -MissingRelative $missing
    $checks.HooksJsonPresent = $hooksJsonOk

    $agentsOk = Test-CursorSmokeAgentsPresent -AgentsPath $agentsPath
    $checks.AgentsPresent = $agentsOk
    if (-not $agentsOk) {
        $missing.Add($script:CursorAdapterConstant.AgentsMarkdownFileName)
    }

    $sddOk = Test-CursorSmokeSddLayoutPresent -SddRoot $sddRoot -MissingRelative $missing
    $checks.SddLayoutPresent = $sddOk

    if ($missing.Count -gt 0) {
        $listText = ($missing.ToArray() -join ', ')
        return New-CursorSmokeResult `
            -Success $false `
            -ErrorCode $script:CursorAdapterConstant.SmokeTe04Code `
            -ResolvedInstallRoot $resolvedInstallRoot `
            -Checks $checks `
            -MissingRelativePaths $missing.ToArray() `
            -Message ($script:CursorAdapterMessage.SmokeTe04Missing -f $listText) `
            -ExitCode 1
    }

    $passMessage = ($script:CursorAdapterMessage.SmokePassed -f $resolvedInstallRoot) + ' ' + $script:CursorAdapterMessage.SmokeFilesystemOnlyNote
    return New-CursorSmokeResult `
        -Success $true `
        -ResolvedInstallRoot $resolvedInstallRoot `
        -Checks $checks `
        -Message $passMessage `
        -ExitCode 0
}
