###
Incomes
  - type: (manual|system) — system ones are created when allocating money directly from Accounts to Expenses. At Expense creation time I'd say.
  - receiptDate
  - description
  - amount
  - envelopes (array of objects based on Envelopes.enabledByDefault)
  - envelopeId
  - rateOverride
  - amount
  - paid
  - transferred: (true|false) — it's almost never not the same amount, and I can use notes and such to document deviations, or split the income into 2. in the end everything is transferred.
  - business: (true|false)
  - depositAccountId
  - notes
  - tags
  - amountRemaining
  - pendingPaymentTotal
  - nonBusinessTotal
###

@Incomes = new Meteor.Collection 'incomes'

# Hooks
@Incomes.before.insert ensureCommonMetadata
