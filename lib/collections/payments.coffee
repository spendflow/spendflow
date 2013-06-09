"""
Payments
  $ - type: (manual|system) — system ones are, for example, when part of income is automatically used to pay Envelope-based expenses
  $ - systemMeta — an object with case-specific keys. initially probably just { from: 'envelope', recordId: envelopeId }
  - expenseId
  - incomeId
  - amount
  - paid
  - notes
"""

@Payments = new Meteor.Collection 'payments'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowPayments'

# Hooks
@Payments.before "insert", (userId, doc) ->
  userId = getCurrentUserId(this) if not userId

  doc.owner = userId if doc.owner isnt userId
