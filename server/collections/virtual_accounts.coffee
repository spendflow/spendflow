VirtualAccounts.allow allowViewOwn
VirtualAccounts.deny denyIfInvalidProfile

Meteor.publish 'spendflowAccounts', (profileId = -1) ->
  virtualAccounts = VirtualAccounts.find {
    owner: @userId
    profileId: profileId
  }
  virtualAccounts
