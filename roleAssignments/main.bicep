targetScope = 'managementGroup'

param ownerPrincipals array = []

module OwnerRoleAssignments 'br/public:avm/ptn/authorization/role-assignment:0.2.2' = [
  for principal in ownerPrincipals: {
    name: guid(principal.id, 'owner-no-privesc')
    params: {
      principalId: principal.id
      roleDefinitionIdOrName: 'Owner'
      condition: principal.condition ?? ''
      conditionVersion: '2.0'
      subscriptionId: principal.subscriptionId
    }
  }
]
