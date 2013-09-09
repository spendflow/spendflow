###
  FinanceSessions
  - date
  - notes
###

@FinanceSessions = new Meteor.Collection 'sessions'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowSessions', getCurrentProfile(), ->
      Session.set("financeSessionsReady", true)

@FinanceSessions.before.insert ensureCommonMetadata
