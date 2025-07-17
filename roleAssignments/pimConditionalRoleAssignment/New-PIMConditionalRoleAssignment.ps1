$subscription = Get-AzSubscription -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' # > replace this with your own subscription ID
# Switch to the target subscription
Set-AzContext -Subscription $subscription
$principalId = '00000000-0000-0000-0000-000000000002' ## your Entra group/user ID
$condition = @"
((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR 
(@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168})) AND 
((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR 
(@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}))
"@

$roleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' # Owner
$guid = [guid]::NewGuid()
$createEligibleRoleUri = "https://management.azure.com/providers/Microsoft.Subscription/subscriptions/{0}/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/{1}?api-version=2020-10-01" -f $subscription.Id, $guid

$body = @{
    Properties = @{
        RoleDefinitionID = "/subscriptions/$Subscription.Id/providers/Microsoft.Authorization/roleDefinitions/$contributorRoleId"
        PrincipalId      = $pimRequestorGroup.Id
        RequestType      = 'AdminAssign'
        ScheduleInfo     = @{
            Expiration = @{
                Type = 'NoExpiration'
            }
        }
    }
}
$guid = [guid]::NewGuid()
# Construct Uri with subscription Id and new GUID
$createEligibleRoleUri = "https://management.azure.com/providers/Microsoft.Subscription/subscriptions/{0}/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/{1}?api-version=2020-10-01" -f $Subscription.Id, $guid

$body = @{
    properties = @{
        roleDefinitionId = "/subscriptions/$($subscription.Id)/providers/Microsoft.Authorization/roleDefinitions/$roleDefinitionId"
        principalId      = $principalId
        requestType      = 'AdminAssign'
        condition        = $condition
        conditionVersion = '2.0'
        scheduleInfo     = @{
            expiration= @{
                type = "AfterDuration"
                endDateTime = $null
                duration = "P365D"
            }
        }
    }
}

# Call the API with PUT to assign the role to the targeted principal with the condition
Invoke-RestMethod -Uri $createEligibleRoleUri -Method Put -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)