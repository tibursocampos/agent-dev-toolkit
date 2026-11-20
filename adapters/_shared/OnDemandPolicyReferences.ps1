#Requires -Version 5.1
# Skill references for adapters without a native policy tree. These use the same
# policy sources as other hosts and are read only when the skill requests them.
function Get-ToolkitOnDemandPolicyNames {
    return @('ai-stealth', 'branch-validation', 'conventional-commits', 'sdd-artifact-language-pt-br')
}

function Get-ToolkitOnDemandPolicyReferenceMap {
    param([Parameter(Mandatory = $true)][string] $ToolkitRoot)

    $map = [ordered]@{}
    foreach ($name in (Get-ToolkitOnDemandPolicyNames)) {
        $map['{{TOOLKIT_ROOT}}/rules/' + $name + '.mdc'] = "$ToolkitRoot/skills/_shared/policy/$name.md"
    }
    return $map
}

function Publish-ToolkitOnDemandPolicyReferences {
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][string] $InstallRoot,
        [Parameter(Mandatory = $true)][string] $DestinationSkillsRoot,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary] $PlaceholderMap
    )

    $stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('adt-policy-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stageRoot | Out-Null
    $stagedFiles = New-Object 'System.Collections.Generic.List[string]'
    try {
        $sourceRoot = Join-Path $RepoRoot 'core/policy'
        $encoding = New-Object System.Text.UTF8Encoding $false
        foreach ($name in (Get-ToolkitOnDemandPolicyNames)) {
            $text = [System.IO.File]::ReadAllText((Join-Path $sourceRoot "$name.md"))
            foreach ($key in $PlaceholderMap.Keys) {
                $text = $text.Replace([string]$key, [string]$PlaceholderMap[$key])
            }
            $text = Convert-MdcReferencesToMd -Text $text -SourceExtension '.mdc' -TargetExtension '.md'
            $stageFile = Join-Path $stageRoot "$name.md"
            $stagedFiles.Add($stageFile)
            [System.IO.File]::WriteAllText($stageFile, $text, $encoding)
        }
        $destination = Join-Path $DestinationSkillsRoot '_shared/policy'
        $null = Copy-ToolkitManagedTree -SourceRoot $stageRoot -DestinationRoot $destination -InstallRoot $InstallRoot
    }
    finally {
        foreach ($stageFile in $stagedFiles) {
            [System.IO.File]::Delete($stageFile)
        }
        [System.IO.Directory]::Delete($stageRoot)
    }
}
