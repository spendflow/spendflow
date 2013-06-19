Envelopes.allow allowViewOwn
Envelopes.deny denyIfInvalidProfile

Meteor.publish 'spendflowEnvelopes', (profileId = -1) ->
  data = Envelopes.find {
    owner: @userId
    profileId: profileId
  }
  data
