@getVirtualAccounts = (userId, parentContext) ->
  if not userId then userId = getCurrentUserId(parentContext)

  data = VirtualAccounts.find({
    owner: userId
  }).fetch()

  data
