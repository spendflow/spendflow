###
  VirtualAccounts
  - type: (bank|payFrom|payTo)
  - name (e.g. Tax, R&D)
  - balance (only used on payFrom)
###
@VirtualAccounts = new Meteor.Collection 'accounts'

@VirtualAccounts.before.insert ensureCommonMetadata
