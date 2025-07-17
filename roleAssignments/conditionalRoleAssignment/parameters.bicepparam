using 'main.bicep'

param ownerPrincipals = [
  {
    id: 'ab1dad1e-b56b-4d00-b03e-779cbbfd8a05'
    subscriptionId: '516961df-801f-4559-a0ea-de8d83641571'
    condition: '''
            ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR
            (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168})) AND
            ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR
            (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}))
        '''
  }
]
