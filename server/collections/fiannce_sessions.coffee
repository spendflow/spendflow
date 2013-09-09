FinanceSessions.allow allowViewOwn
FinanceSessions.deny denyIfInvalidProfile

Meteor.publish 'spendflowSessions', (profileId = -1) ->
  financeSessions = FinanceSessions.find {
    owner: @userId
    profileId: profileId
  }
  financeSessions
