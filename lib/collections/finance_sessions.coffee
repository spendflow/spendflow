###
  FinanceSessions
  - date
  - notes
###

@FinanceSessions = new Meteor.Collection 'sessions'

@FinanceSessions.before.insert ensureCommonMetadata
