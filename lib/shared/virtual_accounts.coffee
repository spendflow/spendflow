"""
parentContext is basically the server publish function context (this).
"""
@getVirtualAccounts = (userId, parentContext, extraCriteria = {}) ->
  if not userId then userId = getCurrentUserId(parentContext)

  criteria = _.extend { owner: userId }, extraCriteria

  data = VirtualAccounts.find(criteria).fetch()

  data

@getVirtualAccountName = (virtualAccountId) ->
  virtualAccount = VirtualAccounts.findOne(virtualAccountId)
  if virtualAccount
    return virtualAccount.name
  undefined
