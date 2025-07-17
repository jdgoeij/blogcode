<#
.SYNOPSIS
    Retrieves the authentication header for making API requests.

.DESCRIPTION
    The Get-Header function is used to retrieve the authentication header required for making API requests. It acquires an access token using the provided context and constructs the authorization header with the token.

.PARAMETER Context
    Specifies the context for acquiring the access token.
    This parameter is mandatory.

.EXAMPLE
    $context = @{
        Subscription = @{
            TenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        }
    }
    $header = Get-Header -Context $context
    Invoke-RestMethod -Uri 'https://api.example.com' -Headers $header

.INPUTS
    None

.OUTPUTS
    System.Collections.Hashtable

#>
Function Get-Header {
    Param (
        [Parameter(Mandatory)]
        [Array]$Context
    )
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($Context.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.AccessToken
    }
    return $authHeader
}
