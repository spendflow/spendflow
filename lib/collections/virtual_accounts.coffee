###
  VirtualAccounts
  - type: (bank|payFrom|payTo)
  - name (e.g. Tax, R&D)
  - balance (only used on payFrom)
###

@VirtualAccounts = new Meteor.Collection 'accounts'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowAccounts', getCurrentProfile()

@VirtualAccounts.before.insert ensureCommonMetadata
