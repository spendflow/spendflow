###
Envelopes
- virtualAccount
- description
- rate
- active
- enabledByDefault
###

@Envelopes = new Meteor.Collection 'envelopes'

@Envelopes.before.insert ensureCommonMetadata
