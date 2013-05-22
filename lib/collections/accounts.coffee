"""
  Accounts
  - type: (bank|payFrom|payTo)
  - name (e.g. Tax, R&D)
  - initialBalance (only used on payFrom)
"""

# TODO: Subscribe to user's account data

Accounts = new Meteor.Collection 'accounts'