###
  FinanceSessions
  - date
  - notes
###

@FinanceSessions = new Meteor.Collection 'sessions'

@_sessionsSub = null

@FinanceSessions.before.insert ensureCommonMetadata
