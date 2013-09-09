###
Envelopes
- virtualAccount
- description
- rate
- active
- enabledByDefault
###

@Envelopes = new Meteor.Collection 'envelopes'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowEnvelopes', getCurrentProfile()

@Envelopes.before.insert ensureCommonMetadata
