function New-OperatorConfirmationEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $ActionId,
        [Parameter(Mandatory = $true)][string] $Effect,
        [Parameter(Mandatory = $true)][string] $Scope
    )

    if ([string]::IsNullOrWhiteSpace($ActionId) -or
        [string]::IsNullOrWhiteSpace($Effect) -or
        [string]::IsNullOrWhiteSpace($Scope)) {
        throw 'Operator confirmation evidence requires action id, effect, and scope.'
    }

    return [PSCustomObject]@{
        Boundary = 'operator_action_boundary'
        Decision = 'confirm'
        Confirmed = $true
        ActionId = $ActionId
        Effect = $Effect
        Scope = $Scope
    }
}

function Test-AuthorizedActionExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object] $TechnicalAuthorization,
        [Parameter(Mandatory = $true)][object] $OperatorConfirmation,
        [Parameter(Mandatory = $true)][object] $ContinuousAuthorization,
        [Parameter(Mandatory = $true)][string] $ExpectedActionId
    )

    if ([string]::IsNullOrWhiteSpace($ExpectedActionId)) {
        return [PSCustomObject]@{
            Allowed = $false
            Reason = 'action_identity_required'
        }
    }

    if ($null -eq $TechnicalAuthorization -or
        $null -eq $TechnicalAuthorization.PSObject.Properties['Allowed'] -or
        -not [bool]$TechnicalAuthorization.Allowed) {
        return [PSCustomObject]@{
            Allowed = $false
            Reason = 'technical_authorization_denied'
        }
    }

    foreach ($field in @('ActionId', 'Effect', 'Scope')) {
        if ($null -eq $TechnicalAuthorization.PSObject.Properties[$field] -or
            [string]::IsNullOrWhiteSpace([string]$TechnicalAuthorization.$field)) {
            return [PSCustomObject]@{
                Allowed = $false
                Reason = 'technical_authorization_missing_context'
            }
        }
    }

    $requiredConfirmationFields = @('Boundary', 'Decision', 'Confirmed', 'ActionId', 'Effect', 'Scope')
    foreach ($field in $requiredConfirmationFields) {
        if ($null -eq $OperatorConfirmation -or $null -eq $OperatorConfirmation.PSObject.Properties[$field]) {
            return [PSCustomObject]@{
                Allowed = $false
                Reason = 'operator_confirmation_required'
            }
        }
    }

    if ([string]$OperatorConfirmation.Boundary -ne 'operator_action_boundary' -or
        (([string]$OperatorConfirmation.Decision -cne 'confirm') -and ([string]$OperatorConfirmation.Decision -cne 'sim')) -or
        -not [bool]$OperatorConfirmation.Confirmed -or
        [string]::IsNullOrWhiteSpace([string]$OperatorConfirmation.ActionId) -or
        [string]::IsNullOrWhiteSpace([string]$OperatorConfirmation.Effect) -or
        [string]::IsNullOrWhiteSpace([string]$OperatorConfirmation.Scope)) {
        return [PSCustomObject]@{
            Allowed = $false
            Reason = 'operator_confirmation_invalid'
        }
    }

    if ($null -ne $TechnicalAuthorization.PSObject.Properties['Effect'] -and
        $null -ne $TechnicalAuthorization.PSObject.Properties['Scope'] -and
        ([string]$TechnicalAuthorization.Effect -cne [string]$OperatorConfirmation.Effect -or
         [string]$TechnicalAuthorization.Scope -cne [string]$OperatorConfirmation.Scope)) {
        return [PSCustomObject]@{
            Allowed = $false
            Reason = 'operator_confirmation_mismatch'
        }
    }

    if ([string]$TechnicalAuthorization.ActionId -cne $ExpectedActionId -or
        [string]$OperatorConfirmation.ActionId -cne $ExpectedActionId) {
        return [PSCustomObject]@{
            Allowed = $false
            Reason = 'action_identity_mismatch'
        }
    }

    if ($null -eq $ContinuousAuthorization -or
        $null -eq $ContinuousAuthorization.PSObject.Properties['Allowed'] -or
        -not [bool]$ContinuousAuthorization.Allowed) {
        return [PSCustomObject]@{
            Allowed = $false
            Reason = 'continuous_authorization_denied'
        }
    }

    return [PSCustomObject]@{
        Allowed = $true
        Reason = 'action_authorized'
        ConfirmationBoundary = [string]$OperatorConfirmation.Boundary
        ConfirmationActionId = [string]$OperatorConfirmation.ActionId
        ExpectedActionId = $ExpectedActionId
    }
}
