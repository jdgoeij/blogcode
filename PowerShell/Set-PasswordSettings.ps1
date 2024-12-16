<#PSScriptInfo
        .GUID aa1abc44-c280-4408-87ab-862520fba42c

        .AUTHOR https://github.com/jdgoeij

        .COMPANYNAME Rubicon B.V.
#>

<#

        .SYNOPSIS
        Updates the banned Password List in Entra ID

        .DESCRIPTION
        Updates the banned Password List in Entra ID using the Microsoft Graph API. Function is scoped on Authentication Methods settings only.

        .PARAMETER ParameterFolderPath
        Specifies the path of the parameter folder of authentication methods setting..

        .PARAMETER TenantBannedPasswordsFilePath
        Specifies the file path of the banned password list.

        .EXAMPLE
        PS> Set-PasswordSettings.ps1 -ParameterFolderPath 'parameters' -TenantBannedPasswordsFilePath 'parameters\bannedPasswordList.json'
        File.txt

    #>

[CmdLetBinding()]
Param (
    [Parameter(Mandatory,
        HelpMessage = "Enter the path of the parameter folder of authentication methods setting.")]
    [String]$ParameterFolderPath,
    [Parameter(Mandatory,
        HelpMessage = "Enter the file path of the banned password list.")]
    [String]$TenantBannedPasswordsFilePath
)

function Set-EntraIdSetting {
    param (
        [Parameter(Mandatory,
            HelpMessage = "Provide the name of the settings to create/update.")]
        [Object]$TargetSettingName,
        [Parameter(Mandatory,
            HelpMessage = "Provide the file path of the settings to create/update.")]
        [Object]$SettingFilePath
    )
    # Get the access token for the Microsoft Graph API
    $settingsUri = "https://graph.microsoft.com/beta/settings"

    Write-Output "##[command]Get access token for the Microsoft Graph API"
    $accessToken = (Get-AzAccessToken -ResourceTypeName MSGraph -AsSecureString).Token

    $params = @{
        Method         = 'Get'
        Uri            = $settingsUri
        Authentication = 'Bearer'
        Token          = $accessToken
        ContentType    = 'application/json'
    }

    try {
        $request = (Invoke-RestMethod @params).value
    }
    catch {
        Throw $_
    }
    if ($request) {
        Write-Output "##[command]Found settings. Checking for setting '$TargetSettingName'"
        $targetSettingObject = $request | Where-Object { $_.displayName -eq $TargetSettingName }
    }
    if ($targetSettingObject) {
        Write-Output "##[command]Found existing $TargetSettingName. Updating setting according to provided config."
        $passwordSettingsUri = $settingsUri + '/' + $targetSettingObject.id
        $params.Uri = $passwordSettingsUri
        $params.Method = 'Patch'
        $body = Get-Content -Path $SettingFilePath | ConvertFrom-Json -Depth 10
        $body.PSObject.properties.remove('templateId')
        $jsonBody = $body | ConvertTo-Json -Depth 10
        try {
            $settingRequest = Invoke-RestMethod @params -Body $jsonBody
        }
        catch {
            throw $_
        }
    }
    elseif (!$targetSettingObject) {
        Write-Output "##[command]No existing '$TargetSettingName'. Creating new '$TargetSettingName' according to provided config."
        $jsonBody = Get-Content -Path $SettingFilePath
        $params.Method = 'Post'

        try {
            $settingRequest = Invoke-RestMethod @params -Body $jsonBody
        }
        catch {
            throw $_
        }
    }
    return $settingRequest
}

Write-Output "##[command]Updating banned password list"
$bannedPasswords = Get-Content -Path $TenantBannedPasswordsFilePath | ConvertFrom-Json
$bannedPasswordsList = $null
$tab = [char]9

Write-Output "##[command]Looping the banned password list and adding tabs needed for the REST API call."
foreach ($bannedPassword in $bannedPasswords) {
    $bannedPasswordsList += $bannedPassword + $tab
}

Write-Output "##[command]Trimming the banned password list to exclude the last tab."
$trimmedPasswordList = $bannedPasswordsList -replace ".{1}$"
$bannedPasswordsSetting = Get-Content -Path "$ParameterFolderPath\passwordSettings.json" | ConvertFrom-Json -Depth 5 -AsHashtable
    ($bannedPasswordsSetting.values | Where-Object { $_.name -eq 'BannedPasswordList' }).value = $trimmedPasswordList
$bannedPasswordsSetting | ConvertTo-Json -Depth 5 | Out-File "$ParameterFolderPath\updatedPasswordSettings.json"


try {
    Set-EntraIdSetting -TargetSettingName 'Password Rule Settings' -SettingFilePath "$ParameterFolderPath\updatedPasswordSettings.json"
    Write-Output "Settings updated successfully!"
}
catch {
    throw
}