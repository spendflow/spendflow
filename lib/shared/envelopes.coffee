# TODO: Implement envelopeIdsInUse
@getActiveEnvelopes = (userId, parentContext, envelopeIdsInUse) ->
  if not userId then userId = getCurrentUserId(parentContext)

  data = Envelopes.find({
    owner: userId
  }).fetch()

  data
