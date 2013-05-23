Envelopes.allow allowViewOwn

Meteor.publish 'spendflowEnvelopes', ->
  data = Envelopes.find { owner: @userId }
  data
