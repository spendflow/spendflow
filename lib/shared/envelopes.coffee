# TODO: Implement envelopeIdsInUse
@getActiveEnvelopes = (userId, parentContext, envelopeIdsInUse) ->
  if not userId then userId = getCurrentUserId(parentContext)

  data = Envelopes.find({
    owner: userId
    $or: [
      { active: true }
      _id: { $in: envelopeIdsInUse }
    ]
  }).fetch()

  # TODO: Make envelopeIdsInUse work

  data

@calculateEnvelopeAmount = (rate, amount, amountOverride) ->
  if not amountOverride then SpendflowMath.roundUpCents((+rate/100) * +amount) else amountOverride
