#Requires -Version 7.0

function Get-DeliveryInputErrorCodes {
    return @(
        'alias_catalog_missing',
        'alias_catalog_invalid',
        'alias_unknown',
        'source_kind_invalid',
        'source_path_invalid',
        'source_escapes_root',
        'source_reparse_point',
        'source_missing',
        'source_unreadable',
        'source_too_large',
        'source_changed_during_read',
        'fileset_invalid',
        'fileset_collision',
        'revision_invalid',
        'revision_unavailable',
        'git_unavailable'
    )
}

function Stop-DeliveryInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Code,
        [Parameter(Mandatory = $true)][string] $Detail
    )

    throw ('{0}: {1}' -f $Code, $Detail)
}

function Get-DeliveryInputMaxFileBytes {
    return [int64]52428800
}

function Get-DeliveryInputSha256Hex {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]] $Bytes
    )

    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($Bytes))
}

function Test-DeliveryInputObject {
    param([AllowNull()][object] $Value)

    return (($Value -is [pscustomobject]) -or ($Value -is [System.Collections.IDictionary]))
}

function Get-DeliveryInputMemberNames {
    param([AllowNull()][object] $Object)

    if ($null -eq $Object) { return @() }
    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys | ForEach-Object { [string]$_ })
    }
    return @($Object.PSObject.Properties | ForEach-Object { [string]$_.Name })
}

function Get-DeliveryInputMember {
    param(
        [AllowNull()][object] $Object,
        [Parameter(Mandatory = $true)][string] $Name
    )

    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in $Object.Keys) {
            if ([string]$key -ceq $Name) { return [pscustomobject]@{ Value = $Object[$key] } }
        }
        return $null
    }
    foreach ($property in $Object.PSObject.Properties) {
        if ($property.Name -ceq $Name) { return [pscustomobject]@{ Value = $property.Value } }
    }
    return $null
}

function Assert-DeliveryInputKeys {
    param(
        [AllowNull()][object] $Object,
        [Parameter(Mandatory = $true)][string[]] $Required,
        [Parameter(Mandatory = $true)][string] $Code,
        [Parameter(Mandatory = $true)][string] $Context,
        [string[]] $Optional = @()
    )

    if (-not (Test-DeliveryInputObject -Value $Object)) { Stop-DeliveryInput -Code $Code -Detail ('{0} must be an object' -f $Context) }
    $names = @(Get-DeliveryInputMemberNames -Object $Object)
    $allowed = @($Required + $Optional)
    foreach ($name in $names) {
        if (-not ($allowed -ccontains $name)) { Stop-DeliveryInput -Code $Code -Detail ('{0} has an unknown key' -f $Context) }
    }
    foreach ($name in $Required) {
        if (-not ($names -ccontains $name)) { Stop-DeliveryInput -Code $Code -Detail ('{0} is missing key {1}' -f $Context, $name) }
    }
}

function Get-DeliveryInputRootFull {
    param([Parameter(Mandatory = $true)][string] $Path)

    $separators = [char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd($separators)
    if ($full.EndsWith(':')) { $full += [System.IO.Path]::DirectorySeparatorChar }
    return $full
}

function Test-DeliveryInputReparse {
    param([Parameter(Mandatory = $true)][string] $Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return (($null -ne $item) -and (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0))
}

function Assert-DeliveryInputRelativeSyntax {
    param([AllowNull()][AllowEmptyString()][string] $Relative)

    if ([string]::IsNullOrEmpty($Relative)) { return }
    if ($Relative.Contains([char]'\')) { Stop-DeliveryInput -Code source_path_invalid -Detail 'backslash separators are not allowed; use forward slashes' }
    if ($Relative.Contains(':')) { Stop-DeliveryInput -Code source_path_invalid -Detail 'drive or colon forms are not allowed' }
    if ($Relative -cmatch '[\x00-\x1F<>"|?*]') { Stop-DeliveryInput -Code source_path_invalid -Detail 'path contains a forbidden character' }
    if ($Relative.StartsWith('/') -or $Relative.EndsWith('/')) { Stop-DeliveryInput -Code source_path_invalid -Detail 'path must be relative without leading or trailing slash' }
    foreach ($segment in $Relative.Split('/')) {
        if (($segment -ceq '') -or ($segment -ceq '.') -or ($segment -ceq '..')) {
            Stop-DeliveryInput -Code source_path_invalid -Detail 'path contains an empty, current or parent segment'
        }
    }
}

function Resolve-DeliveryContainedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $Relative
    )

    Assert-DeliveryInputRelativeSyntax -Relative $Relative
    $rootFull = Get-DeliveryInputRootFull -Path $Root
    $full = $rootFull
    if ($Relative.Length -gt 0) {
        $native = $Relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $native))
    }
    $prefix = $rootFull
    if (-not $prefix.EndsWith([System.IO.Path]::DirectorySeparatorChar)) { $prefix += [System.IO.Path]::DirectorySeparatorChar }
    if (-not ($full.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase))) {
        Stop-DeliveryInput -Code source_escapes_root -Detail 'path resolves outside its root'
    }

    if (Test-DeliveryInputReparse -Path $rootFull) { Stop-DeliveryInput -Code source_reparse_point -Detail 'root is a reparse point' }
    if ($Relative.Length -gt 0) {
        $cursor = $rootFull
        foreach ($segment in $Relative.Split('/')) {
            $cursor = [System.IO.Path]::Combine($cursor, $segment)
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
            if ($null -eq $item) { break }
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                Stop-DeliveryInput -Code source_reparse_point -Detail 'path crosses a junction or symbolic link'
            }
        }
    }

    return [pscustomobject]@{ Root = $rootFull; Relative = $Relative; Full = $full }
}

function Read-DeliveryAliasCatalog {
    [CmdletBinding()]
    param(
        [AllowNull()][AllowEmptyString()][string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { Stop-DeliveryInput -Code alias_catalog_missing -Detail 'no alias catalog path was given' }
    try {
        $catalogFull = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        Stop-DeliveryInput -Code alias_catalog_missing -Detail 'alias catalog path is not valid'
    }
    if (-not (Test-Path -LiteralPath $catalogFull -PathType Leaf)) { Stop-DeliveryInput -Code alias_catalog_missing -Detail 'alias catalog file does not exist' }

    try {
        $text = [System.IO.File]::ReadAllText($catalogFull, [System.Text.UTF8Encoding]::new($false))
    }
    catch {
        Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'alias catalog cannot be read'
    }
    if ([string]::IsNullOrWhiteSpace($text)) { Stop-DeliveryInput -Code alias_catalog_missing -Detail 'alias catalog file is empty' }

    try {
        $document = ConvertFrom-Json -InputObject $text -ErrorAction Stop
    }
    catch {
        Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'alias catalog is not valid JSON'
    }
    if ($document -isnot [pscustomobject]) { Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'alias catalog must be a JSON object' }
    Assert-DeliveryInputKeys -Object $document -Required @('schema', 'aliases') -Code alias_catalog_invalid -Context 'alias catalog'

    $schema = (Get-DeliveryInputMember -Object $document -Name 'schema').Value
    if (($schema -isnot [string]) -or ($schema -cne 'delivery-input-aliases/v1')) {
        Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'alias catalog schema must be delivery-input-aliases/v1'
    }
    $aliases = (Get-DeliveryInputMember -Object $document -Name 'aliases').Value
    if ($aliases -isnot [System.Array]) { Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'aliases must be an array' }

    $catalog = [System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)
    $seenNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $aliases) {
        Assert-DeliveryInputKeys -Object $entry -Required @('name', 'root', 'kind') -Code alias_catalog_invalid -Context 'alias entry'

        $name = (Get-DeliveryInputMember -Object $entry -Name 'name').Value
        if (($name -isnot [string]) -or ($name -cnotmatch '\A[a-z0-9][a-z0-9-]*\z')) {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'alias name must be a lowercase slug'
        }
        if (-not $seenNames.Add($name)) { Stop-DeliveryInput -Code alias_catalog_invalid -Detail 'alias names must be unique ignoring case' }

        $root = (Get-DeliveryInputMember -Object $entry -Name 'root').Value
        if (($root -isnot [string]) -or [string]::IsNullOrWhiteSpace($root) -or (-not [System.IO.Path]::IsPathFullyQualified($root))) {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail ('alias {0} root must be an absolute path' -f $name)
        }
        try {
            $rootFull = Get-DeliveryInputRootFull -Path $root
        }
        catch {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail ('alias {0} root is not a valid path' -f $name)
        }
        if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail ('alias {0} root must be an existing directory' -f $name)
        }
        if (Test-DeliveryInputReparse -Path $rootFull) {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail ('alias {0} root must not be a reparse point' -f $name)
        }

        $kind = (Get-DeliveryInputMember -Object $entry -Name 'kind').Value
        if (($kind -isnot [string]) -or (($kind -cne 'directory') -and ($kind -cne 'git'))) {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail ('alias {0} kind must be directory or git' -f $name)
        }
        if (($kind -ceq 'git') -and ($null -eq (Get-Item -LiteralPath ([System.IO.Path]::Combine($rootFull, '.git')) -Force -ErrorAction SilentlyContinue))) {
            Stop-DeliveryInput -Code alias_catalog_invalid -Detail ('git alias {0} has no .git entry in its root' -f $name)
        }

        $catalog[$name] = [pscustomobject]@{ Name = $name; Root = $rootFull; Kind = $kind }
    }

    return $catalog
}

function Resolve-DeliveryAliasPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][System.Collections.IDictionary] $Catalog,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string] $AliasPath
    )

    if ($null -eq $Catalog) { Stop-DeliveryInput -Code alias_catalog_missing -Detail 'no alias catalog is loaded' }
    if (($null -eq $AliasPath) -or (-not $AliasPath.StartsWith('alias:', [System.StringComparison]::Ordinal))) {
        Stop-DeliveryInput -Code source_path_invalid -Detail 'path is not an alias path'
    }

    $body = $AliasPath.Substring(6)
    $separatorIndex = $body.IndexOfAny([char[]]@('/', '\'))
    if (($separatorIndex -ge 0) -and ($body[$separatorIndex] -eq [char]'\')) {
        Stop-DeliveryInput -Code source_path_invalid -Detail 'backslash separators are not allowed; use forward slashes'
    }
    $name = $body
    $relative = ''
    if ($separatorIndex -ge 0) {
        $name = $body.Substring(0, $separatorIndex)
        $relative = $body.Substring($separatorIndex + 1)
        if ($relative.Length -eq 0) { Stop-DeliveryInput -Code source_path_invalid -Detail 'path must not end with a slash' }
    }
    if ($name.Length -eq 0) { Stop-DeliveryInput -Code source_path_invalid -Detail 'alias name is empty' }
    if (-not $Catalog.Contains($name)) { Stop-DeliveryInput -Code alias_unknown -Detail ('alias {0} is not defined in the catalog' -f $name) }

    $alias = $Catalog[$name]
    $resolved = Resolve-DeliveryContainedPath -Root $alias.Root -Relative $relative
    return [pscustomobject]@{
        Alias    = $name
        Root     = $alias.Root
        Relative = $relative
        Full     = $resolved.Full
        Kind     = $alias.Kind
    }
}

function Read-DeliveryInputFileHash {
    param(
        [Parameter(Mandatory = $true)][string] $FullPath,
        [Parameter(Mandatory = $true)][string] $Display
    )

    try {
        $bytes = [System.IO.File]::ReadAllBytes($FullPath)
    }
    catch {
        Stop-DeliveryInput -Code source_unreadable -Detail ('file cannot be read: {0}' -f $Display)
    }
    return Get-DeliveryInputSha256Hex -Bytes $bytes
}

function Get-DeliveryInputFileSha256 {
    param(
        [Parameter(Mandatory = $true)][string] $FullPath,
        [Parameter(Mandatory = $true)][string] $Display,
        [AllowNull()][scriptblock] $AfterFirstRead
    )

    $item = Get-Item -LiteralPath $FullPath -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { Stop-DeliveryInput -Code source_missing -Detail ('file not found: {0}' -f $Display) }
    if ($item.PSIsContainer) { Stop-DeliveryInput -Code source_unreadable -Detail ('path is a directory, not a file: {0}' -f $Display) }
    if ($item.Length -gt (Get-DeliveryInputMaxFileBytes)) { Stop-DeliveryInput -Code source_too_large -Detail ('file exceeds the size limit: {0}' -f $Display) }

    $first = Read-DeliveryInputFileHash -FullPath $FullPath -Display $Display
    if ($null -ne $AfterFirstRead) { & $AfterFirstRead $FullPath }
    $second = Read-DeliveryInputFileHash -FullPath $FullPath -Display $Display
    if ($first -cne $second) { Stop-DeliveryInput -Code source_changed_during_read -Detail ('file changed while it was read: {0}' -f $Display) }
    return $first
}

function Get-DeliveryInputFilesetIdentity {
    param(
        [Parameter(Mandatory = $true)][string] $DirectoryFull,
        [Parameter(Mandatory = $true)][string] $DisplayPath,
        [AllowNull()][object] $Members,
        [AllowNull()][scriptblock] $AfterFirstRead
    )

    if (($Members -isnot [System.Array]) -or ($Members.Count -lt 1) -or ($Members.Count -gt 2000)) {
        Stop-DeliveryInput -Code fileset_invalid -Detail 'files must be a non-empty array of at most 2000 relative paths'
    }

    $fullByRelative = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($member in $Members) {
        if (($member -isnot [string]) -or [string]::IsNullOrWhiteSpace($member)) { Stop-DeliveryInput -Code fileset_invalid -Detail 'each file must be a non-blank string' }
        $resolved = Resolve-DeliveryContainedPath -Root $DirectoryFull -Relative $member
        if (-not $seen.Add($member)) { Stop-DeliveryInput -Code fileset_collision -Detail ('duplicate or case-colliding file: {0}' -f $member) }
        $fullByRelative[$member] = $resolved.Full
    }

    $relatives = [string[]]@($fullByRelative.Keys)
    [System.Array]::Sort($relatives, [System.StringComparer]::Ordinal)

    $items = [System.Collections.Generic.List[string]]::new()
    foreach ($relative in $relatives) {
        $hash = Get-DeliveryInputFileSha256 -FullPath $fullByRelative[$relative] -Display ('{0}/{1}' -f $DisplayPath, $relative) -AfterFirstRead $AfterFirstRead
        $items.Add(('{{"path":{0},"sha256":"{1}"}}' -f (ConvertTo-Json -InputObject $relative -Compress), $hash))
    }

    $payload = '[' + ($items -join ',') + ']'
    return Get-DeliveryInputSha256Hex -Bytes ([System.Text.UTF8Encoding]::new($false).GetBytes($payload))
}

function Invoke-DeliveryInputGit {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string[]] $Arguments
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.ArgumentList.Add('-C')
    $startInfo.ArgumentList.Add($Root)
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.Environment['GIT_OPTIONAL_LOCKS'] = '0'

    try {
        $process = [System.Diagnostics.Process]::Start($startInfo)
    }
    catch {
        Stop-DeliveryInput -Code git_unavailable -Detail 'git executable is not available'
    }
    try {
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        [void]$process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            try { $process.Kill($true) } catch { }
            Stop-DeliveryInput -Code revision_unavailable -Detail 'git did not finish within 30 seconds'
        }
        $process.WaitForExit()
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdoutTask.Result }
    }
    finally {
        $process.Dispose()
    }
}

function Get-DeliveryInputRevisionIdentity {
    param(
        [Parameter(Mandatory = $true)][string] $AliasName,
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][string] $Revision
    )

    $commit = $Revision.ToLowerInvariant()
    $verify = Invoke-DeliveryInputGit -Root $Root -Arguments @('cat-file', '-e', ($commit + '^{commit}'))
    if ($verify.ExitCode -ne 0) { Stop-DeliveryInput -Code revision_unavailable -Detail 'commit is not present in the alias repository' }

    $tree = Invoke-DeliveryInputGit -Root $Root -Arguments @('rev-parse', ($commit + '^{tree}'))
    if ($tree.ExitCode -ne 0) { Stop-DeliveryInput -Code revision_unavailable -Detail 'tree of the commit cannot be resolved' }
    $treeId = $tree.Stdout.Trim()
    if ($treeId -cnotmatch '\A[0-9a-f]{40}\z') { Stop-DeliveryInput -Code revision_unavailable -Detail 'tree id is not recognized' }

    $payload = [ordered]@{ kind = 'revision'; alias = $AliasName; commit = $commit; tree = $treeId } | ConvertTo-Json -Compress
    return Get-DeliveryInputSha256Hex -Bytes ([System.Text.UTF8Encoding]::new($false).GetBytes($payload))
}

function Get-DeliveryInputSourceIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $RepoRoot,
        [Parameter(Mandatory = $true)][Alias('Input')][object] $InputSource,
        [string] $AliasCatalogPath,
        [scriptblock] $AfterFirstRead
    )

    if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) { Stop-DeliveryInput -Code source_path_invalid -Detail 'repository root is not a directory' }
    $repoFull = Get-DeliveryInputRootFull -Path $RepoRoot

    $pathMember = Get-DeliveryInputMember -Object $InputSource -Name 'path'
    if (($null -eq $pathMember) -or ($pathMember.Value -isnot [string]) -or [string]::IsNullOrWhiteSpace($pathMember.Value)) {
        Stop-DeliveryInput -Code source_path_invalid -Detail 'input path must be a non-blank string'
    }
    $path = [string]$pathMember.Value
    $isAlias = $path.StartsWith('alias:', [System.StringComparison]::Ordinal)

    $catalog = $null
    if ($isAlias) {
        if ([string]::IsNullOrWhiteSpace($AliasCatalogPath)) { Stop-DeliveryInput -Code alias_catalog_missing -Detail 'an alias path requires an alias catalog' }
        $catalog = Read-DeliveryAliasCatalog -Path $AliasCatalogPath
    }

    $kind = 'file'
    $source = $null
    $sourceMember = Get-DeliveryInputMember -Object $InputSource -Name 'source'
    if ($null -ne $sourceMember) {
        $source = $sourceMember.Value
        if (-not (Test-DeliveryInputObject -Value $source)) { Stop-DeliveryInput -Code source_kind_invalid -Detail 'source must be an object' }
        $kindMember = Get-DeliveryInputMember -Object $source -Name 'kind'
        if (($null -eq $kindMember) -or ($kindMember.Value -isnot [string])) { Stop-DeliveryInput -Code source_kind_invalid -Detail 'source kind must be a string' }
        $kind = [string]$kindMember.Value
        if ($kind -ceq 'file') {
            Assert-DeliveryInputKeys -Object $source -Required @('kind') -Code source_kind_invalid -Context 'file source'
        }
        elseif ($kind -ceq 'fileset') {
            Assert-DeliveryInputKeys -Object $source -Required @('kind', 'files') -Code source_kind_invalid -Context 'fileset source'
        }
        elseif ($kind -ceq 'revision') {
            Assert-DeliveryInputKeys -Object $source -Required @('kind', 'revision') -Code source_kind_invalid -Context 'revision source'
        }
        else {
            Stop-DeliveryInput -Code source_kind_invalid -Detail 'source kind must be file, fileset or revision'
        }
    }

    if ($kind -ceq 'file') {
        if (-not $isAlias) { Stop-DeliveryInput -Code source_kind_invalid -Detail 'a repository-relative path requires a fileset or revision source' }
        $resolved = Resolve-DeliveryAliasPath -Catalog $catalog -AliasPath $path
        return Get-DeliveryInputFileSha256 -FullPath $resolved.Full -Display $path -AfterFirstRead $AfterFirstRead
    }

    if ($kind -ceq 'fileset') {
        if ($isAlias) {
            $resolved = Resolve-DeliveryAliasPath -Catalog $catalog -AliasPath $path
        }
        else {
            $resolved = Resolve-DeliveryContainedPath -Root $repoFull -Relative $path
        }
        $directoryItem = Get-Item -LiteralPath $resolved.Full -Force -ErrorAction SilentlyContinue
        if ($null -eq $directoryItem) { Stop-DeliveryInput -Code source_missing -Detail ('fileset directory not found: {0}' -f $path) }
        if (-not $directoryItem.PSIsContainer) { Stop-DeliveryInput -Code fileset_invalid -Detail ('fileset path is not a directory: {0}' -f $path) }
        $filesMember = Get-DeliveryInputMember -Object $source -Name 'files'
        return Get-DeliveryInputFilesetIdentity -DirectoryFull $resolved.Full -DisplayPath $path -Members $filesMember.Value -AfterFirstRead $AfterFirstRead
    }

    if (-not $isAlias) { Stop-DeliveryInput -Code source_kind_invalid -Detail 'a revision source requires an alias:<name> path of a git alias' }
    if ($path -cnotmatch '\Aalias:([a-z0-9][a-z0-9-]*)\z') { Stop-DeliveryInput -Code source_kind_invalid -Detail 'revision path must be alias:<name>' }
    $aliasName = $Matches[1]
    if (-not $catalog.Contains($aliasName)) { Stop-DeliveryInput -Code alias_unknown -Detail ('alias {0} is not defined in the catalog' -f $aliasName) }
    $alias = $catalog[$aliasName]
    if ($alias.Kind -cne 'git') { Stop-DeliveryInput -Code source_kind_invalid -Detail ('alias {0} is not a git alias' -f $aliasName) }
    $revisionMember = Get-DeliveryInputMember -Object $source -Name 'revision'
    if (($revisionMember.Value -isnot [string]) -or ($revisionMember.Value -cnotmatch '\A[0-9a-fA-F]{40}\z')) {
        Stop-DeliveryInput -Code revision_invalid -Detail 'revision must be a full 40-character commit id'
    }
    return Get-DeliveryInputRevisionIdentity -AliasName $aliasName -Root $alias.Root -Revision ([string]$revisionMember.Value)
}
