Profiles.allow allowViewOwn

Meteor.publish 'spendflowProfiles', ->
  data = Profiles.find { owner: @userId }
  data
